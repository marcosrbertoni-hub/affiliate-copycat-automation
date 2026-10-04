#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
TOKEN="${SATELLITE_REPO_TOKEN:?SATELLITE_REPO_TOKEN não configurado}"
SOURCE_SITEMAP="${SOURCE_SITEMAP:-https://analisemelhor.com.br/sitemap.xml}"
INDEXNOW_KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
API="https://api.github.com"
BASE_DOMAIN="analisemelhor.com.br"
BATCH_SIZE="${BATCH_SIZE:-800}"
HUB_COUNT=10
TMP="$(mktemp -d)"
HUB_MANIFEST="${GITHUB_WORKSPACE:-.}/generated-hubs.tsv"
trap 'rm -rf "$TMP"' EXIT

api() {
  curl -fsS -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" "$@"
}
post_api() {
  curl -fsS -X POST -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" "$@"
}
resolve_sitemap() {
  local url="$1" depth="${2:-0}" file
  [ "$depth" -lt 10 ] || { echo "Sitemap profundo demais: $url" >&2; exit 1; }
  file="$TMP/sitemap-${RANDOM}-${RANDOM}.xml"
  curl -fsSL -A "analisemelhor-sitemap-automation/3.0" "$url" > "$file"
  if grep -qi '<sitemap>' "$file"; then
    grep -oE '<loc>[^<]+'</loc> "$file" | sed -E 's#</?loc>##g' |
      while IFS= read -r child; do resolve_sitemap "$child" "$((depth+1))"; done
  else
    grep -oE '<loc>[^<]+'</loc> "$file" | sed -E 's#</?loc>##g' >> "$TMP/urls.raw"
  fi
}

: > "$TMP/urls.raw"
resolve_sitemap "$SOURCE_SITEMAP"

# Exclusivamente URLs de conteúdo/produto/review. Nunca distribuir páginas institucionais.
sort -u "$TMP/urls.raw" |
  awk '$0 ~ /^https:\/\/(www\.)?analisemelhor\.com\.br\// {print}' |
  grep -Evi '/(contato|contact|sobre|about|politica|privacidade|privacy|termos|terms|cookies?|autor|authors?|login|entrar|buscar|search|categoria|categorias|category|tag|tags|pagina|page|sitemap|feed|rss|arquivo|archives)(/|$|[?])' |
  grep -Ei '/(review|reviews|analise|analises|melhor|melhores|produto|produtos|comparativo|comparativos|guia|guias|top-|ranking|oferta|ofertas|[0-9]{4})' > "$TMP/candidates.txt" || true

TOTAL="$(wc -l < "$TMP/candidates.txt" | tr -d ' ')"
[ "$TOTAL" -gt 0 ] || { echo "Nenhuma URL de produto/review encontrada no sitemap." >&2; exit 1; }
echo "URLs elegíveis: $TOTAL"

# A distribuição é POSICIONAL: URL 1-800 -> hub 01, 801-1600 -> hub 02 etc.
# Uma URL já usada jamais pode entrar em outro hub.
awk -v size="$BATCH_SIZE" -v hubs="$HUB_COUNT" '
  { n=NR; h=int((n-1)/size)+1; if (h<=hubs) print $0 > sprintf("%s/hub-%02d.txt", ENVIRON["TMP_DIR"], h) }
' TMP_DIR="$TMP" "$TMP/candidates.txt"

: > "$HUB_MANIFEST"
: > "$TMP/used.urls"
for i in $(seq 1 "$HUB_COUNT"); do
  file="$TMP/hub-$(printf '%02d' "$i").txt"
  : "${file:=}"
  [ -f "$file" ] || : > "$file"
done

# Nomes descritivos sem alterar a regra de lotes. O tema é definido pelo conteúdo do primeiro lote.
HUB_NAMES=(
  "casa"
  "cozinha"
  "eletronicos"
  "informatica"
  "celulares"
  "esportes"
  "ferramentas"
  "automotivo"
  "beleza"
  "moda"
)
HUB_TITLES=(
  "Casa e Produtos para o Lar"
  "Cozinha e Eletrodomésticos"
  "Eletrônicos"
  "Informática"
  "Celulares e Acessórios"
  "Esportes e Fitness"
  "Ferramentas"
  "Automotivo"
  "Beleza e Cuidados Pessoais"
  "Moda e Acessórios"
)

create_repo() {
  local repo="$1" title="$2"
  if api "$API/repos/$OWNER/$repo" >/dev/null 2>&1; then
    echo "Atualizando $repo"
    return
  fi
  post_api "$API/user/repos" --data "$(jq -n --arg name "$repo" --arg desc "AnaliseMelhor — hub editorial de $title"     '{name:$name,description:$desc,private:false,has_issues:false,has_projects:false,has_wiki:false,has_discussions:false,auto_init:true}')" >/dev/null
  sleep 2
}
commit_file() {
  local repo="$1" path="$2" file="$3" message="$4" encoded current_sha payload
  encoded="$(base64 -w 0 "$file")"
  current_sha="$(api "$API/repos/$OWNER/$repo/contents/$path?ref=main" 2>/dev/null | jq -r '.sha // empty')" || true
  if [ -n "$current_sha" ]; then
    payload="$(jq -n --arg msg "$message" --arg content "$encoded" --arg sha "$current_sha"       '{message:$msg,content:$content,sha:$sha,branch:"main"}')"
  else
    payload="$(jq -n --arg msg "$message" --arg content "$encoded"       '{message:$msg,content:$content,branch:"main"}')"
  fi
  curl -fsS -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $TOKEN"     -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json"     "$API/repos/$OWNER/$repo/contents/$path" --data "$payload" >/dev/null
}

escape_html() {
  sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

for i in $(seq 1 "$HUB_COUNT"); do
  n="$(printf '%02d' "$i")"
  repo="analisemelhor-${HUB_NAMES[$((i-1))]}"
  title="${HUB_TITLES[$((i-1))]}"
  lotfile="$TMP/hub-$n.txt"
  page="https://$OWNER.github.io/$repo/"
  count="$(wc -l < "$lotfile" | tr -d ' ')"

  # Não cria um hub vazio e não reutiliza URLs de outros lotes.
  [ "$count" -gt 0 ] || { echo "Hub $n vazio; encerrando a criação para preservar a sequência."; break; }

  while IFS= read -r url; do
    if grep -Fxq "$url" "$TMP/used.urls"; then
      echo "ERRO: URL duplicada detectada: $url" >&2
      exit 1
    fi
    printf '%s\n' "$url" >> "$TMP/used.urls"
  done < "$lotfile"

  create_repo "$repo" "$title"

  mkdir -p "$TMP/site-$n/articles"
  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>$title — Guias e Reviews | AnaliseMelhor</title>"
    echo "<meta name="description" content="Guias editoriais e referências de produtos do AnaliseMelhor em $title.">'
    echo "<link rel="canonical" href="$page">"
    echo '<style>body{font-family:system-ui;max-width:1000px;margin:auto;padding:32px;line-height:1.65}article{padding:18px 0;border-bottom:1px solid #ddd}a{color:#0b57d0}</style></head><body>'
    echo "<header><h1>$title</h1><p>Seleção editorial de produtos, análises e comparativos relacionados ao tema.</p><p>$count referências organizadas em páginas de leitura.</p></header><main>"
  } > "$TMP/site-$n/index.html"

  # 3–5 URLs por página interna, sequencialmente, sem repetição.
  page_no=0
  group_count=0
  group_file="$TMP/group-$n.txt"
  : > "$group_file"
  while IFS= read -r url; do
    printf '%s\n' "$url" >> "$group_file"
    group_count=$((group_count+1))
    if [ "$group_count" -eq 5 ]; then
      page_no=$((page_no+1))
      {
        echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
        echo "<title>Guias de $title — seleção $page_no</title></head><body><main><h1>Guias de $title</h1>"
        while IFS= read -r item; do
          item_title="$(printf '%s' "$item" | sed -E 's#/$##; s#.*/##; s/[-_]+/ /g' | escape_html)"
          echo "<article><h2>$item_title</h2><p>Confira a análise e os detalhes deste produto no AnaliseMelhor, referência utilizada para esta seleção editorial.</p><p><a href="$item" rel="nofollow">Ler análise completa no AnaliseMelhor</a></p></article>"
        done < "$group_file"
        echo '</main></body></html>'
      } > "$TMP/site-$n/articles/page-$page_no.html"
      printf '<li><a href="articles/page-%s.html">Seleção %s</a></li>\n' "$page_no" "$page_no" >> "$TMP/site-$n/index.html"
      : > "$group_file"
      group_count=0
    fi
  done < "$lotfile"

  if [ "$group_count" -gt 0 ]; then
    page_no=$((page_no+1))
    {
      echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      echo "<title>Guias de $title — seleção $page_no</title></head><body><main><h1>Guias de $title</h1>"
      while IFS= read -r item; do
        item_title="$(printf '%s' "$item" | sed -E 's#/$##; s#.*/##; s/[-_]+/ /g' | escape_html)"
        echo "<article><h2>$item_title</h2><p>Confira a análise e os detalhes deste produto no AnaliseMelhor, referência utilizada para esta seleção editorial.</p><p><a href="$item" rel="nofollow">Ler análise completa no AnaliseMelhor</a></p></article>"
      done < "$group_file"
      echo '</main></body></html>'
    } > "$TMP/site-$n/articles/page-$page_no.html"
    printf '<li><a href="articles/page-%s.html">Seleção %s</a></li>\n' "$page_no" "$page_no" >> "$TMP/site-$n/index.html"
  fi

  echo '</main><hr><p><a href="https://analisemelhor.com.br/" rel="nofollow">Visitar AnaliseMelhor</a></p></body></html>' >> "$TMP/site-$n/index.html"

  printf '%s' "$INDEXNOW_KEY" > "$TMP/site-$n/indexnow-key.txt"
  : > "$TMP/site-$n/.nojekyll"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: $page/sitemap.xml" > "$TMP/site-$n/robots.txt"

  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    echo "<url><loc>$page</loc><lastmod>$(date -u +%F)</lastmod></url>"
    find "$TMP/site-$n/articles" -type f -name '*.html' | sort | while read -r f; do
      rel="${f#"$TMP/site-$n/"}"
      echo "<url><loc>$page$rel</loc><lastmod>$(date -u +%F)</lastmod></url>"
    done
    echo '</urlset>'
  } > "$TMP/site-$n/sitemap.xml"

  cat > "$TMP/site-$n/pages.yml" <<'YAML'
name: Deploy editorial hub
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: true
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
    steps:
      - uses: actions/checkout@v6
      - uses: actions/configure-pages@v5
      - uses: actions/upload-pages-artifact@v4
        with:
          path: .
      - id: deployment
        uses: actions/deploy-pages@v4
YAML

  commit_file "$repo" "index.html" "$TMP/site-$n/index.html" "Cria hub editorial $title"
  # Copia todos os arquivos do site para commits individuais, mantendo a implementação simples.
  while IFS= read -r f; do
    rel="${f#"$TMP/site-$n/"}"
    commit_file "$repo" "$rel" "$f" "Publica página editorial $rel"
  done < <(find "$TMP/site-$n" -type f ! -name 'index.html' ! -name 'pages.yml' | sort)
  commit_file "$repo" ".github/workflows/pages.yml" "$TMP/site-$n/pages.yml" "Configura GitHub Pages"

  printf '%s\t%s\t%s\t%s\n' "$repo" "$title" "$count" "$page_no" >> "$HUB_MANIFEST"
  echo "$repo pronto: $count URLs, $page_no páginas internas."
done

echo "Concluído: lotes sequenciais de $BATCH_SIZE URLs, sem reutilização."

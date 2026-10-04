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
  n="$(printf '%02d' "$i")"
  lotfile="$TMP/hub-$n.txt"
  count="$(wc -l < "$lotfile" | tr -d ' ')"
  [ "$count" -gt 0 ] || { echo "Hub $n vazio; encerrando."; break; }

  while IFS= read -r url; do
    if grep -Fxq "$url" "$TMP/used.urls"; then
      echo "ERRO: URL duplicada detectada: $url" >&2
      exit 1
    fi
    printf '%s\n' "$url" >> "$TMP/used.urls"
  done < "$lotfile"

  # O tema serve apenas para dar nome coerente ao lote. As URLs permanecem na ordem original.
  best_slug="produtos"
  best_title="Produtos e Reviews"
  best_score=0
  for spec in "${THEMES[@]}"; do
    IFS='|' read -r slug title keywords <<< "$spec"
    score=0
    IFS=',' read -ra words <<< "$keywords"
    while IFS= read -r url; do
      normalized="$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]')"
      for word in "${words[@]}"; do
        [ -n "$word" ] || continue
        [[ "$normalized" == *"$word"* ]] && score=$((score+1))
      done
    done < "$lotfile"
    if [ "$score" -gt "$best_score" ]; then
      best_score="$score"; best_slug="$slug"; best_title="$title"
    fi
  done
  suffix="${THEME_SUFFIXES[$(( (i-1) % ${#THEME_SUFFIXES[@]} ))]}"
  repo="analisemelhor-${best_slug}-${suffix}"
  page="https://$OWNER.github.io/$repo/"

  create_repo "$repo" "$best_title"
  mkdir -p "$TMP/site-$n/pages"

  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>$best_title — AnaliseMelhor</title>"
    echo "<meta name="description" content="Índice editorial de $count análises e reviews relacionados a $best_title.">"
    echo "<link rel="canonical" href="$page">"
    echo '<style>body{font-family:system-ui;max-width:1000px;margin:auto;padding:32px;line-height:1.65}li{margin:.4rem 0}a{color:#0b57d0}</style></head><body>'
    echo "<h1>$best_title</h1><p>Índice editorial com $count referências de produtos e reviews.</p><ul>"
  } > "$TMP/site-$n/index.html"

  page_no=0
  while IFS= read -r url; do
    page_no=$((page_no+1))
    slug_text="$(printf '%s' "$url" | sed -E 's#/$##; s#.*/##; s/[-_]+/ /g')"
    safe_title="$(printf '%s' "$slug_text" | escape_html)"
    safe_url="$(printf '%s' "$url" | sed 's/&/\&amp;/g; s/"/\&quot;/g')"
    {
      echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      echo "<title>$safe_title — Análise e Review | AnaliseMelhor</title>"
      echo "<meta name="description" content="Referência editorial sobre $safe_title, com acesso à análise completa no AnaliseMelhor.">"
      echo '<style>body{font-family:system-ui;max-width:850px;margin:auto;padding:32px;line-height:1.7}a{color:#0b57d0}</style></head><body><main>'
      echo "<h1>$safe_title</h1>"
      echo "<p>Quem pesquisa <strong>$safe_title</strong> pode consultar nesta página uma referência editorial e seguir para a análise completa. O conteúdo detalhado, especificações e comparações permanecem no AnaliseMelhor, fonte original da referência.</p>"
      echo "<p><a href="$safe_url" rel="nofollow">Ler a análise completa no AnaliseMelhor</a></p>"
      echo '</main></body></html>'
    } > "$TMP/site-$n/pages/$page_no.html"
    printf '<li><a href="pages/%s.html">%s</a></li>\n' "$page_no" "$safe_title" >> "$TMP/site-$n/index.html"
  done < "$lotfile"

  echo '</ul></body></html>' >> "$TMP/site-$n/index.html"

  printf '%s' "$INDEXNOW_KEY" > "$TMP/site-$n/indexnow-key.txt"
  : > "$TMP/site-$n/.nojekyll"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: $page/sitemap.xml" > "$TMP/site-$n/robots.txt"

  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    echo "<url><loc>$page</loc><lastmod>$(date -u +%F)</lastmod></url>"
    find "$TMP/site-$n/pages" -type f -name '*.html' | sort -V | while read -r f; do
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

  commit_file "$repo" "index.html" "$TMP/site-$n/index.html" "Cria hub editorial $best_title"
  while IFS= read -r f; do
    rel="${f#"$TMP/site-$n/"}"
    commit_file "$repo" "$rel" "$f" "Publica página editorial $rel"
  done < <(find "$TMP/site-$n" -type f ! -name 'index.html' ! -name 'pages.yml' | sort -V)
  commit_file "$repo" ".github/workflows/pages.yml" "$TMP/site-$n/pages.yml" "Configura GitHub Pages"

  printf '%s\t%s\t%s\t%s\n' "$repo" "$best_title" "$count" "$page_no" >> "$HUB_MANIFEST"
  echo "$repo pronto: $count URLs, $page_no páginas internas."
done

echo "Concluído: lotes sequenciais de $BATCH_SIZE URLs, sem reutilização."

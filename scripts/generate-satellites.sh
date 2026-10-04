#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
TOKEN="${SATELLITE_REPO_TOKEN:?SATELLITE_REPO_TOKEN não configurado}"
SOURCE_SITEMAP="${SOURCE_SITEMAP:-https://analisemelhor.com.br/sitemap.xml}"
INDEXNOW_KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
API="https://api.github.com"
BASE_DOMAIN="analisemelhor.com.br"

# Hubs editoriais: o nome do repositório acompanha o assunto real das URLs.
# A URL é classificada pelo conjunto de termos do próprio slug.
CATEGORIES=(
  "casa|Casa|casa,moveis,móvel,móveis,decoracao,decoração,organizacao,organização,limpeza,quarto,sala,banheiro,jardim"
  "cozinha|Cozinha|cozinha,panela,panelas,fritadeira,air-fryer,airfryer,liquidificador,batedeira,mixer,forno,cafeteira,cafe,café"
  "eletronicos|Eletrônicos|eletronico,eletrônicos,eletronicos,tv,televisao,televisão,smart-tv,fones,fone,caixa-de-som,som,bluetooth"
  "informatica|Informática|informatica,informática,notebook,notebooks,computador,computadores,pc,monitor,teclado,mouse,impressora,roteador"
  "celulares|Celulares e Acessórios|celular,celulares,smartphone,smartphones,iphone,samsung,motorola,xiaomi,redmi,capinha,carregador"
  "esportes|Esportes|esporte,esportes,tenis-de-corrida,tênis-de-corrida,corrida,bicicleta,bicicletas,futebol,fitness,academia,treino"
  "ferramentas|Ferramentas|ferramenta,ferramentas,furadeira,parafusadeira,serra,martelete,oficina,construcao,construção"
  "automotivo|Automotivo|carro,carros,automotivo,automotivos,moto,motos,motocicleta,motocicletas,pneu,pneus,acessorios-para-carro,acessórios-para-carro"
  "beleza|Beleza e Cuidados Pessoais|beleza,cosmetico,cosmético,cosmeticos,cosméticos,maquiagem,cabelo,barba,perfume,skin-care,skincare"
  "moda|Moda|moda,roupa,roupas,calcado,calçado,calcados,calçados,tenis,tênis,sapato,sapatos,bolsa,bolsas,vestido"
  "saude|Saúde e Bem-estar|saude,saúde,bem-estar,bemestar,vitamina,vitaminas,suplemento,suplementos,estetica,estética"
)

TMP="$(mktemp -d)"
HUB_MANIFEST="${GITHUB_WORKSPACE:-.}/generated-hubs.tsv"
trap 'rm -rf "$TMP"' EXIT

api() {
  curl -fsS -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" "$@"
}

post_api() {
  curl -fsS -X POST -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" -H "X-GitHub-Api-Version: 2026-03-10" \
    -H "Content-Type: application/json" "$@"
}

resolve_sitemap() {
  local url="$1"
  local depth="${2:-0}"
  [ "$depth" -lt 10 ] || { echo "Sitemap profundo demais: $url" >&2; exit 1; }
  local file="$TMP/sitemap-${RANDOM}-${RANDOM}.xml"
  curl -fsSL -A "analisemelhor-sitemap-automation/2.0" "$url" > "$file"
  if grep -qi '<sitemap>' "$file"; then
    grep -oE '<loc>[^<]+'</loc> "$file" | sed -E 's#</?loc>##g' | while IFS= read -r child; do
      resolve_sitemap "$child" "$((depth+1))"
    done
  else
    grep -oE '<loc>[^<]+'</loc> "$file" | sed -E 's#</?loc>##g' >> "$TMP/urls.raw"
  fi
}

: > "$TMP/urls.raw"
resolve_sitemap "$SOURCE_SITEMAP"

sort -u "$TMP/urls.raw" | awk '$0 ~ /^https:\/\/(www\.)?analisemelhor\.com\.br\// {print}' > "$TMP/urls.txt"
TOTAL="$(wc -l < "$TMP/urls.txt" | tr -d ' ')"
[ "$TOTAL" -gt 0 ] || { echo "Nenhuma URL válida encontrada no sitemap." >&2; exit 1; }
echo "Sitemap resolvido: $TOTAL URLs"

# Cada categoria recebe somente URLs cujo próprio endereço contém sinais do tema.
# URLs sem correspondência vão para um hub editorial neutro, evitando forçar assuntos.
for spec in "${CATEGORIES[@]}"; do
  IFS='|' read -r slug title keywords <<< "$spec"
  : > "$TMP/$slug.txt"
done
: > "$TMP/guias.txt"

while IFS= read -r url; do
  normalized="$(printf '%s' "$url" | tr '[:upper:]' '[:lower:]' | sed 's/%20/-/g; s/[_ ]/-/g')"
  best_slug="guias"
  best_score=0
  for spec in "${CATEGORIES[@]}"; do
    IFS='|' read -r slug title keywords <<< "$spec"
    score=0
    IFS=',' read -ra words <<< "$keywords"
    for word in "${words[@]}"; do
      [ -n "$word" ] || continue
      if [[ "$normalized" == *"$word"* ]]; then score=$((score+1)); fi
    done
    if [ "$score" -gt "$best_score" ]; then
      best_score="$score"
      best_slug="$slug"
    fi
  done
  printf '%s\n' "$url" >> "$TMP/$best_slug.txt"
done < "$TMP/urls.txt"

# Só cria hubs que realmente tenham URLs. Não há obrigação artificial de criar 10.
: > "$TMP/hubs.tsv"
: > "$HUB_MANIFEST"
for spec in "${CATEGORIES[@]}"; do
  IFS='|' read -r slug title keywords <<< "$spec"
  count="$(wc -l < "$TMP/$slug.txt" | tr -d ' ')"
  if [ "$count" -gt 0 ]; then
    printf '%s\t%s\t%s\n' "$slug" "$title" "$count" >> "$TMP/hubs.tsv"
  fi
done
fallback_count="$(wc -l < "$TMP/guias.txt" | tr -d ' ')"
if [ "$fallback_count" -gt 0 ]; then
  printf '%s\t%s\t%s\n' "guias-e-comparativos" "Guias e Comparativos" "$fallback_count" >> "$TMP/hubs.tsv"
fi

HUB_COUNT="$(wc -l < "$TMP/hubs.tsv" | tr -d ' ')"
[ "$HUB_COUNT" -gt 0 ] || { echo "Nenhum hub temático pôde ser formado." >&2; exit 1; }
echo "Hubs temáticos identificados: $HUB_COUNT"

create_repo() {
  local repo="$1" title="$2"
  if api "$API/repos/$OWNER/$repo" >/dev/null 2>&1; then
    echo "Atualizando $repo"
    return
  fi
  echo "Criando $repo"
  post_api "$API/user/repos" --data "$(jq -n --arg name "$repo" --arg desc "AnaliseMelhor — hub editorial de $title" '{name:$name,description:$desc,private:false,has_issues:false,has_projects:false,has_wiki:false,has_discussions:false,auto_init:true}')" >/dev/null
  sleep 2
}

enable_pages() {
  local repo="$1"
  if api "$API/repos/$OWNER/$repo/pages" >/dev/null 2>&1; then return; fi
  post_api "$API/repos/$OWNER/$repo/pages" --data '{"build_type":"workflow","source":{"branch":"main","path":"/"}}' >/dev/null || true
}

commit_file() {
  local repo="$1" path="$2" content_file="$3" message="$4"
  local encoded current_sha payload
  encoded="$(base64 -w 0 "$content_file")"
  current_sha="$(api "$API/repos/$OWNER/$repo/contents/$path?ref=main" 2>/dev/null | jq -r '.sha // empty')" || true
  if [ -n "$current_sha" ]; then
    payload="$(jq -n --arg msg "$message" --arg content "$encoded" --arg sha "$current_sha" '{message:$msg,content:$content,sha:$sha,branch:"main"}')"
  else
    payload="$(jq -n --arg msg "$message" --arg content "$encoded" '{message:$msg,content:$content,branch:"main"}')"
  fi
  curl -fsS -X PUT -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" -H "Content-Type: application/json" \
    "$API/repos/$OWNER/$repo/contents/$path" --data "$payload" >/dev/null
}

while IFS=$'\t' read -r slug title count; do
  repo="analisemelhor-$slug"
  lotfile="$TMP/$slug.txt"
  page="https://$OWNER.github.io/$repo/"
  echo "$repo" >> "$TMP/hub-repos.txt"

  create_repo "$repo" "$title"
  enable_pages "$repo"

  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>$title — AnaliseMelhor</title>"
    echo "<meta name="description" content="Índice editorial de guias de $title publicados no AnaliseMelhor.">'
    echo '<link rel="canonical" href="'"$page"'">'
    echo '<style>body{font-family:system-ui;max-width:1100px;margin:auto;padding:30px;line-height:1.6}li{margin:.45rem 0}a{color:#0b57d0}header{margin-bottom:2rem}</style></head><body>"
    echo '<header><h1>'"$title"'</h1><p>Índice temático de conteúdos do <a href="https://analisemelhor.com.br/" rel="nofollow">AnaliseMelhor</a>. Os guias completos estão no site original.</p><p>'"$count"' guias relacionados.</p></header><main><ul>'
    while IFS= read -r url; do
      slug_text="$(printf '%s' "$url" | sed -E 's#/$##; s#.*/##; s/[-_]+/ /g')"
      safe_title="$(printf '%s' "$slug_text" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
      echo '<li><a href="'"$url"'" rel="nofollow">'"$safe_title"'</a></li>'
    done < "$lotfile"
    echo '</ul></main><hr><p><a href="https://analisemelhor.com.br/sitemap.xml" rel="nofollow">Sitemap do AnaliseMelhor</a></p></body></html>'
  } > "$TMP/index.html"

  cat > "$TMP/pages.yml" <<'YAML'
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

  printf '%s' "$INDEXNOW_KEY" > "$TMP/indexnow-key.txt"
  : > "$TMP/nojekyll"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: $page/sitemap.xml" > "$TMP/robots.txt"
  cat > "$TMP/sitemap.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>$page</loc><lastmod>$(date -u +%F)</lastmod></url></urlset>
XML

  commit_file "$repo" "index.html" "$TMP/index.html" "Atualiza hub temático $title"
  commit_file "$repo" "sitemap.xml" "$TMP/sitemap.xml" "Atualiza sitemap do hub"
  commit_file "$repo" "robots.txt" "$TMP/robots.txt" "Atualiza robots do hub"
  commit_file "$repo" "indexnow-key.txt" "$TMP/indexnow-key.txt" "Atualiza chave IndexNow"
  commit_file "$repo" ".nojekyll" "$TMP/nojekyll" "Atualiza configuração Pages"
  commit_file "$repo" ".github/workflows/pages.yml" "$TMP/pages.yml" "Configura GitHub Pages"

  echo "$repo pronto: $count URLs"
done < "$TMP/hubs.tsv"

cp "$TMP/hubs.tsv" "$TMP/../hubs.tsv" 2>/dev/null || true
cp "$TMP/hub-repos.txt" "$TMP/../hub-repos.txt" 2>/dev/null || true
cp "$TMP/hubs.tsv" "$HUB_MANIFEST"
echo "Concluído: $HUB_COUNT hubs editoriais temáticos. Nenhum nome numérico foi usado."

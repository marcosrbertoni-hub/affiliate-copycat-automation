#!/usr/bin/env bash
set -euo pipefail

OWNER="$GITHUB_OWNER"; [ -n "$OWNER" ] || OWNER=marcosrbertoni-hub
TOKEN="$SATELLITE_REPO_TOKEN"; test -n "$TOKEN" || { echo "SATELLITE_REPO_TOKEN não configurado" >&2; exit 1; }
SOURCE_SITEMAP="$SOURCE_SITEMAP"; [ -n "$SOURCE_SITEMAP" ] || SOURCE_SITEMAP=https://analisemelhor.com.br/sitemap.xml
PREFIX="$REPO_PREFIX"; [ -n "$PREFIX" ] || PREFIX=analisemelhor-satellite
COUNT="$SATELLITE_COUNT"; [ -n "$COUNT" ] || COUNT=10
INDEXNOW_KEY="$INDEXNOW_KEY"; test -n "$INDEXNOW_KEY" || { echo "INDEXNOW_KEY não configurado" >&2; exit 1; }
API="https://api.github.com"

if [ "$COUNT" -ne 10 ]; then echo "SATELLITE_COUNT deve ser 10" >&2; exit 1; fi

api() {
  curl -fsS \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    "$@"
}

post_api() {
  curl -fsS -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    -H "Content-Type: application/json" \
    "$@"
}

put_api() {
  curl -fsS -X PUT \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2026-03-10" \
    -H "Content-Type: application/json" \
    "$@"
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

resolve_sitemap() {
  local url="$1"
  local out="$2"
  curl -fsSL -A "analisemelhor-sitemap-automation/1.0" "$url" > "$TMP/current.xml"
  if grep -qi '<sitemap>' "$TMP/current.xml"; then
    grep -oE '<loc>[^<]+'</loc> "$TMP/current.xml" 2>/dev/null | sed -E 's#</?loc>##g' | while IFS= read -r child; do
      resolve_sitemap "$child" "$out"
    done
  else
    grep -oE '<loc>[^<]+'</loc> "$TMP/current.xml" 2>/dev/null | sed -E 's#</?loc>##g' >> "$out"
  fi
}

URLS_RAW="$TMP/urls.raw"
: > "$URLS_RAW"
resolve_sitemap "$SOURCE_SITEMAP" "$URLS_RAW"

sort -u "$URLS_RAW" | awk '$0 ~ /^https:\/\/([A-Za-z0-9-]+\.)*analisemelhor\.com\.br\// {print}' > "$TMP/urls.txt"
TOTAL="$(wc -l < "$TMP/urls.txt" | tr -d ' ')"
if [ "$TOTAL" -eq 0 ]; then echo "Nenhuma URL válida encontrada no sitemap." >&2; exit 1; fi

echo "Sitemap resolvido: $TOTAL URLs"

for i in $(seq 1 10); do : > "$TMP/lot-$i.txt"; done
awk '{n=(NR-1)%10+1; print >> "'$TMP'/lot-" n ".txt"}' "$TMP/urls.txt"

create_repo() {
  local repo="$1"
  local lot="$2"
  if api "$API/repos/$OWNER/$repo" >/dev/null 2>&1; then
    echo "Atualizando $repo"
    return
  fi
  echo "Criando $repo"
  post_api "$API/user/repos" --data "{\"name\":\"$repo\",\"description\":\"AnaliseMelhor — índice temático automatizado, lote $lot\",\"private\":false,\"has_issues\":false,\"has_projects\":false,\"has_wiki\":false,\"has_discussions\":false,\"auto_init\":true}" >/dev/null
  sleep 2
}

enable_pages() {
  local repo="$1"
  if api "$API/repos/$OWNER/$repo/pages" >/dev/null 2>&1; then return; fi
  post_api "$API/repos/$OWNER/$repo/pages" --data '{"build_type":"workflow","source":{"branch":"main","path":"/"}}' >/dev/null || true
}

commit_file() {
  local repo="$1"
  local path="$2"
  local content_file="$3"
  local message="$4"
  local encoded
  encoded="$(base64 -w 0 "$content_file")"
  local current_sha=""
  current_sha="$(api "$API/repos/$OWNER/$repo/contents/$path?ref=main" 2>/dev/null | jq -r '.sha // empty')" || true
  local payload
  if [ -n "$current_sha" ]; then
    payload="$(jq -n --arg msg "$message" --arg content "$encoded" --arg sha "$current_sha" '{message:$msg,content:$content,sha:$sha,branch:"main"}')"
  else
    payload="$(jq -n --arg msg "$message" --arg content "$encoded" '{message:$msg,content:$content,branch:"main"}')"
  fi
  put_api "$API/repos/$OWNER/$repo/contents/$path" --data "$payload" >/dev/null
}

build_index() {
  local lot="$1"
  local lotfile="$TMP/lot-$lot.txt"
  local outfile="$TMP/index-$lot.html"
  local page="https://$OWNER.github.io/$PREFIX-$(printf '%02d' "$lot")/"
  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>Índice de guias — AnaliseMelhor — lote $(printf '%02d' "$lot")</title>"
    echo '<meta name="description" content="Índice temático de guias publicados no AnaliseMelhor. O conteúdo original permanece no domínio analisemelhor.com.br.">'
    echo "<link rel=\"canonical\" href=\"$page\"><style>body{font-family:system-ui;max-width:1100px;margin:auto;padding:30px;line-height:1.6}li{margin:.35rem 0}a{color:#0b57d0}section{margin:2rem 0}</style></head><body>"
    echo '<h1>Índice de guias do AnaliseMelhor</h1>'
    echo '<p>Índice de navegação sem cópia de conteúdo. Consulte o guia original no AnaliseMelhor.</p>'
    echo "<p>Lote $(printf '%02d' "$lot") · $(wc -l < "$lotfile" | tr -d ' ') URLs</p>"
    echo '<ul>'
    while IFS= read -r url; do
      slug="$(printf '%s' "$url" | sed -E 's#/$##; s#.*/##; s/[-_]+/ /g')"
      title="$(printf '%s' "$slug" | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1')"
      safe_title="$(printf '%s' "$title" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')"
      echo "<li><a href=\"$url\" rel=\"nofollow\">$safe_title</a> — guia original no AnaliseMelhor</li>"
    done < "$lotfile"
    echo '</ul>'
    echo '<hr><p>Outros índices: '
    for j in $(seq 1 10); do
      [ "$j" -eq "$lot" ] && continue
      printf '<a href="https://%s.github.io/%s-%02d/">Hub %02d</a> ' "$OWNER" "$PREFIX" "$j" "$j"
    done
    echo '</p><p><a href="https://analisemelhor.com.br/sitemap.xml">Sitemap do AnaliseMelhor</a></p></body></html>'
  } > "$outfile"
}

for lot in $(seq 1 10); do
  repo="$PREFIX-$(printf '%02d' "$lot")"
  create_repo "$repo" "$lot"
  enable_pages "$repo"
  build_index "$lot"

  cat > "$TMP/pages-$lot.yml" <<'YAML'
name: Deploy satellite hub
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

  printf '%s' "$INDEXNOW_KEY" > "$TMP/indexnow-$lot.txt"
  : > "$TMP/nojekyll-$lot"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: https://$OWNER.github.io/$repo/sitemap.xml" > "$TMP/robots-$lot.txt"
  cat > "$TMP/sitemap-$lot.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>https://$OWNER.github.io/$repo/</loc><lastmod>$(date -u +%F)</lastmod></url></urlset>
XML

  commit_file "$repo" "index.html" "$TMP/index-$lot.html" "Atualiza índice do lote $(printf '%02d' "$lot")"
  commit_file "$repo" "sitemap.xml" "$TMP/sitemap-$lot.xml" "Atualiza sitemap do hub"
  commit_file "$repo" "robots.txt" "$TMP/robots-$lot.txt" "Atualiza robots do hub"
  commit_file "$repo" "indexnow-key.txt" "$TMP/indexnow-$lot.txt" "Atualiza chave IndexNow"
  commit_file "$repo" ".nojekyll" "$TMP/nojekyll-$lot" "Atualiza configuração Pages"
  commit_file "$repo" ".github/workflows/pages.yml" "$TMP/pages-$lot.yml" "Configura GitHub Pages"
  echo "$repo pronto: $(wc -l < "$TMP/lot-$lot.txt" | tr -d ' ') URLs"
done

echo "Os 10 hubs foram criados/atualizados. O deploy do GitHub Pages é assíncrono."

#!/usr/bin/env bash
set -euo pipefail
OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
API="https://api.indexnow.org/indexnow"
REPOS=(
  analisemelhor-casa-guias
  analisemelhor-moda-comparativos
  analisemelhor-casa-selecoes
  analisemelhor-casa-recomendacoes
  analisemelhor-casa-reviews
  analisemelhor-casa-comparativos
  analisemelhor-informatica-selecoes
  analisemelhor-ferramentas-recomendacoes
  analisemelhor-celulares-reviews
  analisemelhor-celulares-reviews-lote-10
)
for repo in "${REPOS[@]}"; do
  base="https://${OWNER}.github.io/${repo}"
  key_location="${base}/indexnow-key.txt"
  echo "Preparando $repo"
  curl -fsS --max-time 20 "${base}/indexnow-key.txt" | grep -Fxq "$KEY" || {
    echo "::error::Chave IndexNow não confirmada em $repo"
    exit 1
  }
  urls=("${base}/")
  if curl -fsS --max-time 30 "${base}/artigos/index.html" >/dev/null 2>&1; then
    mapfile -t article_urls < <(curl -fsS --max-time 30 "${base}/artigos/index.html" | grep -oE 'href="[^"]+\.html"' | sed -E 's/^href="|"$//g' | grep -v '^index\.html$' | sed "s#^#${base}/artigos/#" | sort -u)
    urls+=("${article_urls[@]}")
  else
    for n in $(seq 1 800); do urls+=("${base}/pages/${n}.html"); done
  fi

  tmp_urls="$(mktemp)"
  tmp_array="$(mktemp)"
  tmp_payload="$(mktemp)"
  printf '%s\n' "${urls[@]}" > "$tmp_urls"
  split -l 100 "$tmp_urls" "$tmp_urls.part."
  for part in "$tmp_urls.part."*; do
    jq -R -s 'split("\n") | map(select(length > 0))' "$part" > "$tmp_array"
    jq -n \
      --arg host "${OWNER}.github.io" \
      --arg key "$KEY" \
      --arg keyLocation "$key_location" \
      --slurpfile urlList "$tmp_array" \
      '{host:$host,key:$key,keyLocation:$keyLocation,urlList:$urlList[0]}' > "$tmp_payload"
    code="$(curl -sS --max-time 90 -o /tmp/indexnow-response -w '%{http_code}' -X POST "$API" -H 'Content-Type: application/json; charset=utf-8' --data-binary "@$tmp_payload")"
    case "$code" in
      200|202) echo "OK: $repo — lote $(wc -l < "$part") URLs (HTTP $code)" ;;
      429) echo "::error::IndexNow limitou $repo (HTTP 429)"; cat /tmp/indexnow-response; exit 1 ;;
      *) echo "::error::IndexNow recusou $repo (HTTP $code)"; cat /tmp/indexnow-response; exit 1 ;;
    esac
  done
  rm -f "$tmp_urls" "$tmp_array" "$tmp_payload" "$tmp_urls.part."*
done
echo "IndexNow concluído para os 10 hubs existentes."

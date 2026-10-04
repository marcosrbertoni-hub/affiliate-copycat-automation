#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
MANIFEST="${HUB_MANIFEST:-${GITHUB_WORKSPACE:-.}/generated-hubs.tsv}"
API="https://api.indexnow.org/indexnow"
TMP_RESPONSE="$(mktemp)"
TMP_URLS="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE" "$TMP_URLS"' EXIT

[ -s "$MANIFEST" ] || { echo "::warning::Nenhum hub editorial foi gerado nesta execução."; exit 0; }

while IFS=$'\t' read -r repo title hub start end count; do
  [ -n "$repo" ] || continue

  url="https://$OWNER.github.io/$repo/"
  key_location="${url}indexnow-key.txt"
  : > "$TMP_URLS"
  printf '%s\n' "$url" >> "$TMP_URLS"
  for page_no in $(seq 1 "$count"); do
    printf '%s\n' "https://$OWNER.github.io/$repo/pages/$page_no.html" >> "$TMP_URLS"
  done

  ready=0
  for attempt in $(seq 1 20); do
    if curl -fsS --max-time 20 -A "analisemelhor-indexnow-automation/3.0" "${url}indexnow-key.txt" 2>/dev/null |
       grep -Fxq "$KEY"; then
      ready=1
      break
    fi
    echo "Pages/chave ainda não disponível: $repo (tentativa $attempt/20)"
    sleep 15
  done

  if [ "$ready" -ne 1 ]; then
    echo "::warning::Não foi possível confirmar Pages + chave IndexNow de $repo nesta execução."
    continue
  fi

  mapfile -t urls < "$TMP_URLS"
  payload="$(jq -n \
    --arg host "$OWNER.github.io" \
    --arg key "$KEY" \
    --arg keyLocation "$key_location" \
    --argjson urlList "$(printf '%s\n' "${urls[@]}" | jq -R . | jq -s .)" \
    '{host:$host,key:$key,keyLocation:$keyLocation,urlList:$urlList}')"

  response="$(curl -sS --max-time 60 -o "$TMP_RESPONSE" -w "%{http_code}" \
    -X POST "$API" \
    -H "Content-Type: application/json; charset=utf-8" \
    --data "$payload")"

  case "$response" in
    200|202) echo "IndexNow aceitou $repo: $((count + 1)) URLs — HTTP $response" ;;
    429) echo "::warning::IndexNow limitou $repo (HTTP 429)." ;;
    *) echo "::warning::IndexNow não aceitou $repo: HTTP $response"; cat "$TMP_RESPONSE" || true ;;
  esac
done < "$MANIFEST"

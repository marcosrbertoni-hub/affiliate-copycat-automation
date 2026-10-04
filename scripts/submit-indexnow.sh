#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
MANIFEST="${HUB_MANIFEST:-${GITHUB_WORKSPACE:-.}/generated-hubs.tsv}"
API="https://api.indexnow.org/indexnow"
TMP_RESPONSE="$(mktemp)"
trap 'rm -f "$TMP_RESPONSE"' EXIT

[ -s "$MANIFEST" ] || { echo "::warning::Nenhum hub editorial foi gerado nesta execução."; exit 0; }

while IFS=$'\t' read -r slug title count; do
  [ -n "$slug" ] || continue
  repo="analisemelhor-$slug"
  url="https://$OWNER.github.io/$repo/"
  key_location="$url/indexnow-key.txt"

  ready=0
  for attempt in $(seq 1 10); do
    if curl -fsS --max-time 20 -A "analisemelhor-indexnow-automation/2.0" "$url" >/dev/null 2>&1; then
      ready=1
      break
    fi
    echo "Pages ainda não disponível: $url (tentativa $attempt/10)"
    sleep 15
  done

  if [ "$ready" -ne 1 ]; then
    echo "::warning::Não foi possível confirmar o Pages de $repo nesta execução."
    continue
  fi

  payload="$(jq -n \
    --arg host "$(printf '%s' "$url" | sed -E 's#^https?://##; s#/$##')" \
    --arg key "$KEY" \
    --arg keyLocation "$key_location" \
    --arg page "$url" \
    '{host:$host,key:$key,keyLocation:$keyLocation,urlList:[$page]}')"

  response="$(curl -sS --max-time 30 -o "$TMP_RESPONSE" -w "%{http_code}" \
    -X POST "$API" -H "Content-Type: application/json; charset=utf-8" --data "$payload")"

  case "$response" in
    200|202) echo "IndexNow aceitou $url: HTTP $response" ;;
    429) echo "::warning::IndexNow limitou $url (HTTP 429)." ;;
    *) echo "::warning::IndexNow não aceitou $url: HTTP $response"; cat "$TMP_RESPONSE" || true ;;
  esac
done < "$MANIFEST"

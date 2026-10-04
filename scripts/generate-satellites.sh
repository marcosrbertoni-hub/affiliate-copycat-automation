#!/usr/bin/env bash
set -euo pipefail

OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
TOKEN="${SATELLITE_REPO_TOKEN:?SATELLITE_REPO_TOKEN não configurado}"
SOURCE_SITEMAP="${SOURCE_SITEMAP:-https://analisemelhor.com.br/sitemap.xml}"
INDEXNOW_KEY="${INDEXNOW_KEY:?INDEXNOW_KEY não configurado}"
API="https://api.github.com"
BASE_DOMAIN="analisemelhor.com.br"
BATCH_SIZE=800
HUB_COUNT=10
REQUIRED_URLS=$((BATCH_SIZE * HUB_COUNT))
TMP="$(mktemp -d)"
HUB_MANIFEST="${GITHUB_WORKSPACE:-.}/generated-hubs.tsv"
LOCK_FILE="${GITHUB_WORKSPACE:-.}/GENERATION_COMPLETE"
trap 'rm -rf "$TMP"' EXIT

# Temas servem somente para nomear o hub. A distribuição continua 100% posicional.
THEMES=(
  "casa|Casa e Lar|casa,lar,móveis,moveis,limpeza"
  "cozinha|Cozinha|cozinha,eletrodomésticos,eletrodomesticos,airfryer,cafeteira"
  "eletronicos|Eletrônicos|eletronico,eletronicos,tv,televisão,televisao,audio"
  "informatica|Informática|informatica,notebook,monitor,impressora,computador"
  "celulares|Celulares e Acessórios|celular,smartphone,iphone,samsung,xiaomi"
  "esportes|Esportes e Fitness|esporte,fitness,academia,corrida,bicicleta"
  "ferramentas|Ferramentas|ferramenta,ferramentas,furadeira,parafusadeira"
  "automotivo|Automotivo|carro,automotivo,pneu,óleo,oleo"
  "beleza|Beleza e Cuidados|beleza,skincare,cabelo,barba"
  "moda|Moda e Acessórios|moda,roupa,calçado,calcado,tênis,tenis"
)
THEME_SUFFIXES=(guias comparativos selecoes recomendacoes reviews)

api() {
  curl -fsS --retry 3 --retry-delay 2 \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

post_api() {
  curl -fsS --retry 3 --retry-delay 2 -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -H "Content-Type: application/json" "$@"
}

escape_html() {
  sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' -e "s/'/\&#39;/g"
}

url_slug() {
  printf '%s' "$1" | sed -E 's#/$##; s#^https?://[^/]+/##; s#[/?&=]+# #g; s/[-_]+/ /g' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' | cut -c1-120
}

resolve_sitemap() {
  local url="$1" depth="${2:-0}" file child
  [ "$depth" -lt 10 ] || { echo "Sitemap profundo demais: $url" >&2; exit 1; }
  file="$TMP/sitemap-$(date +%s%N)-${depth}.xml"
  curl -fsSL --retry 3 --retry-delay 2 -A "analisemelhor-sitemap-automation/4.0" "$url" > "$file"
  if grep -qi '<sitemap>' "$file"; then
    grep -oE '<loc>[^<]+</loc>' "$file" | sed -E 's#</?loc>##g' |
      while IFS= read -r child; do
        [ -n "$child" ] && resolve_sitemap "$child" "$((depth+1))"
      done
  else
    grep -oE '<loc>[^<]+</loc>' "$file" | sed -E 's#</?loc>##g' >> "$TMP/urls.raw"
  fi
}

repo_exists() {
  local status
  status="$(curl -sS --retry 3 --retry-delay 2 \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -o /dev/null -w '%{http_code}' "$API/repos/$OWNER/$1")"
  [ "$status" = "200" ]
}

repo_is_empty() {
  local repo="$1" body size
  body="$(api "$API/repos/$OWNER/$repo")" || return 1
  size="$(printf '%s' "$body" | jq -r '.size // -1')"
  [ "$size" = "0" ]
}

repo_has_800_pages() {
  local repo="$1" body count
  body="$(api "$API/repos/$OWNER/$repo/git/trees/main?recursive=1")" || return 1
  count="$(printf '%s' "$body" | jq '[.tree[]? | select(.type == "blob" and (.path | startswith("pages/")) and (.path | endswith(".html")))] | length')"
  [ "$count" = "$BATCH_SIZE" ]
}

create_repo() {
  local repo="$1" title="$2"
  local payload
  payload="$(jq -n --arg name "$repo" --arg description "Hub editorial temático do AnaliseMelhor — $title" '{name:$name,description:$description,private:false,auto_init:false,has_issues:false,has_projects:false,has_wiki:false,has_discussions:false}')"
  post_api "$API/user/repos" --data "$payload" >/dev/null
}

enable_pages() {
  local repo="$1" payload
  payload='{"build_type":"workflow"}'
  post_api "$API/repos/$OWNER/$repo/pages" --data "$payload" >/dev/null 2>&1 || {
    # Se Pages já estiver habilitado, não interromper.
    api "$API/repos/$OWNER/$repo/pages" >/dev/null
  }
}

publish_repo() {
  local repo="$1" dir="$2"
  local remote="https://github.com/$OWNER/$repo.git"

  git -C "$dir" init -b main >/dev/null
  git -C "$dir" config user.name "AnaliseMelhor Automation"
  git -C "$dir" config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git -C "$dir" add .
  git -C "$dir" commit -m "Publica hub editorial de 800 páginas" >/dev/null
  git -C "$dir" remote add origin "$remote"
  git -C "$dir" -c http.extraheader="Authorization: basic $(printf 'x-access-token:%s' "$TOKEN" | base64 -w0)" push -u origin main >/dev/null
}

: > "$TMP/urls.raw"
resolve_sitemap "$SOURCE_SITEMAP"

# Somente conteúdo de produto/review. Institucional, navegação e arquivos auxiliares ficam fora.
awk '!seen[$0]++' "$TMP/urls.raw" |
  awk '$0 ~ /^https:\/\/(www\.)?analisemelhor\.com\.br\// {print}' |
  grep -Evi '/(contato|contact|sobre|about|politica|privacidade|privacy|termos|terms|cookies?|autor|authors?|login|entrar|buscar|search|categoria|categorias|category|tag|tags|pagina|page|sitemap|feed|rss|arquivo|archives)(/|$|[?])' |
  grep -Ei '/(review|reviews|analise|analises|melhor|melhores|produto|produtos|comparativo|comparativos|guia|guias|top-|ranking|oferta|ofertas|[0-9]{4})' > "$TMP/candidates.txt" || true

TOTAL="$(wc -l < "$TMP/candidates.txt" | tr -d ' ')"
echo "URLs elegíveis no sitemap: $TOTAL"

# Pré-voo obrigatório: não cria nenhum hub se não houver os 8.000 URLs necessários.
if [ "$TOTAL" -lt "$REQUIRED_URLS" ]; then
  echo "::error::São necessários pelo menos $REQUIRED_URLS URLs elegíveis; encontrados: $TOTAL. Nenhum hub foi criado."
  exit 1
fi

# Execução única: o marcador só é criado depois dos 10 hubs publicados com sucesso.
if [ -f "$LOCK_FILE" ]; then
  echo "::error::Esta geração já foi concluída (GENERATION_COMPLETE). Não execute novamente."
  exit 1
fi
if [ -s "$HUB_MANIFEST" ]; then
  echo "::error::Há um manifest de geração anterior. A execução anterior pode ter sido parcial; não execute novamente automaticamente. Verifique os repositórios criados antes de qualquer nova ação."
  exit 1
fi

# Prepara exatamente os primeiros 8.000 URLs elegíveis, preservando a ordem do sitemap.
head -n "$REQUIRED_URLS" "$TMP/candidates.txt" > "$TMP/selected.txt"
[ "$(wc -l < "$TMP/selected.txt" | tr -d ' ')" -eq "$REQUIRED_URLS" ] || exit 1

: > "$TMP/used.urls"
for i in $(seq 1 "$HUB_COUNT"); do
  n="$(printf '%02d' "$i")"
  start=$(( (i-1) * BATCH_SIZE + 1 ))
  end=$(( i * BATCH_SIZE ))
  sed -n "${start},${end}p" "$TMP/selected.txt" > "$TMP/hub-$n.txt"
  [ "$(wc -l < "$TMP/hub-$n.txt" | tr -d ' ')" -eq "$BATCH_SIZE" ] || {
    echo "::error::Hub $n não contém exatamente $BATCH_SIZE URLs."
    exit 1
  }

  while IFS= read -r url; do
    if grep -Fxq "$url" "$TMP/used.urls"; then
      echo "::error::URL duplicada detectada: $url"
      exit 1
    fi
    printf '%s\n' "$url" >> "$TMP/used.urls"
  done < "$TMP/hub-$n.txt"
done

[ "$(wc -l < "$TMP/used.urls" | tr -d ' ')" -eq "$REQUIRED_URLS" ] || {
  echo "::error::A validação final não encontrou exatamente $REQUIRED_URLS URLs únicas."
  exit 1
}

: > "$HUB_MANIFEST"

for i in $(seq 1 "$HUB_COUNT"); do
  n="$(printf '%02d' "$i")"
  lotfile="$TMP/hub-$n.txt"

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
      best_score="$score"
      best_slug="$slug"
      best_title="$title"
    fi
  done

  suffix="${THEME_SUFFIXES[$(( (i-1) % ${#THEME_SUFFIXES[@]} ))]}"
  repo="analisemelhor-${best_slug}-${suffix}"
  page="https://$OWNER.github.io/$repo"

  reuse_existing=false

  # O primeiro hub pode já ter sido publicado por uma tentativa anterior.
  # Se ele contém exatamente 800 páginas geradas, reutilizamos o resultado e
  # seguimos para os demais hubs. Qualquer outro repositório existente é colisão.
  if repo_exists "$repo"; then
    if [ "$repo" = "analisemelhor-casa-guias" ] && { repo_is_empty "$repo" || repo_has_800_pages "$repo"; }; then
      reuse_existing=true
      echo "Reutilizando o hub já preparado: $OWNER/$repo"
    else
      echo "::error::O repositório alvo $OWNER/$repo já existe e não está em estado seguro para reutilização. Geração interrompida."
      exit 1
    fi
  fi

  site="$TMP/site-$n"
  mkdir -p "$site/pages" "$site/.github/workflows"

  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>$best_title — AnaliseMelhor</title>"
    echo "<meta name="description" content="Hub editorial com $BATCH_SIZE referências de produtos e reviews sobre $best_title.">"
    echo "<link rel="canonical" href="$page/">"
    echo '<style>body{font-family:system-ui,sans-serif;max-width:1000px;margin:auto;padding:32px;line-height:1.65}li{margin:.45rem 0}a{color:#0b57d0}</style></head><body>'
    echo "<h1>$best_title</h1><p>Hub editorial com $BATCH_SIZE referências de produtos e reviews. Cada página apresenta uma referência e direciona para a análise original no AnaliseMelhor.</p><ol>"
  } > "$site/index.html"

  page_no=0
  while IFS= read -r url; do
    page_no=$((page_no+1))
    slug_text="$(url_slug "$url")"
    safe_title="$(printf '%s' "$slug_text" | escape_html)"
    safe_url="$(printf '%s' "$url" | escape_html)"
    {
      echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      echo "<title>$safe_title — Análise e Review | AnaliseMelhor</title>"
      echo "<meta name="description" content="Referência editorial sobre $safe_title, com acesso à análise completa no AnaliseMelhor.">"
      echo '<style>body{font-family:system-ui,sans-serif;max-width:850px;margin:auto;padding:32px;line-height:1.7}a{color:#0b57d0}</style></head><body><main>'
      echo "<h1>$safe_title</h1>"
      echo "<p>Esta página reúne uma referência editorial sobre <strong>$safe_title</strong>. Para consultar o conteúdo completo, especificações, comparações e informações atualizadas, acesse a análise original no AnaliseMelhor.</p>"
      echo "<p><a href="$safe_url" rel="nofollow">Ler a análise completa no AnaliseMelhor</a></p>"
      echo '</main></body></html>'
    } > "$site/pages/$page_no.html"
    printf '<li><a href="pages/%s.html">%s</a></li>\n' "$page_no" "$safe_title" >> "$site/index.html"
  done < "$lotfile"

  echo '</ol></body></html>' >> "$site/index.html"

  printf '%s' "$INDEXNOW_KEY" > "$site/indexnow-key.txt"
  : > "$site/.nojekyll"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: $page/sitemap.xml" > "$site/robots.txt"

  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    echo "<url><loc>$page/</loc><lastmod>$(date -u +%F)</lastmod></url>"
    for page_no in $(seq 1 "$BATCH_SIZE"); do
      echo "<url><loc>$page/pages/$page_no.html</loc><lastmod>$(date -u +%F)</lastmod></url>"
    done
    echo '</urlset>'
  } > "$site/sitemap.xml"

  cat > "$site/.github/workflows/pages.yml" <<'YAML'
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

  # O repositório só é criado depois de todo o lote estar pronto localmente.
  # Se o primeiro hub já estiver completo, não sobrescrevemos nem fazemos push:
  # apenas registramos o lote e seguimos para o próximo.
  if [ "$reuse_existing" = "true" ]; then
    echo "Hub $i/10 já estava completo; publicação ignorada com segurança."
  else
    if ! repo_exists "$repo"; then
      create_repo "$repo" "$best_title"
    fi
    enable_pages "$repo"
    publish_repo "$repo" "$site"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$best_title" "$i" "$start" "$end" "$BATCH_SIZE" >> "$HUB_MANIFEST"
  echo "Hub $i/10 publicado: $repo — URLs $start-$end — $BATCH_SIZE páginas."
done

printf "Geração concluída: 10 hubs x 800 URLs = 8.000 URLs únicas.\\n" > "$LOCK_FILE"
echo "Concluído: exatamente 10 hubs, 800 URLs únicas por hub, 8.000 URLs totais."

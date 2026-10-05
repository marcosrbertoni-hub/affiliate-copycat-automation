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
HUB_MANIFEST="${GITHUB_WORKSPACE:-.}/generated-editorial-hubs.tsv"
LOCK_FILE="${GITHUB_WORKSPACE:-.}/EDITORIAL_ARTICLES_COMPLETE"
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


slugify() {
  printf '%s' "$1" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g' | cut -c1-110
}
repo_has_800_articles() {
  local repo="$1" body count
  body="$(api "$API/repos/$OWNER/$repo/git/trees/main?recursive=1")" || return 1
  count="$(printf '%s' "$body" | jq '[.tree[]? | select(.type == "blob" and (.path | startswith("artigos/")) and (.path | endswith(".html")))] | length')"
  [ "$count" = "$BATCH_SIZE" ]
}
fetch_source_metadata() {
  local url="$1" out="$2"
  local html="$out/source.html"
  mkdir -p "$out"
  if ! curl -fsSL --retry 2 --retry-delay 1 --max-time 15 -A "AnaliseMelhor-Editorial-Hub/1.0" "$url" > "$html" 2>/dev/null; then
    : > "$out/title"; : > "$out/description"; : > "$out/facts"; return 0
  fi
  python3 - "$html" "$out/title" "$out/description" "$out/facts" <<'PY'
import html as h,re,sys
source,title_file,desc_file,facts_file=sys.argv[1:]
text=open(source,"r",encoding="utf-8",errors="ignore").read()
def clean(v):
    v=re.sub(r"<[^>]+>"," ",v or ""); v=h.unescape(v); return re.sub(r"\s+"," ",v).strip()
m=re.search(r"<title[^>]*>(.*?)</title>",text,re.I|re.S); title=clean(m.group(1)) if m else ""
desc=""
for p in (r'<meta[^>]+name=["\']description["\'][^>]+content=["\'](.*?)["\']',r'<meta[^>]+content=["\'](.*?)["\'][^>]+name=["\']description["\']'):
    m=re.search(p,text,re.I|re.S)
    if m: desc=clean(m.group(1)); break
facts=[]; seen=set()
for tag in ("h2","h3","li"):
    for m in re.finditer(rf"<{tag}\b[^>]*>(.*?)</{tag}>",text,re.I|re.S):
        v=clean(m.group(1)); k=v.lower()
        if 20<=len(v)<=180 and k not in seen and not re.search(r"menu|cookie|privacidade|termos|compartilhe|coment",v,re.I):
            facts.append(v); seen.add(k)
        if len(facts)>=8: break
    if len(facts)>=8: break
open(title_file,"w",encoding="utf-8").write(title+"\n")
open(desc_file,"w",encoding="utf-8").write(desc+"\n")
open(facts_file,"w",encoding="utf-8").write("\n".join(facts[:8])+("\n" if facts else ""))
PY
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

  # Se o repositório já tiver conteúdo de uma tentativa anterior, preserva o
  # histórico remoto e atualiza o lote gerado de forma segura. Como o lote
  # é determinístico, o resultado final continua sendo exatamente as 800
  # páginas daquele intervalo.
  if git -C "$dir" fetch origin main >/dev/null 2>&1; then
    remote_sha="$(git -C "$dir" rev-parse refs/remotes/origin/main)"
    git -C "$dir" -c http.extraheader="Authorization: basic $(printf 'x-access-token:%s' "$TOKEN" | base64 -w0)" push --force-with-lease=main:"$remote_sha" -u origin main >/dev/null
  else
    git -C "$dir" -c http.extraheader="Authorization: basic $(printf 'x-access-token:%s' "$TOKEN" | base64 -w0)" push -u origin main >/dev/null
  fi
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

  # O décimo lote é o único que precisa de uma retomada especial: se o nome
  # temático calculado já pertencer a um dos nove hubs concluídos, não reutilizar
  # esse repositório para outro lote. Usa-se um nome temático exclusivo do lote 10.
  if [ "$i" = "10" ] && repo_exists "$repo" && repo_has_800_pages "$repo"; then
    repo="${repo}-lote-10"
    echo "Nome temático do lote 10 já ocupado; usando hub exclusivo: $OWNER/$repo"
  fi

  page="https://$OWNER.github.io/$repo"

  reuse_existing=false

  # Retomada automática: qualquer hub que já tenha sido concluído é pulado,
  # independentemente do nome/tema. Um hub vazio pode ser preenchido normalmente.
  # Um hub parcial também pode ser atualizado com o lote determinístico completo,
  # preservando o histórico remoto e evitando a interrupção da geração.
  if repo_exists "$repo"; then
    if repo_has_800_articles "$repo"; then
      reuse_existing=true
      echo "Hub já possui 800 artigos editoriais: $OWNER/$repo — publicação ignorada."
    elif repo_is_empty "$repo"; then
      echo "Reutilizando repositório vazio: $OWNER/$repo"
    else
      echo "Repositório existente sem os 800 artigos editoriais: será atualizado preservando as páginas legadas."
    fi
  fi

  site="$TMP/site-$n"
  mkdir -p "$site/pages" "$site/artigos" "$site/.github/workflows"

  # Se o hub já existe e é parcial, trazemos o conteúdo remoto para o diretório
  # temporário. Assim, uma nova execução continua dos artigos que já foram
  # escritos em vez de começar novamente do zero.
  if repo_exists "$repo" && ! repo_has_800_articles "$repo" && ! repo_is_empty "$repo"; then
    # Recuperação de hub parcial via API do GitHub. Evita depender da autenticação
    # do Git over HTTPS do runner; a mesma credencial já foi validada pelas chamadas
    # à API acima.
    archive="$TMP/$n-$repo.zip"
    extract="$TMP/extract-$n"
    mkdir -p "$extract"
    if ! curl -fsSL --retry 3 --retry-delay 2 \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $TOKEN" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "$API/repos/$OWNER/$repo/zipball/main" -o "$archive"; then
      echo "Não foi possível recuperar o hub parcial $OWNER/$repo pela API do GitHub." >&2
      exit 1
    fi
    unzip -q "$archive" -d "$extract"
    source_dir="$(find "$extract" -mindepth 1 -maxdepth 1 -type d -print -quit)"
    [ -n "$source_dir" ] || {
      echo "O arquivo do hub parcial $OWNER/$repo não contém um diretório válido." >&2
      exit 1
    }
    cp -a "$source_dir"/. "$site"/
    mkdir -p "$site/artigos" "$site/pages" "$site/.github/workflows"
    echo "Retomando $OWNER/$repo a partir do conteúdo remoto já publicado."
  fi

  {
    echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    echo "<title>$best_title — Guias, análises e recomendações | AnaliseMelhor</title>"
    echo "<meta name="description" content="Portal editorial sobre $best_title, com guias de compra, análises, características e pontos de atenção.">"
    echo "<link rel="canonical" href="$page/">"
    echo '<style>body{font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;max-width:1120px;margin:auto;padding:24px;line-height:1.7;color:#202124;min-height:100vh;background:linear-gradient(135deg,#b91c1c 0%,#2563eb 50%,#b91c1c 100%);background-attachment:fixed}header{padding:28px 24px 18px;border:1px solid rgba(255,255,255,.75);border-radius:16px;background:rgba(255,255,255,.94);box-shadow:0 8px 28px rgba(0,0,0,.12)}h1{font-size:clamp(2rem,4vw,3.2rem);line-height:1.1}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:18px;margin:28px 0}.card{border:1px solid rgba(255,255,255,.85);border-radius:14px;padding:20px;background:rgba(255,255,255,.94);box-shadow:0 6px 20px rgba(0,0,0,.1)}.tag{font-size:.75rem;font-weight:700;text-transform:uppercase;color:#555}a{color:#0645ad;text-decoration:none}a:hover{text-decoration:underline}.section{margin-top:42px;padding:22px;border-radius:16px;background:rgba(255,255,255,.86);box-shadow:0 8px 28px rgba(0,0,0,.1)}</style></head><body><header><span class="tag">Portal editorial</span><h1>Portal editorial</h1><p>Guias e análises independentes para ajudar na pesquisa de produtos. Cada artigo trata de um assunto específico e indica a análise correspondente no AnaliseMelhor.</p></header><main><section class="section"><h2>Artigos em destaque</h2><div class="grid">'
  } > "$site/index.html"

  page_no=0
  while IFS= read -r url; do
    page_no=$((page_no+1))
    meta_dir="$TMP/meta-$n-$page_no"

    # Checkpoint: se este artigo já existe no hub remoto recuperado, preserva-o.
    if compgen -G "$site/artigos/*-$page_no.html" > /dev/null; then
      echo "Artigo $page_no/800 já existe; continuando para o próximo."
      continue
    fi
    fetch_source_metadata "$url" "$meta_dir"
    raw_source_title="$(head -n 1 "$meta_dir/title" 2>/dev/null || true)"
    raw_source_desc="$(head -n 1 "$meta_dir/description" 2>/dev/null || true)"
    subject="$raw_source_title"
    [ -n "$subject" ] || subject="$(url_slug "$url")"
    subject="$(printf '%s' "$subject" | sed -E 's/[[:space:]]+[|—–-][[:space:]]+AnaliseMelhor.*$//I; s/[[:space:]]+/ /g; s/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -n "$subject" ] || subject="Guia de compra $page_no"
    safe_title="$(printf '%s' "$subject" | escape_html)"
    safe_url="$(printf '%s' "$url" | escape_html)"
    article_slug="$(slugify "$subject")"
    [ -n "$article_slug" ] || article_slug="artigo-$page_no"
    article_slug="$article_slug-$page_no"
    article_path="artigos/$article_slug.html"
    article_page="$page/$article_path"
    safe_desc="$(printf '%s' "$raw_source_desc" | cut -c1-220 | escape_html)"
    [ -n "$safe_desc" ] || safe_desc="Guia editorial sobre $safe_title, com características, critérios de escolha e pontos de atenção."

    {
      echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      echo "<title>$safe_title — análise, características e guia de compra</title>"
      echo "<meta name="description" content="$safe_desc">"
      echo "<link rel="canonical" href="$article_page">"
      echo '<style>body{font-family:system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;max-width:900px;margin:auto;padding:24px;line-height:1.8;color:#202124;min-height:100vh;background:linear-gradient(135deg,#b91c1c 0%,#2563eb 50%,#b91c1c 100%);background-attachment:fixed}h1{font-size:clamp(2rem,4vw,3rem);line-height:1.15}h2{margin-top:2.1rem}.eyebrow{font-size:.75rem;font-weight:700;text-transform:uppercase;color:#555}.note{padding:18px;border-left:4px solid #222;background:#f6f7f8}a{color:#0b57d0}</style></head><body><article>'
      echo "<p class=eyebrow>$best_title</p><h1>$safe_title</h1>"
      echo "<p>Pesquisar <strong>$safe_title</strong> exige mais do que olhar apenas para o preço. Este guia editorial organiza os principais pontos que merecem atenção antes de uma decisão de compra.</p>"
      if [ -s "$meta_dir/facts" ]; then
        echo '<h2>Informações encontradas sobre o tema</h2><ul>'
        while IFS= read -r fact; do
          [ -n "$fact" ] && printf '<li>%s</li>\n' "$(printf '%s' "$fact" | escape_html)"
        done < <(head -n 6 "$meta_dir/facts")
        echo '</ul>'
      else
        echo '<h2>O que analisar antes de escolher</h2><p>Compare especificações, compatibilidade, dimensões, recursos, garantia e condições de compra. Esses critérios ajudam a separar uma opção adequada para o uso pretendido de uma escolha baseada somente em preço.</p>'
      fi
      echo '<h2>Como avaliar uma opção</h2><p>Identifique primeiro o uso principal e os recursos realmente necessários. Depois compare as características que têm impacto direto nesse uso. Em modelos semelhantes, observe construção, capacidade, acessórios, compatibilidade e facilidade de manutenção. Preço, estoque e disponibilidade também podem mudar.</p>'
      if [ -n "$raw_source_desc" ]; then
        source_desc_clean="$(printf '%s' "$raw_source_desc" | cut -c1-500 | escape_html)"
        echo "<div class=note><strong>Resumo da referência:</strong> $source_desc_clean</div>"
      fi
      echo '<h2>Pontos de atenção</h2><p>Confira a ficha técnica, medidas, compatibilidades, política de troca, garantia, acessórios incluídos e reputação do vendedor. Para produtos de uso específico, uma diferença importante pode estar em um detalhe que não aparece no preço anunciado.</p>'
      echo '<h2>Para quem pode fazer sentido</h2><p>A escolha tende a ser mais adequada quando as características correspondem ao uso pretendido. Compare necessidades, orçamento e recursos importantes para o seu caso em vez de procurar uma opção universalmente melhor.</p>'
      echo '<h2>Consulte a análise correspondente</h2><p>Para consultar a referência completa, comparações e informações adicionais relacionadas a este tema, veja a análise correspondente no AnaliseMelhor.</p>'
      echo "<p><a href="$safe_url" rel="nofollow">Ler a análise completa no AnaliseMelhor</a></p>"
      echo '</article></body></html>'
    } > "$site/$article_path"

    slug_text="$(url_slug "$url")"
    safe_legacy_title="$(printf '%s' "$slug_text" | escape_html)"
    {
      echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      echo "<title>$safe_legacy_title — referência | AnaliseMelhor</title>"
      echo "<meta name="description" content="Referência editorial sobre $safe_legacy_title, com acesso à análise completa no AnaliseMelhor.">"
      echo '<style>body{font-family:system-ui,sans-serif;max-width:850px;margin:auto;padding:32px;line-height:1.7;min-height:100vh;background:linear-gradient(135deg,#b91c1c 0%,#2563eb 50%,#b91c1c 100%);background-attachment:fixed}a{color:#0b57d0}</style></head><body><main>'
      echo "<h1>$safe_legacy_title</h1><p>Referência editorial preservada para este assunto. Consulte também o novo artigo editorial deste hub.</p>"
      echo "<p><a href="../$article_path">Ler o artigo editorial</a></p>"
      echo "<p><a href="$safe_url" rel="nofollow">Consultar a análise original no AnaliseMelhor</a></p>"
      echo '</main></body></html>'
    } > "$site/pages/$page_no.html"

    if [ "$page_no" -le 18 ]; then
      {
        echo '<article class=card>'
        echo "<span class=tag>$best_title</span><h2><a href="$article_path">$safe_title</a></h2>"
        echo '<p>Guia editorial com características, critérios de escolha e pontos de atenção.</p></article>'
      } >> "$site/index.html"
    fi
  done < "$lotfile"

  echo '</div></section><section class=section><h2>Navegar pelos 800 artigos</h2><p><a href="artigos/index.html">Ver todos os 800 artigos e navegar por páginas →</a></p></section><section class=section><h2>Como usar este portal</h2><p>Os artigos foram organizados individualmente por assunto. Explore os temas e, quando precisar da análise de origem, siga o link contextual para o AnaliseMelhor.</p></section></main></body></html>' >> "$site/index.html"

  bash scripts/build-navigation.sh "$site" "$best_title" "$BATCH_SIZE"
  printf '%s' "$INDEXNOW_KEY" > "$site/indexnow-key.txt"
  : > "$site/.nojekyll"
  printf '%s\n' 'User-agent: *' 'Allow: /' "Sitemap: $page/sitemap.xml" > "$site/robots.txt"

  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
    echo "<url><loc>$page/</loc><lastmod>$(date -u +%F)</lastmod></url>"
    echo "<url><loc>$page/artigos/index.html</loc><lastmod>$(date -u +%F)</lastmod></url>"
    for nav_file in "$site"/artigos/pagina-*.html; do
      nav_name="$(basename "$nav_file")"
      echo "<url><loc>$page/artigos/$nav_name</loc><lastmod>$(date -u +%F)</lastmod></url>"
    done
    for article_file in "$site"/artigos/*.html; do
      article_name="$(basename "$article_file")"
      echo "<url><loc>$page/artigos/$article_name</loc><lastmod>$(date -u +%F)</lastmod></url>"
    done
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
  # Hub completo: não toca nele. Hub vazio/parcial: publica o lote completo.
  if [ "$reuse_existing" = "true" ]; then
    echo "Hub $i/10 já possui os 800 artigos editoriais; publicação ignorada com segurança."
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

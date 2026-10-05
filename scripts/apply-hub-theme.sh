#!/usr/bin/env bash
set -euo pipefail
OWNER="${GITHUB_OWNER:-marcosrbertoni-hub}"
TOKEN="${SATELLITE_REPO_TOKEN:?SATELLITE_REPO_TOKEN não configurado}"
API="https://api.github.com"
REPOS=(analisemelhor-casa-guias analisemelhor-moda-comparativos analisemelhor-casa-selecoes analisemelhor-casa-recomendacoes analisemelhor-casa-reviews analisemelhor-casa-comparativos analisemelhor-informatica-selecoes analisemelhor-ferramentas-recomendacoes analisemelhor-celulares-reviews analisemelhor-celulares-reviews-lote-10)
for repo in "${REPOS[@]}"; do
  echo "Atualizando tema de $OWNER/$repo"
  work="$(mktemp -d)"; archive="$work/repo.zip"; extract="$work/extract"; mkdir -p "$extract"
  curl -fsSL --retry 3 --retry-delay 2 -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $TOKEN" -H "X-GitHub-Api-Version: 2022-11-28" "$API/repos/$OWNER/$repo/zipball/main" -o "$archive"
  unzip -q "$archive" -d "$extract"; src="$(find "$extract" -mindepth 1 -maxdepth 1 -type d -print -quit)"; [ -n "$src" ]
  python3 - "$src" <<'PY'
import pathlib,re,sys
root=pathlib.Path(sys.argv[1])
g="linear-gradient(135deg,#b91c1c 0%,#2563eb 50%,#b91c1c 100%)"
for p in list(root.glob("artigos/*.html"))+list(root.glob("pages/*.html"))+[root/"index.html"]:
    if not p.exists(): continue
    s=p.read_text(encoding="utf-8",errors="ignore")
    if g in s: continue
    s=re.sub(r'body{([^}]*)}',lambda m:"body{"+m.group(1)+";background:"+g+";background-attachment:fixed;min-height:100vh}",s,count=1)
    if g not in s:
        s=s.replace("</style>",f"body{{background:{g};background-attachment:fixed;min-height:100vh}}</style>",1)
    p.write_text(s,encoding="utf-8")
PY
  cd "$src"; git init -b main >/dev/null; git config user.name "AnaliseMelhor Automation"; git config user.email "41898282+github-actions[bot]@users.noreply.github.com"; git add .
  if git diff --cached --quiet; then cd - >/dev/null; rm -rf "$work"; continue; fi
  git commit -m "Aplica layout vermelho e azul aos artigos" >/dev/null
  git remote add origin "https://github.com/$OWNER/$repo.git"
  git fetch origin main >/dev/null 2>&1
  remote_sha="$(git rev-parse refs/remotes/origin/main)"
  git -c http.extraheader="Authorization: basic $(printf 'x-access-token:%s' "$TOKEN" | base64 -w0)" push --force-with-lease=main:"$remote_sha" -u origin main >/dev/null
  cd - >/dev/null; rm -rf "$work"; echo "Concluído: $repo"
done

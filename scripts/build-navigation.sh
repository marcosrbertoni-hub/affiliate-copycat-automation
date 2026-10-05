#!/usr/bin/env bash
set -euo pipefail
site="$1"
best_title="$2"
batch_size="$3"
article_list="$site/.article-list.tmp"
find "$site/artigos" -maxdepth 1 -type f -name '*.html' ! -name 'index.html' ! -name 'pagina-*.html' | sort -V > "$article_list"
count="$(wc -l < "$article_list" | tr -d ' ')"
[ "$count" = "$batch_size" ] || { echo "::error::Navegação: esperados $batch_size artigos, encontrados $count."; exit 1; }

{
 echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
 echo "<title>Todos os $batch_size artigos — $best_title</title>"
 echo '<meta name="description" content="Índice com acesso a todos os artigos editoriais deste portal.">'
 echo '<style>body{font-family:system-ui,sans-serif;max-width:980px;margin:auto;padding:24px;line-height:1.7;color:#202124}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:12px;margin:28px 0}.grid a{display:block;padding:14px;border:1px solid #e5e7eb;border-radius:10px;color:#0b57d0;text-decoration:none}</style></head><body><main><p><a href="../">← Início do portal</a></p>'
 echo "<h1>Todos os $batch_size artigos</h1><p>Use as páginas abaixo para navegar por todo o conteúdo editorial deste hub.</p><div class=grid>"
 for p in $(seq 1 40); do
   start=$(( (p - 1) * 20 + 1 ))
   end=$(( p * 20 ))
   echo "<a href="./pagina-$(printf '%02d' "$p").html">Artigos $start–$end</a>"
 done
 echo '</div></main></body></html>'
} > "$site/artigos/index.html"

for p in $(seq 1 40); do
 start=$(( (p - 1) * 20 + 1 ))
 end=$(( p * 20 ))
 {
  echo '<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
  echo "<title>Artigos $p — $best_title</title>"
  echo '<meta name="description" content="Índice paginado dos artigos editoriais deste hub.">'
  echo '<style>body{font-family:system-ui,sans-serif;max-width:980px;margin:auto;padding:24px;line-height:1.7;color:#202124}a{color:#0b57d0}.list li{margin:9px 0}.pagination{display:flex;gap:10px;flex-wrap:wrap;margin:28px 0;padding:14px 0;border-block:1px solid #e5e7eb}.pagination a,.pagination strong{padding:5px 9px}</style></head><body><main><p><a href="./index.html">← Todos os artigos</a></p>'
  echo "<h1>Artigos $p de 40</h1><ol class=list>"
  sed -n "$start,\${end}p" "$article_list" | while IFS= read -r f; do
    name="$(basename "$f")"
    label="$(printf '%s' "$name" | sed -E 's/\.html$//; s/-[0-9]+$//; s/-/ /g')"
    echo "<li><a href="./$name">$label</a></li>"
  done
  echo '</ol><nav class=pagination>'
  if [ "$p" -gt 1 ]; then prev=$((p-1)); echo "<a href="./pagina-$(printf '%02d' "$prev").html">Anterior</a>"; fi
  first=$((p-2)); [ "$first" -lt 1 ] && first=1
  last=$((p+2)); [ "$last" -gt 40 ] && last=40
  for n in $(seq "$first" "$last"); do
    if [ "$n" -eq "$p" ]; then echo "<strong>$n</strong>"; else echo "<a href="./pagina-$(printf '%02d' "$n").html">$n</a>"; fi
  done
  if [ "$p" -lt 40 ]; then next=$((p+1)); echo "<a href="./pagina-$(printf '%02d' "$next").html">Próxima</a>"; fi
  echo '</nav></main></body></html>'
 } > "$site/artigos/pagina-$(printf '%02d' "$p").html"
done
rm -f "$article_list"

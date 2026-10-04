# Estrelas e snippets de produto

## Objetivo
Exibir estrelas apenas quando houver uma nota real e verificável para o produto e fornecer ao Google os dados estruturados correspondentes.

## Implementação
- Detectar notas e quantidades de avaliações já presentes nos dados importados de cada produto.
- Mostrar estrelas, nota e total de avaliações junto ao produto somente quando os dois valores forem válidos.
- Adicionar `Product` com `AggregateRating` ao JSON-LD da página somente para produtos com dados reais; páginas sem nota continuam sem estrelas.
- Manter título, conteúdo, links afiliados e desempenho atuais intactos.
- Validar uma amostra de páginas com e sem avaliações, além do build e dos dados estruturados renderizados.

## Regra de segurança para SEO
Não inventar avaliações nem copiar uma nota sem fonte identificável. Marcação enganosa pode causar ação manual e remover todos os resultados avançados do domínio.

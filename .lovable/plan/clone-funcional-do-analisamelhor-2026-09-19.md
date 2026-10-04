# Clone funcional do AnalisaMelhor

## Objetivo
Recriar a experiência visual do portal de reviews, com página inicial navegável, busca, categorias e um modelo completo de artigo. Todo conteúdo editorial ficará centralizado e todo link de produto passará obrigatoriamente pelo mesmo normalizador de afiliados.

## O que será construído
- Cabeçalho fixo com marca, categorias coloridas, busca e navegação adaptada para celular.
- Página inicial com abertura editorial, grade de recomendações, categorias e artigos recentes.
- Busca funcional por título, categoria, resumo e produtos.
- Página dinâmica de artigo com breadcrumb, dados editoriais, Top 3, tabela comparativa, análises individuais, prós e contras e FAQ expansível.
- Rodapé editorial com links institucionais e aviso sobre comissões.
- Estados de interação e movimento discretos, preservando acessibilidade e redução de movimento.

## Conteúdo centralizado
- Criar `src/data/posts.ts` com categorias, artigos, produtos, especificações, rankings, prós, contras e perguntas frequentes.
- Gerar a página inicial e os artigos a partir desse arquivo, evitando textos e produtos espalhados pelos componentes.
- Incluir conteúdo demonstrativo coerente, fácil de substituir diretamente no arquivo central.

## Links de afiliados
- Criar uma função única para processar qualquer URL de produto antes de renderizá-la.
- Remover parâmetros concorrentes ou antigos e aplicar exatamente `tag=shoptimego09-20&linkCode=as4&ref_=onb_gen_lnk&th=1`.
- Preservar o domínio, caminho e parâmetros não relacionados ao rastreamento.
- Usar essa função em todos os botões e links de compra, sem exceções.

## Direção visual
- Reproduzir a linguagem editorial observada: cabeçalho azul-marinho, marca coral, títulos serifados, texto limpo e metadados monoespaçados.
- Usar tokens semânticos para cores, tipografia, sombras e raios, mantendo consistência em todas as telas.
- Baixar ou gerar imagens locais adequadas para que a experiência não dependa de imagens externas em tempo de uso.

## Estrutura técnica
- Manter TanStack Start e criar uma rota dinâmica de artigo em `/artigos/$slug`.
- Criar componentes pequenos para cabeçalho, busca, cards, tabela comparativa, prós/contras e FAQ.
- Adicionar títulos e descrições sociais próprios para a página inicial e para cada artigo.

## Validação
- Verificar compilação e ausência de erros no navegador.
- Testar busca, menu móvel, FAQ e todos os links de compra.
- Conferir visualmente a página inicial e um artigo em desktop e celular.
- Confirmar que os links finais contêm o padrão de afiliado solicitado.

# Automação editorial do AnaliseMelhor

Este repositório é exclusivo da automação. O repositório principal `affiliate-copycat-pro` não é usado nem alterado.

## Como os hubs são definidos

A automação lê o sitemap do `analisemelhor.com.br`, resolve os sitemaps filhos e classifica cada URL pelo assunto indicado no próprio endereço.

Os hubs recebem nomes editoriais coerentes, por exemplo:

- `analisemelhor-casa`
- `analisemelhor-cozinha`
- `analisemelhor-eletronicos`
- `analisemelhor-informatica`
- `analisemelhor-celulares`
- `analisemelhor-esportes`
- `analisemelhor-ferramentas`
- `analisemelhor-automotivo`
- `analisemelhor-beleza`
- `analisemelhor-moda`
- `analisemelhor-saude`
- `analisemelhor-guias-e-comparativos` para URLs que não tenham sinal suficiente para outra categoria.

**Importante:** não existe mais a lógica de criar `satellite-01`, `satellite-02` etc. E a automação não é obrigada a criar 10 hubs: somente categorias que realmente tenham URLs são publicadas.

Os hubs funcionam como índices temáticos. Eles não copiam os artigos do AnaliseMelhor.

## IndexNow

Depois que os hubs ficam disponíveis no GitHub Pages, a automação envia cada endereço público ao IndexNow. O workflow usa um manifesto gerado na mesma execução para enviar somente os hubs que realmente foram criados.

## Secrets

Em **Settings → Secrets and variables → Actions**, crie:

1. `SATELLITE_REPO_TOKEN` — token com permissão para criar repositórios públicos na conta e administrar GitHub Pages.
2. `INDEXNOW_KEY` — chave IndexNow válida.

O `GITHUB_TOKEN` automático do workflow não tem escopo para criar e administrar outros repositórios; por isso o token separado é necessário.

## Execução

O workflow pode ser executado manualmente em **Actions → AnaliseMelhor — criar e atualizar hubs temáticos → Run workflow** ou automaticamente uma vez por dia.

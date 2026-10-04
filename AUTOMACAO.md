# Configuração da automação

Este repositório é exclusivo da máquina de automação. O repositório principal `affiliate-copycat-pro` não é usado nem alterado.

## Fluxo

- Lê e resolve `https://analisemelhor.com.br/sitemap.xml`.
- Divide as URLs em exatamente 10 lotes equilibrados.
- Cria/atualiza os repositórios `analisemelhor-satellite-01` até `analisemelhor-satellite-10`.
- Ativa GitHub Pages e publica um índice de navegação em cada hub.
- Gera `sitemap.xml`, `robots.txt` e arquivo de verificação do IndexNow.
- Envia a URL pública de cada hub ao IndexNow depois que o Pages estiver disponível.

Os hubs não copiam o conteúdo dos artigos. Os links para o conteúdo original usam `rel="nofollow"`.

## Secrets

Em **Settings → Secrets and variables → Actions**, crie:

1. `SATELLITE_REPO_TOKEN` — token com permissão para criar repositórios públicos na conta e administrar GitHub Pages.
2. `INDEXNOW_KEY` — chave IndexNow válida.

O `GITHUB_TOKEN` automático do workflow não tem escopo para criar e administrar outros repositórios; por isso o token separado é necessário.

## Execução

O workflow pode ser executado manualmente em **Actions → AnaliseMelhor — criar e atualizar 10 hubs → Run workflow** ou automaticamente uma vez por dia.

# Automação editorial do AnaliseMelhor

Este repositório é exclusivo da automação. O repositório principal `affiliate-copycat-pro` não é usado nem alterado.

## Regra de distribuição

A automação lê o sitemap do `analisemelhor.com.br` e considera somente URLs de conteúdo de produto/review.

URLs institucionais ou de navegação são excluídas, incluindo contato, sobre, política de privacidade, termos, cookies, login, busca, categorias, tags, sitemap e feeds.

A distribuição é **sequencial e sem repetição**:

- URLs 1–800 → hub 1
- URLs 801–1.600 → hub 2
- URLs 1.601–2.400 → hub 3
- e assim por diante
- máximo de 10 hubs nesta execução.

Uma URL que entrou em um lote não pode entrar em outro. O script mantém uma lista de URLs utilizadas e aborta se detectar duplicação.

Cada lote é dividido em páginas internas com **3 a 5 URLs relacionadas por página**, sempre preservando a ordem e sem repetir URLs.

## Conteúdo das páginas

As páginas são índices editoriais de produtos/reviews. Cada referência aponta para a análise correspondente no AnaliseMelhor.

A automação não copia o artigo principal. O texto editorial é curto e contextual, e o link aponta para a fonte original.

## Repositórios

Os hubs são criados como repositórios públicos independentes no GitHub Pages.

Os nomes devem refletir o tema predominante do lote, quando isso puder ser determinado. O conteúdo do lote continua sendo definido pela posição no sitemap; o nome não pode causar redistribuição ou repetição das URLs.

## IndexNow

Após o deploy, a automação pode notificar o IndexNow sobre as páginas públicas dos hubs.

IndexNow é apenas uma notificação de URLs para mecanismos compatíveis; não garante indexação, ranking ou tráfego.

## Execução

A automação **não possui execução diária**.

O workflow fica disponível em:

**Actions → AnaliseMelhor — criar e atualizar hubs temáticos → Run workflow**

A intenção é executar a geração inicial uma vez, depois revisar os resultados antes de qualquer nova execução.

## Secrets

Em **Settings → Secrets and variables → Actions**:

1. `SATELLITE_REPO_TOKEN` — token para criação/administração dos repositórios e Pages.
2. `INDEXNOW_KEY` — chave IndexNow.

Nunca coloque valores desses secrets no código ou em commits.

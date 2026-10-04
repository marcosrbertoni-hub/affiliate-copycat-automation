# Automação editorial do AnaliseMelhor

Este repositório é exclusivo da automação. O repositório principal `affiliate-copycat-pro` não é usado nem alterado.

## Regra fixa de distribuição

A automação lê o sitemap do `analisemelhor.com.br` e considera somente URLs de conteúdo de produto/review.

São excluídas páginas institucionais, navegação e arquivos auxiliares, incluindo contato, sobre, política de privacidade, termos, cookies, login, busca, categorias, tags, sitemap, feeds e arquivos.

A distribuição é **posicional, sequencial e sem repetição**:

- URLs 1–800 → hub 1
- URLs 801–1.600 → hub 2
- URLs 1.601–2.400 → hub 3
- URLs 2.401–3.200 → hub 4
- URLs 3.201–4.000 → hub 5
- URLs 4.001–4.800 → hub 6
- URLs 4.801–5.600 → hub 7
- URLs 5.601–6.400 → hub 8
- URLs 6.401–7.200 → hub 9
- URLs 7.201–8.000 → hub 10

A automação exige **pelo menos 8.000 URLs elegíveis antes de criar qualquer repositório**. Ela usa exatamente as primeiras 8.000 URLs elegíveis e cria exatamente 10 hubs com 800 URLs cada.

Cada URL aparece em **uma única página interna**. Portanto, cada hub possui:

- 800 URLs de origem;
- 800 páginas internas, uma por URL;
- 1 página inicial do hub;
- sitemap com a página inicial + 800 páginas internas.

Há uma validação global que aborta se qualquer URL se repetir.

## Nomes dos repositórios

O lote continua sendo definido exclusivamente pela posição no sitemap. O tema predominante é usado apenas para dar um nome descritivo ao repositório, sem alterar a distribuição.

Exemplos de padrões usados: `analisemelhor-cozinha-guias`, `analisemelhor-informatica-comparativos`, `analisemelhor-esportes-selecoes`.

## Publicação

Para evitar milhares de commits, cada hub é:

1. montado localmente no runner;
2. validado com 800 URLs;
3. criado como repositório público;
4. configurado para GitHub Pages;
5. publicado com **um único push**.

O repositório principal `affiliate-copycat-pro` nunca é alterado.

## Execução única

O workflow não possui cron e não roda diariamente.

Ele é manual:

**Actions → AnaliseMelhor — criar e atualizar hubs temáticos → Run workflow**

O script também bloqueia uma nova execução quando `generated-hubs.tsv` já contém uma geração concluída ou quando um repositório alvo já existe. Isso evita redistribuição acidental ou repetição de URLs.

**Não execute novamente depois de uma geração concluída.**

## IndexNow

Depois da publicação, a automação espera cada GitHub Pages disponibilizar a chave e envia para o IndexNow:

- a página inicial do hub;
- as 800 páginas internas do hub.

IndexNow é somente uma notificação para mecanismos compatíveis; não garante indexação, ranking ou tráfego.

## Secrets

Em **Settings → Secrets and variables → Actions**:

1. `SATELLITE_REPO_TOKEN` — token para criação/administração dos repositórios e Pages.
2. `INDEXNOW_KEY` — chave IndexNow.

Nunca coloque os valores desses secrets no código ou em commits.

## Importante sobre SEO

Os hubs usam texto editorial curto e contextual e apontam para a fonte original. Eles não copiam os artigos do AnaliseMelhor.

Links externos são marcados como `nofollow` para não transformar a automação em uma rede artificial de manipulação de PageRank.

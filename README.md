# Review Studio

Atue como um desenvolvedor expert e especialista em engenharia reversa de UI/UX. Preciso que você crie um clone funcional e visualmente idêntico ao portal de reviews: https://analisamelhor.com.br/

Siga rigorosamente estas diretrizes:

1. Clonagem de Layout e Estrutura:

   - Replique exato o design, cores, cabeçalho com menu de categorias, barra de pesquisa, a grade (grid) de produtos recomendados na Home, e a estrutura das páginas de artigos (com tabelas de Top 3, caixas de prós e contras, e seção de FAQ).

2. Sistema de Substituição de Links de Afiliados:

   - Configure o código de forma que qualquer URL de produto gerada receba obrigatoriamente a minha estrutura de parâmetros de afiliado.

   - Padrão de substituição: Onde houver tags de afiliados genéricas ou do concorrente, substitua automaticamente o final da URL de rastreamento para o meu padrão exato: `tag=shoptimego09-20&linkCode=as4&ref_=onb_gen_lnk&th=1`.

3. Organização de Dados:

   - Estruture os dados dos produtos e artigos em um arquivo centralizado (ex: `src/data/posts.ts`) para que eu possa gerenciar, alterar textos, trocar palavras-chave e atualizar os produtos facilmente.

This project was built with [Lovable](https://lovable.dev).

**Live app**: https://affiliate-copycat-pro.lovable.app

## Build with Lovable

Continue developing this project in the [Lovable editor](https://lovable.dev/projects/f6f9a91a-3814-46f8-986f-cc610861988d).

- **Ship faster**: describe what you want to build and Lovable handles the code.
- **Stay in sync**: every change made in Lovable is committed straight to this repository.
- **Full ownership**: this code is yours. Push to `main` on GitHub and your changes sync back into Lovable, ready for your next prompt.

## Development

Prefer working locally? You need Node.js and npm — [install with nvm](https://github.com/nvm-sh/nvm#installing-and-updating).

```sh
git clone <this-repository-url>
cd <repository-name>
npm i
npm run dev
```

import { createFileRoute, Link, notFound, redirect } from "@tanstack/react-router";
import { Check, ChevronRight, Clock3, ExternalLink, Info, Star, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ContentCard } from "@/components/content-card";
import { SafeImage } from "@/components/safe-image";
import { extractProducts, makeArticleIntro } from "@/lib/article-parser";
import { articleTitle, contentTitle } from "@/lib/content-title";
import { getPage } from "@/lib/pages.functions";

const SITE_URL = "https://analisemelhor.com.br";


export const Route = createFileRoute("/$")({
  staticData: { sitemap: true },
  loader: async ({ params }) => {
    const slug = params._splat;
    if (!slug) throw redirect({ to: "/" });
    const data = await getPage({ data: { slug } });
    if (!data) throw notFound();
    return data;
  },
  head: ({ params, loaderData }) => {
    const page = loaderData?.page;
    if (!page) return { meta: [{ title: "AnaliseMelhor" }] };
    const isCategory = page.slug === page.category_slug;
    const title = isCategory ? `${contentTitle(page.title)} — Guias de compra | AnaliseMelhor` : articleTitle(page.title);
    const description = page.description ?? "Compare produtos, características e opções de compra.";
    const url = `${SITE_URL}/${params._splat ?? page.slug}`;
    const image = page.image && /^https:\/\//.test(page.image) ? page.image : undefined;
    const ratedProducts = isCategory ? [] : extractProducts(page.html).filter((product) => product.rating);
    return {
      meta: [
        { title }, { name: "description", content: description },
        { property: "og:title", content: title }, { property: "og:description", content: description },
        { property: "og:type", content: isCategory ? "website" : "article" },
        { property: "og:url", content: url },
        { name: "twitter:card", content: "summary_large_image" },
        ...(image ? [{ property: "og:image", content: image }, { name: "twitter:image", content: image }] : []),
      ],
      links: [
        { rel: "canonical", href: url },
        ...(isCategory && loaderData?.related?.[0]?.image ? [{ rel: "preload", as: "image", href: loaderData.related[0].image, fetchPriority: "high" as const }] : []),
      ],
      scripts: [{
        type: "application/ld+json",
        children: JSON.stringify({
          "@context": "https://schema.org",
          "@graph": [
            isCategory
              ? { "@type": "CollectionPage", name: title, description, url, inLanguage: "pt-BR" }
              : {
                  "@type": "Article",
                  headline: title,
                  description,
                  url,
                  inLanguage: "pt-BR",
                  ...(image ? { image } : {}),
                  ...(page.published_at ? { datePublished: page.published_at } : {}),
                  articleSection: page.category_name ?? "Guias de compra",
                  mainEntityOfPage: { "@type": "WebPage", "@id": url },
                  author: { "@type": "Organization", name: "AnaliseMelhor", url: SITE_URL + "/sobre" },
                  publisher: { "@type": "Organization", name: "AnaliseMelhor", url: SITE_URL + "/" },
                 },
            ...ratedProducts.map((product) => ({
              "@type": "Product",
              name: product.name,
              ...(product.image ? { image: product.image } : {}),
              url,
              aggregateRating: {
                "@type": "AggregateRating",
                ratingValue: product.rating?.value,
                reviewCount: product.rating?.count,
                bestRating: 5,
                worstRating: 1,
              },
              ...(product.price ? {
                offers: {
                  "@type": "Offer",
                  url: product.url,
                  priceCurrency: "BRL",
                  price: product.price.replace(/[^\d,]/g, "").replace(",", "."),
                },
              } : {}),
            })),
            {
              "@type": "BreadcrumbList",
              itemListElement: [
                { "@type": "ListItem", position: 1, name: "Início", item: SITE_URL + "/" },
                ...(!isCategory && page.category_name && page.category_slug
                  ? [{ "@type": "ListItem", position: 2, name: page.category_name, item: `${SITE_URL}/${page.category_slug}` }]
                  : []),
                { "@type": "ListItem", position: !isCategory && page.category_name && page.category_slug ? 3 : 2, name: title, item: url },

              ],
            },
          ],
        }),
      }],
    };
  },

  component: DynamicPage,
});

function DynamicPage() {
  const { page, related } = Route.useLoaderData();
  const isCategory = page.slug === page.category_slug || !page.html.toLowerCase().includes("amazon.com.br");
  return isCategory ? <CategoryPage /> : <ArticlePage />;
}

function CategoryPage() {
  const { page, related } = Route.useLoaderData();
  const title = contentTitle(page.title);
  return <>
    <header className="bg-article-hero text-header-foreground"><div className="mx-auto max-w-7xl px-4 py-8 sm:py-12 lg:px-8"><nav className="text-sm text-header-muted"><Link to="/">Início</Link> / Categoria</nav><h1 className="mt-5 font-display text-3xl font-extrabold leading-tight sm:text-5xl">{title}</h1><p className="mt-4 max-w-2xl text-lg text-header-muted">Seleções e comparativos para encontrar opções que façam sentido para sua rotina.</p></div></header>
    <section className="mx-auto max-w-7xl px-4 py-8 sm:py-12 lg:px-8"><div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">{related.map((post, index) => <ContentCard key={post.slug} post={post} priority={index === 0} />)}</div></section>
  </>;
}

function ArticlePage() {
  const { page, related } = Route.useLoaderData();
  const products = extractProducts(page.html);
  const title = articleTitle(page.title);
  return <article>
    <header className="bg-article-hero text-header-foreground"><div className="mx-auto max-w-5xl px-4 py-8 sm:py-12 sm:py-16"><nav className="flex items-center gap-1.5 text-xs text-header-muted"><Link to="/">Início</Link><ChevronRight className="size-3"/><span>{page.category_name ?? "Comparativos"}</span></nav><span className="mt-8 inline-flex rounded-full bg-brand px-3 py-1 text-xs font-bold text-primary-foreground">{page.category_name ?? "Guia de compra"}</span><h1 className="mt-4 font-display text-3xl font-extrabold leading-tight sm:text-5xl">{title}</h1><p className="mt-4 max-w-3xl text-base leading-7 sm:mt-5 sm:text-lg sm:leading-8 text-header-muted">{page.description}</p><div className="mt-5 flex flex-wrap gap-x-4 gap-y-2 sm:mt-6 sm:gap-5 font-mono text-xs text-header-muted"><span>Por Equipe AnaliseMelhor</span>{page.published_at && <span>{page.published_at}</span>}{page.reading_time && <span className="flex items-center gap-1.5"><Clock3 className="size-3.5"/>{page.reading_time}</span>}</div></div></header>
    <div className="mx-auto max-w-5xl px-4 py-7 sm:py-10">
      <p className="max-w-4xl text-base leading-7 text-muted-foreground sm:text-lg sm:leading-8">{makeArticleIntro(page, products.length)}</p>
      {products.length > 0 && <section className="mt-6 rounded-lg border border-border bg-card p-4 sm:mt-8 sm:p-5" aria-labelledby="summary-title">
        <h2 id="summary-title" className="font-display text-2xl font-bold">Resumo das opções</h2>
        <p className="mt-3 leading-7 text-muted-foreground">Compare características, preço, limitações e compatibilidade com sua necessidade antes de escolher.</p>
        <ul className="mt-4 grid gap-3 sm:grid-cols-2">
          {products.slice(0, 6).map((product, index) => <li key={product.url} className="rounded-md border border-border p-3">
            <a href={"#produto-" + (index + 1)} className="font-semibold hover:text-brand">{product.name}</a>
            {product.facts.length > 0 && <p className="mt-1 text-sm leading-6 text-muted-foreground">{product.facts.slice(0, 2).join(" · ")}</p>}
          </li>)}
        </ul>
      </section>}
      <div className="mt-6 flex gap-3 border-l-4 border-brand bg-notice p-4 text-sm leading-6 text-notice-foreground"><Info className="mt-0.5 size-5 shrink-0"/><p><strong>Transparência:</strong> podemos receber comissão quando uma compra é feita por nossos links. Você não paga nada a mais por isso.</p></div>
      <section className="mt-8 rounded-lg border border-border bg-card p-4 sm:mt-10 sm:p-5" aria-labelledby="methodology-title"><h2 id="methodology-title" className="font-display text-2xl font-bold">Como analisamos as opções</h2><p className="mt-3 leading-7 text-muted-foreground">A seleção é organizada a partir das informações disponíveis para cada produto, como características, preço informado, pontos positivos e pontos de atenção. O objetivo é facilitar a comparação entre alternativas com perfis e faixas de preço diferentes.</p><ul className="mt-4 grid gap-2 text-sm text-muted-foreground sm:grid-cols-2"><li>• Características e especificações informadas</li><li>• Preço de referência no momento da publicação</li><li>• Pontos positivos e limitações identificados na seleção</li><li>• Adequação a diferentes perfis de uso</li></ul><p className="mt-4 text-sm leading-6 text-muted-foreground">As informações de preço, estoque e condições comerciais podem mudar. Quando uma informação depender da loja ou do fabricante, confirme os dados diretamente na página de compra.</p></section>
      {products.length > 0 && <section className="mt-12"><h2 className="font-display text-3xl font-bold">Comparação rápida</h2><div className="mt-4 overflow-x-auto rounded-md border border-border"><table className="w-full min-w-[680px] text-left text-sm"><thead className="bg-primary text-primary-foreground"><tr><th className="p-4">Posição</th><th className="p-4">Produto</th><th className="p-4">Preço informado</th><th className="p-4">Comprar</th></tr></thead><tbody>{products.slice(0, 5).map((product, index) => <tr key={product.url} className="border-t border-border"><td className="p-4 font-mono">{String(index + 1).padStart(2,"0")}</td><td className="p-4 font-bold">{product.name}</td><td className="p-4">{product.price ?? "Consulte na loja"}</td><td className="p-4"><Button asChild variant="amazon" size="sm"><a href={product.url} target="_blank" rel="sponsored noopener noreferrer">Ver preço <ExternalLink/></a></Button></td></tr>)}</tbody></table></div></section>}
      <div className="mt-10 space-y-7 sm:mt-14 sm:space-y-10">{products.map((product, index) => <section key={product.url} id={"produto-" + (index + 1)} className="scroll-mt-24 overflow-hidden rounded-lg border border-border bg-card shadow-step"><div className="bg-product-header px-5 py-5 text-header-foreground"><span className="text-xs font-bold uppercase text-brand-soft">#{index + 1} · {product.badge}</span><h2 className="mt-1 font-display text-2xl font-bold sm:text-3xl">{product.name}</h2>{product.rating && <div className="mt-3 flex flex-wrap items-center gap-2" aria-label={`${product.rating.value.toFixed(1)} de 5 estrelas em ${product.rating.count.toLocaleString("pt-BR")} avaliações na Amazon`}><span className="flex text-line" aria-hidden="true">{Array.from({ length: 5 }, (_, starIndex) => <Star key={starIndex} className="size-4 fill-current" />)}</span><strong className="text-sm">{product.rating.value.toFixed(1).replace(".", ",")}/5</strong><span className="text-sm text-header-muted">({product.rating.count.toLocaleString("pt-BR")} avaliações na {product.rating.source})</span></div>}</div><div className="grid gap-5 p-4 sm:gap-7 sm:p-5 sm:grid-cols-[240px_1fr]"><SafeImage src={product.image ?? undefined} alt={product.name} className="aspect-square w-full rounded-md bg-muted object-contain" loading="lazy"/><div><p className="leading-7 text-muted-foreground">{product.facts.length > 0 ? product.name + " aparece neste comparativo pelos critérios apresentados abaixo. " + product.facts.slice(0, 2).join(" ") + " Compare essas características com o que você precisa antes de comprar." : "Esta opção foi incluída no comparativo de " + title.toLowerCase() + ". Consulte as características disponíveis, compare com as demais alternativas e confirme as condições atuais na loja."}</p><div className="mt-5 flex flex-col items-stretch gap-3 bg-muted p-4 sm:flex-row sm:items-center sm:justify-between sm:gap-4"><div><span className="block text-xs text-muted-foreground">Preço informado</span><strong className="text-xl">{product.price ?? "Consulte na Amazon"}</strong></div><Button asChild variant="amazon" size="xl" className="w-full sm:w-auto"><a href={product.url} target="_blank" rel="sponsored noopener noreferrer">Ver na Amazon <ExternalLink/></a></Button></div></div></div><div className="grid gap-3 border-t border-border p-4 sm:gap-4 sm:p-5 sm:grid-cols-2"><div className="border border-success-border bg-success-soft p-4"><h3 className="flex items-center gap-2 font-bold text-success-foreground"><Check className="size-5"/> Pontos para considerar</h3><ul className="mt-3 space-y-2 text-sm">{(product.facts.length ? product.facts : ["Alternativa incluída no comparativo", "Informações de compra acessíveis na loja"]).map((fact) => <li key={fact}>• {fact}</li>)}</ul></div><div className="border border-danger-border bg-danger-soft p-4"><h3 className="flex items-center gap-2 font-bold text-danger-foreground"><X className="size-5"/> Antes de comprar</h3><ul className="mt-3 space-y-2 text-sm"><li>• Confirme medidas e compatibilidade</li><li>• Preço e disponibilidade podem mudar</li></ul></div></div></section>)}</div>
      {page.slug === "melhor-mouse" && <section className="mt-10 rounded-lg border border-border bg-card p-4 sm:mt-12 sm:p-6" aria-labelledby="analysis-link-title">
        <span className="text-xs font-bold uppercase text-brand">Análise individual</span>
        <h2 id="analysis-link-title" className="mt-2 font-display text-2xl font-bold">Quer ver uma análise mais detalhada?</h2>
        <p className="mt-3 leading-7 text-muted-foreground">O Logitech MX Master 4 aparece neste comparativo. Criamos uma página individual com as características disponíveis, perfil de uso e pontos de atenção antes da compra.</p>
        <Link to="/review-logitech-mx-master-4" className="mt-4 inline-flex font-semibold text-brand underline underline-offset-4">Ler análise do Logitech MX Master 4 <ExternalLink className="ml-1 size-4"/></Link>
      </section>}
      <section className="mt-10 sm:mt-14"><h2 className="font-display text-3xl font-bold">Perguntas comuns sobre {title.toLowerCase()}</h2><div className="mt-5 border border-border bg-card px-5">{[
        [`O que considerar ao escolher ${title.toLowerCase()}?`, "Compare primeiro as características que realmente afetam seu uso, depois observe preço, compatibilidade, dimensões e limitações de cada alternativa."],
        ["Como comparar os produtos desta lista?", "Use a tabela e os pontos apresentados em cada produto para identificar diferenças de características, preço informado e perfil de uso. O modelo mais adequado depende das suas prioridades."],
        ["Os preços estão sempre atualizados?", "Os valores podem mudar a qualquer momento. O preço válido é o exibido pela loja ao abrir o link, junto com estoque e condições comerciais."],
        ["Os produtos foram testados pela AnaliseMelhor?", "A página organiza as informações disponíveis para comparação. Não atribuímos testes práticos ou experiências de uso que não tenham sido realizados e documentados."],
        ["O link altera o preço da compra?", "Não. O link identifica a indicação e pode gerar comissão para o site, sem acrescentar custo ao comprador."],
      ].map(([question, answer]) => <details key={question} className="group border-b border-border last:border-0"><summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-5 font-semibold">{question}<ChevronRight className="size-5 transition-transform group-open:rotate-90"/></summary><p className="pb-5 leading-7 text-muted-foreground">{answer}</p></details>)} </div></section>
      {related.length > 0 && <section className="mt-12 sm:mt-16"><h2 className="font-display text-3xl font-bold">Outros guias da categoria</h2><div className="mt-6 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">{related.slice(0,3).map((post) => <ContentCard key={post.slug} post={post}/>)}</div></section>}
    </div>
  </article>;
}
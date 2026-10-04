import { createFileRoute, Link } from "@tanstack/react-router";
import { SafeImage } from "@/components/safe-image";
import { ArrowRight, CheckCircle2, Search, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ContentCard } from "@/components/content-card";
import { articleTitle } from "@/lib/content-title";
import { getHomeData } from "@/lib/pages.functions";

const SITE_URL = "https://analisemelhor.com.br";


export const Route = createFileRoute("/")({
  staticData: { sitemap: true },
  loader: () => getHomeData(),
  head: ({ loaderData }) => ({ meta: [
    { title: "AnaliseMelhor — Compare produtos sem complicação" },
    { name: "description", content: "Guias de compra objetivos, produtos comparados e informações práticas para escolher melhor." },
    { property: "og:title", content: "AnaliseMelhor — Compare produtos sem complicação" },
    { property: "og:description", content: "Comparativos objetivos e recomendações práticas para sua próxima compra." },
    { property: "og:type", content: "website" },
    { property: "og:url", content: SITE_URL + "/" },
    { name: "twitter:card", content: "summary_large_image" },
  ],
  links: [
    { rel: "canonical", href: SITE_URL + "/" },
    ...(loaderData?.posts?.[0]?.image ? [{ rel: "preload", as: "image", href: loaderData.posts[0].image, fetchPriority: "high" as const }] : []),
  ],
  scripts: [{
    type: "application/ld+json",
    children: JSON.stringify({
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: "AnaliseMelhor",
      url: SITE_URL + "/",
      inLanguage: "pt-BR",
      publisher: { "@type": "Organization", name: "AnaliseMelhor", url: SITE_URL + "/" },
    }),
  }] }),

  component: Index,
});

function Index() {
  const { posts, categories } = Route.useLoaderData();
  const leadPost = posts[0];
  if (!leadPost) return null;
  return (
    <>
      <section className="bg-hero text-header-foreground">
        <div className="mx-auto grid max-w-7xl items-center gap-6 px-4 py-8 sm:gap-8 sm:py-10 md:grid-cols-[1.02fr_.98fr] md:py-16 lg:px-8">
          <div className="max-w-2xl">
            <span className="inline-flex items-center gap-2 rounded-full border border-header-border bg-header-surface px-3 py-1.5 text-xs font-semibold text-brand-soft"><Sparkles className="size-3.5"/> Informação clara para decisões reais.</span>
            <h1 className="mt-6 font-display text-[2rem] font-extrabold leading-[1.08] sm:text-5xl lg:text-6xl">Compare com calma. <span className="text-brand-soft">Escolha com certeza.</span></h1>
            <p className="mt-4 max-w-xl text-base leading-7 sm:mt-5 sm:text-lg sm:leading-8 text-header-muted">Reunimos os dados que importam para você encontrar o produto certo para sua rotina e seu orçamento.</p>
            <div className="mt-6 flex flex-col gap-2.5 sm:mt-7 sm:flex-row sm:flex-wrap sm:gap-3"><Button asChild variant="brand" size="xl" className="w-full sm:w-auto"><Link to="/$" params={{ _splat: leadPost.slug }}>Ver guia em destaque <ArrowRight /></Link></Button><Button asChild variant="header" size="xl" className="w-full sm:w-auto"><a href="#guias"><Search/> Explorar guias</a></Button></div>
            <div className="mt-6 flex flex-wrap gap-x-4 gap-y-2 sm:mt-8 text-xs text-header-muted"><span className="flex items-center gap-1.5"><CheckCircle2 className="size-4 text-success"/> Seleção independente</span><span className="flex items-center gap-1.5"><CheckCircle2 className="size-4 text-brand-soft"/> Comparação objetiva</span></div>
          </div>
          <Link to="/$" params={{ _splat: leadPost.slug }} className="group block overflow-hidden rounded-lg border border-header-border bg-header-surface p-3 shadow-hero">
            <div className="flex aspect-[16/10] items-center justify-center overflow-hidden rounded-md bg-card p-4 sm:p-5 sm:p-8">
              <SafeImage src={leadPost.image ?? undefined} alt={articleTitle(leadPost.title)} width={1600} height={900} loading="eager" fetchPriority="high" decoding="async" className="h-full w-full object-contain p-4 transition-transform duration-500 group-hover:scale-[1.04]"/>
            </div>
            <div className="px-1 pb-1 pt-4">
              <span className="block text-xs font-bold uppercase text-brand-soft">Guia em destaque</span>
              <span className="mt-1 line-clamp-2 block font-display font-bold text-header-foreground">{articleTitle(leadPost.title)}</span>
              <span className="mt-2 inline-flex items-center gap-1 text-sm font-semibold text-header-muted">Ler guia completo <ArrowRight className="size-4" /></span>
            </div>
          </Link>
        </div>
      </section>

      <section className="border-b-4 border-line bg-card"><div className="mx-auto flex max-w-7xl gap-6 overflow-x-auto px-4 py-4 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden sm:gap-8 sm:py-5 lg:px-8">{categories.map((category) => <Link key={category.slug} to="/$" params={{ _splat: category.slug }} className="flex shrink-0 items-center gap-2 text-sm font-semibold text-muted-foreground hover:text-foreground"><span className="category-dot bg-brand"/>{category.name}<small className="font-mono">{category.count}</small></Link>)}</div></section>

      <section id="guias" className="mx-auto max-w-7xl px-4 py-10 sm:py-16 lg:px-8">
        <div className="flex items-end justify-between gap-6"><div><span className="text-xs font-bold uppercase text-brand">Recomendações recentes</span><h2 className="mt-2 font-display text-3xl font-bold sm:text-4xl">Guias para decidir melhor</h2></div><span className="hidden text-sm text-muted-foreground sm:block">Análises práticas, sem enrolação.</span></div>
        <div className="mt-6 grid gap-4 sm:mt-8 sm:gap-6 sm:grid-cols-2 lg:grid-cols-3">{posts.map((post) => <ContentCard key={post.slug} post={post} />)}</div>
      </section>

      <section className="bg-muted"><div className="mx-auto max-w-7xl px-4 py-10 sm:py-14 lg:px-8"><h2 className="font-display text-3xl font-bold">Nosso jeito de comparar</h2><div className="mt-5 grid gap-3 sm:mt-7 sm:gap-4 sm:grid-cols-3">{["Dados essenciais", "Opções para perfis diferentes", "Preço conferido na loja"].map((item, index) => <div key={item} className="border-l-4 border-brand bg-card p-5"><span className="font-mono text-xs font-bold text-brand">0{index + 1}</span><strong className="mt-3 block">{item}</strong></div>)}</div><div className="mt-6 rounded-lg border border-border bg-card p-4 sm:mt-8 sm:p-6"><h3 className="font-display text-xl font-bold">Como usar o AnaliseMelhor</h3><p className="mt-3 max-w-3xl leading-7 text-muted-foreground">Pesquise um produto ou escolha uma categoria, leia o guia e compare as informações apresentadas. Quando quiser conferir uma oferta, use o link indicado para abrir a loja e verificar preço, estoque e condições atualizadas.</p><div className="mt-5 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:gap-4 text-sm font-semibold"><a href="/sobre" className="text-brand underline underline-offset-4">Sobre Nós</a><a href="/contato" className="text-brand underline underline-offset-4">Formulário de contato</a><a href="/privacidade" className="text-brand underline underline-offset-4">Política de Privacidade</a></div></div></div></section>
    </>
  );
}

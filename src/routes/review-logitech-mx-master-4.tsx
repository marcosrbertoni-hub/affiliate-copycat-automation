import { createFileRoute, Link } from "@tanstack/react-router";
import { ArrowLeft, ExternalLink } from "lucide-react";
import { Button } from "@/components/ui/button";
import reviewHero from "@/assets/review-hero.jpg";

const SITE_URL = "https://analisemelhor.com.br";
const AMAZON_URL = "https://www.amazon.com.br/dp/B0FPM2VC6Q?linkCode=as4&ref_=onb_gen_lnk&tag=shoptimego09-20&th=1";

export const Route = createFileRoute("/review-logitech-mx-master-4")({
  staticData: { sitemap: true },
  head: () => ({
    meta: [
      { title: "Logitech MX Master 4: análise, recursos e preço no Brasil em 2026" },
      {
        name: "description",
        content:
          "Análise do Logitech MX Master 4 com características, pontos de atenção, preço de referência e perfil de uso.",
      },
      { property: "og:title", content: "Logitech MX Master 4: análise, recursos e preço no Brasil em 2026" },
      {
        property: "og:description",
        content:
          "Veja as características do Logitech MX Master 4, para quem ele faz sentido e o que conferir antes da compra.",
      },
      { property: "og:type", content: "article" },
      { property: "og:url", content: SITE_URL + "/review-logitech-mx-master-4" },
      { property: "og:image", content: SITE_URL + "/review-hero.jpg" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
    links: [{ rel: "canonical", href: SITE_URL + "/review-logitech-mx-master-4" }],
    scripts: [
      {
        type: "application/ld+json",
        children: JSON.stringify({
          "@context": "https://schema.org",
          "@type": "Article",
          headline: "Logitech MX Master 4: análise, recursos e preço no Brasil em 2026",
          description:
            "Análise informativa do Logitech MX Master 4 baseada nas características disponíveis para comparação.",
          url: SITE_URL + "/review-logitech-mx-master-4",
          image: SITE_URL + "/review-hero.jpg",
          inLanguage: "pt-BR",
          author: { "@type": "Organization", name: "AnaliseMelhor", url: SITE_URL + "/sobre" },
          publisher: { "@type": "Organization", name: "AnaliseMelhor", url: SITE_URL },
          mainEntityOfPage: { "@type": "WebPage", "@id": SITE_URL + "/review-logitech-mx-master-4" },
        }),
      },
    ],
  }),
  component: ReviewPage,
});

function ReviewPage() {
  return (
    <article>
      <header className="bg-article-hero text-header-foreground">
        <div className="mx-auto max-w-5xl px-4 py-8 sm:py-12 lg:py-16">
          <nav className="text-sm text-header-muted">
            <Link to="/">Início</Link> /{" "}
            <Link to="/$" params={{ _splat: "melhor-mouse" }}>Melhor mouse</Link> / Análise
          </nav>
          <span className="mt-8 inline-flex rounded-full bg-brand px-3 py-1 text-xs font-bold text-primary-foreground">
            Análise de produto
          </span>
          <h1 className="mt-4 font-display text-3xl font-extrabold leading-tight sm:text-5xl">
            Logitech MX Master 4: análise, recursos e preço no Brasil em 2026
          </h1>
          <p className="mt-4 max-w-3xl text-base leading-7 sm:mt-5 sm:text-lg sm:leading-8 text-header-muted">
            Uma análise individual para quem encontrou o MX Master 4 no nosso comparativo de mouses e quer entender melhor suas características antes de comprar.
          </p>
        </div>
      </header>

      <div className="mx-auto max-w-5xl px-4 py-7 sm:py-10">
        <div className="grid gap-8 lg:grid-cols-[1fr_280px]">
          <div>
            <p className="text-base leading-7 text-muted-foreground sm:text-lg sm:leading-8">
              O Logitech MX Master 4 aparece no comparativo de mouses do AnaliseMelhor com recursos voltados à produtividade, incluindo feedback tátil, design ergonômico, rolagem rápida e conexão por USB-C ou Bluetooth. Esta página organiza esses dados em uma análise para facilitar a decisão.
            </p>

            <section className="mt-8 sm:mt-10">
              <h2 className="font-display text-3xl font-bold">Principais características</h2>
              <ul className="mt-5 grid gap-3 sm:grid-cols-2">
                <li className="rounded-lg border border-border bg-card p-4">Feedback tátil Haptic</li>
                <li className="rounded-lg border border-border bg-card p-4">Design ergonômico</li>
                <li className="rounded-lg border border-border bg-card p-4">Rolagem ultrarrápida</li>
                <li className="rounded-lg border border-border bg-card p-4">USB-C ou Bluetooth</li>
                <li className="rounded-lg border border-border bg-card p-4">Compatibilidade com Windows e macOS</li>
              </ul>
            </section>

            <section className="mt-10">
              <h2 className="font-display text-3xl font-bold">Para quem faz sentido</h2>
              <p className="mt-4 leading-7 text-muted-foreground">
                Pelas características listadas no comparativo, o perfil do produto é mais alinhado a quem prioriza produtividade, conforto e conectividade em diferentes dispositivos. Para jogos competitivos, vale comparar também peso, formato, sensor e recursos específicos de modelos gamer.
              </p>
            </section>

            <section className="mt-10">
              <h2 className="font-display text-3xl font-bold">O que conferir antes de comprar</h2>
              <ul className="mt-4 space-y-3 text-muted-foreground">
                <li>• Confirme compatibilidade com seu sistema e fluxo de trabalho.</li>
                <li>• Confira dimensões, ergonomia e peso na ficha atualizada.</li>
                <li>• Verifique preço, estoque, garantia e condições de entrega.</li>
                <li>• Compare com outros modelos do nosso <Link to="/$" params={{ _splat: "melhor-mouse" }} className="font-semibold text-brand underline underline-offset-4">comparativo de melhores mouses</Link>.</li>
              </ul>
            </section>

            <section className="mt-10 rounded-lg border border-border bg-muted p-4 sm:p-6">
              <h2 className="font-display text-2xl font-bold">Transparência da análise</h2>
              <p className="mt-3 leading-7 text-muted-foreground">
                Esta é uma análise informativa baseada nas características disponíveis para comparação. Não apresentamos como teste próprio qualquer experiência prática que não tenha sido realizada e documentada. Preços e condições podem mudar na loja.
              </p>
            </section>

            <div className="mt-8 flex flex-col gap-3 sm:mt-10 sm:flex-row sm:flex-wrap">
              <Button asChild variant="amazon" size="xl" className="w-full sm:w-auto">
                <a href={AMAZON_URL} target="_blank" rel="sponsored noopener noreferrer">
                  Ver preço na Amazon <ExternalLink />
                </a>
              </Button>
              <Button asChild variant="outline" size="xl" className="w-full sm:w-auto">
                <Link to="/$" params={{ _splat: "melhor-mouse" }}>
                  <ArrowLeft /> Voltar ao comparativo
                </Link>
              </Button>
            </div>
          </div>

          <aside className="h-fit overflow-hidden rounded-lg border border-border bg-card">
            <img src={reviewHero} alt="Análise do Logitech MX Master 4 no AnaliseMelhor" className="aspect-[4/3] w-full object-cover" />
            <div className="p-5">
              <span className="text-xs font-bold uppercase text-brand">Preço de referência</span>
              <p className="mt-2 font-display text-2xl font-bold">R$ 799,88</p>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                Valor observado no comparativo; confirme o preço atual antes da compra.
              </p>
            </div>
          </aside>
        </div>
      </div>
    </article>
  );
}

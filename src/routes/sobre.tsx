import { createFileRoute, Link } from "@tanstack/react-router";
import { InstitutionalPage } from "@/components/institutional-page";

const PAGE_URL = "https://analisemelhor.com.br/sobre";

export const Route = createFileRoute("/sobre")({
  staticData: { sitemap: true },
  head: () => ({ meta: [
    { title: "Sobre Nós — AnaliseMelhor" },
    { name: "description", content: "Conheça o AnaliseMelhor, nosso compromisso editorial e como produzimos comparativos de produtos." },
    { property: "og:title", content: "Sobre Nós — AnaliseMelhor" },
    { property: "og:description", content: "Conheça nosso compromisso com comparativos claros, úteis e transparentes." },
    { property: "og:type", content: "website" },
    { property: "og:url", content: PAGE_URL },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: [{ rel: "canonical", href: PAGE_URL }], scripts: [{ type: "application/ld+json", children: JSON.stringify({ "@context": "https://schema.org", "@type": "ProfilePage", mainEntity: { "@type": "Person", name: "Marcos Roberto Krauswscki Filho", url: PAGE_URL } }) }] }),
  component: AboutPage,
});

function AboutPage() {
  return (
    <InstitutionalPage eyebrow="Sobre Nós" title="Informação clara para escolhas mais seguras" description="O AnaliseMelhor organiza dados de produtos e opções de compra para facilitar sua pesquisa.">
      <section><h2>Quem somos</h2><p className="mt-3">O AnaliseMelhor é um portal independente de conteúdo e comparação de produtos, sob responsabilidade de <strong>Marcos Roberto Krauswscki Filho</strong>. Nosso objetivo é reunir informações úteis em uma linguagem direta, para que cada pessoa possa comparar alternativas antes de comprar.</p></section>
      <section><h2>Como produzimos nossos guias</h2><p className="mt-3">Organizamos características, especificações, faixas de preço e informações públicas disponibilizadas por fabricantes e lojas. As recomendações têm caráter informativo e devem ser avaliadas de acordo com as necessidades, o orçamento e as preferências de cada leitor.</p></section>
      <section><h2>Como usar o AnaliseMelhor</h2><p className="mt-3">Escolha uma categoria ou pesquise pelo produto que deseja conhecer. Abra um guia para consultar características, critérios de comparação e informações úteis. Quando houver uma opção de compra, o botão indicado leva você ao site da loja para conferir preço, estoque e condições atualizadas.</p><ol className="mt-4 list-decimal space-y-2 pl-5"><li>Pesquise por uma categoria ou produto.</li><li>Leia o guia e compare as informações apresentadas.</li><li>Acesse a loja pelo link indicado se quiser verificar a oferta.</li></ol></section>
      <section><h2>Transparência e sistema de afiliados</h2><p className="mt-3">Participamos do programa de afiliados da Amazon. Alguns links deste site são links de afiliado: quando uma compra elegível é realizada por meio deles, podemos receber uma comissão. <strong>O preço pago pelo comprador não aumenta por causa disso.</strong></p></section>
      <section><h2>O que oferecemos</h2><p className="mt-3">O site oferece guias, comparativos e seleções de produtos organizados por categoria. O conteúdo serve como apoio à pesquisa: preços, disponibilidade e condições de compra devem ser confirmados na loja antes da decisão.</p></section>
      <section><h2>Independência editorial</h2><p className="mt-3">A possibilidade de comissão não garante posição, avaliação positiva ou inclusão de um produto. Preços, estoque, entrega e condições comerciais são definidos pela loja e podem mudar sem aviso.</p></section>
      <p>Para dúvidas, correções ou sugestões, visite a página de <Link to="/contato">Contato</Link>.</p>
    </InstitutionalPage>
  );
}
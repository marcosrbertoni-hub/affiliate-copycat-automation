import { createFileRoute, Link } from "@tanstack/react-router";
import { InstitutionalPage } from "@/components/institutional-page";

const PAGE_URL = "https://analisemelhor.com.br/termos";

export const Route = createFileRoute("/termos")({
  staticData: { sitemap: true },
  head: () => ({ meta: [
    { title: "Termos de Uso — AnaliseMelhor" },
    { name: "description", content: "Consulte as condições de uso, aviso de afiliados e responsabilidades aplicáveis ao AnaliseMelhor." },
    { property: "og:title", content: "Termos de Uso — AnaliseMelhor" },
    { property: "og:description", content: "Condições de uso, transparência de afiliados e responsabilidades do AnaliseMelhor." },
    { property: "og:type", content: "website" },
    { property: "og:url", content: PAGE_URL },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: [{ rel: "canonical", href: PAGE_URL }] }),
  component: TermsPage,
});

function TermsPage() {
  return (
    <InstitutionalPage eyebrow="Termos de Uso" title="Termos e condições de uso" description="Ao acessar o AnaliseMelhor, você concorda com as condições abaixo.">
      <section><h2>Finalidade do conteúdo</h2><p className="mt-3">O AnaliseMelhor, sob responsabilidade de <strong>Marcos Roberto Krauswscki Filho</strong>, oferece conteúdo informativo para auxiliar pesquisas e comparações. As informações não substituem orientação profissional nem representam garantia de adequação de um produto a uma necessidade específica.</p></section>
      <section><h2>Preços e disponibilidade</h2><p className="mt-3">Preços, estoque, prazo, frete, garantia e demais condições podem mudar sem aviso. Antes de comprar, confira todas as informações diretamente na página da loja. Em caso de diferença, prevalecem as condições apresentadas pela loja no momento da compra.</p></section>
      <section><h2>Programa de afiliados</h2><p className="mt-3">O AnaliseMelhor participa do programa de afiliados da Amazon. Podemos receber comissão por compras elegíveis feitas após o acesso a determinados links, sem custo adicional para o comprador. A compra, o pagamento, a entrega, a troca e o atendimento são realizados pela loja.</p></section>
      <section><h2>Uso do site</h2><ul className="mt-3"><li>Use o conteúdo de forma lícita e respeite direitos de terceiros.</li><li>Não tente comprometer a segurança, disponibilidade ou funcionamento do site.</li><li>Não reproduza integralmente textos, identidade ou materiais próprios sem autorização.</li></ul></section>
      <section><h2>Links de terceiros</h2><p className="mt-3">Não controlamos páginas, políticas ou serviços externos. O acesso a links de terceiros é uma decisão do visitante e fica sujeito aos termos e às políticas do destino.</p></section>
      <section><h2>Limitação de responsabilidade</h2><p className="mt-3">Empregamos cuidado na organização das informações, mas não garantimos ausência total de erros ou disponibilidade contínua. Na extensão permitida por lei, não nos responsabilizamos por decisões de compra, alterações feitas pelas lojas ou danos decorrentes de serviços de terceiros.</p></section>
      <section><h2>Alterações e contato</h2><p className="mt-3">Estes termos podem ser atualizados a qualquer momento. Última atualização: 19 de setembro de 2026. Em caso de dúvida, use a página de <Link to="/contato">Contato</Link>.</p></section>
    </InstitutionalPage>
  );
}
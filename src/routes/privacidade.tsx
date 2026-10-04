import { createFileRoute, Link } from "@tanstack/react-router";
import { InstitutionalPage } from "@/components/institutional-page";

const PAGE_URL = "https://analisemelhor.com.br/privacidade";

export const Route = createFileRoute("/privacidade")({
  staticData: { sitemap: true },
  head: () => ({ meta: [
    { title: "Política de Privacidade — AnaliseMelhor" },
    { name: "description", content: "Saiba como o AnaliseMelhor trata dados enviados, cookies, links externos e solicitações de privacidade." },
    { property: "og:title", content: "Política de Privacidade — AnaliseMelhor" },
    { property: "og:description", content: "Informações sobre dados, cookies, links externos e seus direitos no AnaliseMelhor." },
    { property: "og:type", content: "website" },
    { property: "og:url", content: PAGE_URL },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: [{ rel: "canonical", href: PAGE_URL }] }),
  component: PrivacyPage,
});

function PrivacyPage() {
  return (
    <InstitutionalPage eyebrow="Privacidade" title="Política de Privacidade" description="Esta política explica, de forma simples, quais informações podem ser tratadas ao usar o AnaliseMelhor.">
      <section><h2>Responsável</h2><p className="mt-3">O responsável pelo AnaliseMelhor e pelo tratamento das informações descritas nesta política é <strong>Marcos Roberto Krauswscki Filho</strong>. O contato para assuntos de privacidade é <a href="mailto:guiasincero@gmail.com">guiasincero@gmail.com</a>.</p></section>
      <section><h2>Dados fornecidos por você</h2><p className="mt-3">Ao usar o formulário de contato, você pode informar nome, endereço de e-mail, assunto e mensagem. Esses dados são usados para responder à solicitação e manter o histórico necessário do atendimento. Não vendemos essas informações.</p></section>
      <section><h2>Dados técnicos e cookies</h2><p className="mt-3">O site pode usar cookies e registros técnicos necessários para funcionamento, segurança, desempenho e medição de acesso. Utilizamos o Google Analytics 4 para medir acessos e entender como o site é utilizado. A medição não essencial fica desativada até que você aceite no aviso de cookies. Você pode recusar ou alterar as permissões disponíveis no navegador.</p><p className="mt-3">O Google pode tratar dados de acordo com sua própria política de privacidade. Para mais informações, consulte a <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer">Política de Privacidade do Google</a>.</p></section>
      <section><h2>Publicidade</h2><p className="mt-3">O site utiliza o Google AdSense para publicidade. O Google e outros fornecedores de publicidade podem usar cookies, beacons e tecnologias semelhantes para veicular, medir e, quando permitido, personalizar anúncios com base nas visitas ao site e a outros sites. A utilização de cookies e o tratamento de dados para publicidade estão sujeitos às configurações de consentimento aplicáveis e às políticas do Google.</p><p className="mt-3">Você pode consultar ou alterar as preferências de publicidade nas <a href="https://adssettings.google.com/" target="_blank" rel="noopener noreferrer">Configurações de anúncios do Google</a> e obter informações sobre publicidade personalizada em <a href="https://www.aboutads.info/" target="_blank" rel="noopener noreferrer">aboutads.info</a>.</p></section>
      <section><h2>Links externos e afiliados</h2><p className="mt-3">Ao abrir um link de produto, você será direcionado para um site externo, como a Amazon. O tratamento de dados nessa loja segue as políticas do próprio serviço. Os links podem conter identificadores de afiliado que permitem atribuir uma compra ao AnaliseMelhor.</p></section>
      <section><h2>Conservação e proteção</h2><p className="mt-3">As informações são conservadas somente pelo período necessário ao atendimento, ao cumprimento de obrigações legais e à proteção de direitos. Adotamos medidas razoáveis para reduzir acessos, alterações ou divulgações indevidas.</p></section>
      <section><h2>Seus direitos</h2><p className="mt-3">Você pode solicitar confirmação de tratamento, acesso, correção ou exclusão de dados, quando aplicável. Envie o pedido pela página de <Link to="/contato">Contato</Link>. Poderemos solicitar informações adicionais para confirmar a identidade do solicitante.</p></section>
      <section><h2>Atualizações</h2><p className="mt-3">Esta política pode ser atualizada para refletir mudanças no site ou na legislação. Última atualização: 29 de setembro de 2026.</p></section>
    </InstitutionalPage>
  );
}
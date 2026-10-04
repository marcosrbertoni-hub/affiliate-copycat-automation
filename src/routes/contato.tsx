import { createFileRoute } from "@tanstack/react-router";
import { useServerFn } from "@tanstack/react-start";
import { FormEvent, useState } from "react";
import { Mail, Send } from "lucide-react";
import { InstitutionalPage } from "@/components/institutional-page";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { contactSchema, prepareContactEmail, type ContactInput } from "@/lib/contact.functions";

const PAGE_URL = "https://analisemelhor.com.br/contato";

export const Route = createFileRoute("/contato")({
  staticData: { sitemap: true },
  head: () => ({ meta: [
    { title: "Contato — AnaliseMelhor" },
    { name: "description", content: "Entre em contato com o AnaliseMelhor pelo formulário de contato para enviar dúvidas, sugestões, correções ou assuntos comerciais." },
    { property: "og:title", content: "Contato — AnaliseMelhor" },
    { property: "og:description", content: "Envie dúvidas, sugestões, correções ou assuntos comerciais ao AnaliseMelhor." },
    { property: "og:type", content: "website" },
    { property: "og:url", content: PAGE_URL },
    { name: "twitter:card", content: "summary_large_image" },
  ], links: [{ rel: "canonical", href: PAGE_URL }] }),
  component: ContactPage,
});

const emptyForm: ContactInput = { name: "", email: "", subject: "", message: "" };

function ContactPage() {
  const prepareEmail = useServerFn(prepareContactEmail);
  const [form, setForm] = useState<ContactInput>(emptyForm);
  const [errors, setErrors] = useState<Partial<Record<keyof ContactInput, string>>>({});
  const [status, setStatus] = useState<"idle" | "sending" | "ready" | "error">("idle");

  const update = (field: keyof ContactInput, value: string) => setForm((current) => ({ ...current, [field]: value }));

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const result = contactSchema.safeParse(form);
    if (!result.success) {
      const nextErrors: Partial<Record<keyof ContactInput, string>> = {};
      for (const issue of result.error.issues) {
        const field = issue.path[0] as keyof ContactInput | undefined;
        if (field && !nextErrors[field]) nextErrors[field] = issue.message;
      }
      setErrors(nextErrors);
      return;
    }
    setErrors({});
    setStatus("sending");
    try {
      const response = await prepareEmail({ data: result.data });
      setStatus("ready");
      window.location.href = response.mailtoUrl;
    } catch {
      setStatus("error");
    }
  }

  return (
    <InstitutionalPage eyebrow="Contato" title="Fale com o AnaliseMelhor" description="Envie sua dúvida, correção, sugestão ou proposta. A mensagem será preparada para o nosso e-mail.">
      <section aria-labelledby="contact-email" className="border-l-4 border-line bg-notice p-5 text-notice-foreground">
        <p id="contact-email" className="flex items-center gap-2 font-semibold"><Mail className="size-5" /> E-mail direto</p>
        <a href="mailto:guiasincero@gmail.com">guiasincero@gmail.com</a>
      </section>
      <section aria-labelledby="contact-form-title" className="space-y-3">
        <h2 id="contact-form-title" className="text-xl font-bold text-foreground">Formulário de contato</h2>
        <p className="text-sm leading-6 text-muted-foreground">Preencha os campos abaixo para preparar uma mensagem para a equipe do AnaliseMelhor.</p>
      <form onSubmit={submit} aria-label="Formulário de contato do AnaliseMelhor"
        className="space-y-5 rounded-lg border border-border bg-card p-5 shadow-step sm:p-7" noValidate>
        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="Nome" id="name" error={errors.name}>
            <Input id="name" name="name" autoComplete="name" value={form.name} onChange={(event) => update("name", event.target.value)} maxLength={100} aria-invalid={Boolean(errors.name)} required />
          </Field>
          <Field label="E-mail" id="email" error={errors.email}>
            <Input id="email" name="email" type="email" autoComplete="email" value={form.email} onChange={(event) => update("email", event.target.value)} maxLength={255} aria-invalid={Boolean(errors.email)} required />
          </Field>
        </div>
        <Field label="Assunto" id="subject" error={errors.subject}>
          <Input id="subject" name="subject" value={form.subject} onChange={(event) => update("subject", event.target.value)} maxLength={120} aria-invalid={Boolean(errors.subject)} required />
        </Field>
        <Field label="Mensagem" id="message" error={errors.message}>
          <Textarea id="message" name="message" className="min-h-40 resize-y" value={form.message} onChange={(event) => update("message", event.target.value)} maxLength={2000} aria-invalid={Boolean(errors.message)} required />
        </Field>
        <p className="text-xs leading-5">Ao enviar, você concorda com o tratamento dos dados para resposta, conforme nossa <a href="/privacidade">Política de Privacidade</a>.</p>
        <Button type="submit" variant="brand" size="xl" disabled={status === "sending"}>
          <Send /> {status === "sending" ? "Preparando..." : "Enviar mensagem"}
        </Button>
        {status === "ready" && <p role="status" className="text-sm font-semibold text-success-foreground">Mensagem preparada. Revise e envie no seu aplicativo de e-mail.</p>}
        {status === "error" && <p role="alert" className="text-sm font-semibold text-danger-foreground">Não foi possível preparar a mensagem. Escreva diretamente para guiasincero@gmail.com.</p>}
      </form>
      </section>
    </InstitutionalPage>
  );
}

function Field({ label, id, error, children }: { label: string; id: string; error: string | undefined; children: React.ReactNode }) {
  return <div className="space-y-2"><Label htmlFor={id}>{label}</Label>{children}{error && <p className="text-sm text-danger-foreground" role="alert">{error}</p>}</div>;
}
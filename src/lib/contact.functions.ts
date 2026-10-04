import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

export const contactSchema = z.object({
  name: z.string().trim().min(2, "Informe seu nome.").max(100, "Use no máximo 100 caracteres."),
  email: z.string().trim().email("Informe um e-mail válido.").max(255, "Use no máximo 255 caracteres."),
  subject: z.string().trim().min(3, "Informe o assunto.").max(120, "Use no máximo 120 caracteres."),
  message: z.string().trim().min(10, "Escreva uma mensagem com pelo menos 10 caracteres.").max(2000, "Use no máximo 2.000 caracteres."),
});

export type ContactInput = z.infer<typeof contactSchema>;

export const prepareContactEmail = createServerFn({ method: "POST" })
  .inputValidator((data) => contactSchema.parse(data))
  .handler(async ({ data }) => {
    const subject = encodeURIComponent(`[AnaliseMelhor] ${data.subject}`);
    const body = encodeURIComponent(`Nome: ${data.name}\nE-mail: ${data.email}\n\nMensagem:\n${data.message}`);
    return { mailtoUrl: `mailto:guiasincero@gmail.com?subject=${subject}&body=${body}` };
  });
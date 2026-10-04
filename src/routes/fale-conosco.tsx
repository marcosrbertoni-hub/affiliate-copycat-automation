import { createFileRoute, redirect } from "@tanstack/react-router";

export const Route = createFileRoute("/fale-conosco")({
  staticData: { sitemap: false },
  loader: () => redirect({ to: "/contato", statusCode: 308 }),
});

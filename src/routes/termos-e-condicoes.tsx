import { createFileRoute, redirect } from "@tanstack/react-router";

export const Route = createFileRoute("/termos-e-condicoes")({
  staticData: { sitemap: false },
  loader: () => redirect({ to: "/termos", statusCode: 308 }),
});

import { createFileRoute, redirect } from "@tanstack/react-router";

export const Route = createFileRoute("/politica-de-privacidade")({
  staticData: { sitemap: false },
  loader: () => redirect({ to: "/privacidade", statusCode: 308 }),
});

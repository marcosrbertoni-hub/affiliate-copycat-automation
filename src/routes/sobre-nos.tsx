import { createFileRoute, redirect } from "@tanstack/react-router";

export const Route = createFileRoute("/sobre-nos")({
  staticData: { sitemap: false },
  loader: () => redirect({ to: "/sobre", statusCode: 308 }),
});

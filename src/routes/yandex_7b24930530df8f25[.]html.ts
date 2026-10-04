import { createFileRoute } from "@tanstack/react-router";

const body = `<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    </head>
    <body>Verification: 7b24930530df8f25</body>
</html>
`;

export const Route = createFileRoute("/yandex_7b24930530df8f25.html")({
  staticData: { sitemap: false },
  server: {
    handlers: {
      GET: () => new Response(body, { headers: { "content-type": "text/html; charset=utf-8" } }),
    },
  },
});

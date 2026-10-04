import "./lib/error-capture";

import { consumeLastCapturedError } from "./lib/error-capture";
import { renderErrorPage } from "./lib/error-page";

type ServerEntry = {
  fetch: (request: Request, env: unknown, ctx: unknown) => Promise<Response> | Response;
};

let serverEntryPromise: Promise<ServerEntry> | undefined;

async function getServerEntry(): Promise<ServerEntry> {
  if (!serverEntryPromise) {
    serverEntryPromise = import("@tanstack/react-start/server-entry").then(
      (m) => (m.default ?? m) as ServerEntry,
    );
  }
  return serverEntryPromise;
}

// h3 swallows in-handler throws into a normal 500 Response with body
// {"unhandled":true,"message":"HTTPError"} — try/catch alone never fires for those.
async function normalizeCatastrophicSsrResponse(response: Response): Promise<Response> {
  if (response.status < 500) return response;
  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("application/json")) return response;

  const body = await response.clone().text();
  if (!isH3SwallowedErrorBody(body)) return response;

  console.error(consumeLastCapturedError() ?? new Error(`h3 swallowed SSR error: ${body}`));
  return new Response(renderErrorPage(), {
    status: 500,
    headers: { "content-type": "text/html; charset=utf-8" },
  });
}

function isH3SwallowedErrorBody(body: string): boolean {
  try {
    const payload = JSON.parse(body) as { unhandled?: unknown; message?: unknown };
    return payload.unhandled === true && payload.message === "HTTPError";
  } catch {
    return false;
  }
}

export default {
  async fetch(request: Request, env: unknown, ctx: unknown) {
    try {
      const handler = await getServerEntry();
      const response = await handler.fetch(request, env, ctx);
      const normalized = await normalizeCatastrophicSsrResponse(response);
      const headers = new Headers(normalized.headers);
      headers.set(
        "Content-Security-Policy",
        "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://pagead2.googlesyndication.com https://*.googlesyndication.com https://fundingchoicesmessages.google.com https://*.adtrafficquality.google https://*.doubleclick.net; frame-src https://*.googlesyndication.com https://*.doubleclick.net https://fundingchoicesmessages.google.com https://www.google.com; connect-src 'self' https://fundingchoicesmessages.google.com https://*.adtrafficquality.google https://*.googlesyndication.com https://*.supabase.co https://www.googletagmanager.com https://*.google-analytics.com https://*.google.com https://*.g.doubleclick.net https://pagead2.googlesyndication.com; img-src 'self' data: blob: https:; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com data:; frame-ancestors 'self'; base-uri 'self'; object-src 'none'; form-action 'self' mailto:; upgrade-insecure-requests"
      );
      headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
      headers.set("X-Content-Type-Options", "nosniff");
      headers.set("X-Frame-Options", "SAMEORIGIN");
      headers.set("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
      return new Response(normalized.body, {
        status: normalized.status,
        statusText: normalized.statusText,
        headers,
      });
    } catch (error) {
      console.error(error);
      return new Response(renderErrorPage(), {
        status: 500,
        headers: { "content-type": "text/html; charset=utf-8" },
      });
    }
  },
};

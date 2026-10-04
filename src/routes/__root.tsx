import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import {
  Outlet,
  Link,
  createRootRouteWithContext,
  useRouter,
  HeadContent,
  Scripts,
  type ErrorComponentProps,
} from "@tanstack/react-router";
import { useEffect, type ReactNode } from "react";

import appCss from "../styles.css?url";
import { reportLovableError } from "../lib/lovable-error-reporting";
import { CookieConsent, SiteFooter, SiteHeader } from "../components/site-shell";

function NotFoundComponent() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-7xl font-bold text-foreground">404</h1>
        <h2 className="mt-4 text-xl font-semibold text-foreground">Page not found</h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The page you're looking for doesn't exist or has been moved.
        </p>
        <div className="mt-6">
          <Link
            to="/"
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Go home
          </Link>
        </div>
      </div>
    </div>
  );
}

function ErrorComponent({ error, reset }: ErrorComponentProps) {
  console.error(error);
  const router = useRouter();
  useEffect(() => {
    reportLovableError(error, { boundary: "tanstack_root_error_component" });
  }, [error]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="max-w-md text-center">
        <h1 className="text-xl font-semibold tracking-tight text-foreground">
          This page didn't load
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Something went wrong on our end. You can try refreshing or head back home.
        </p>
        <div className="mt-6 flex flex-wrap justify-center gap-2">
          <button
            onClick={() => {
              router.invalidate();
              reset();
            }}
            className="inline-flex items-center justify-center rounded-md bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-colors hover:bg-primary/90"
          >
            Try again
          </button>
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md border border-input bg-background px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-accent"
          >
            Go home
          </a>
        </div>
      </div>
    </div>
  );
}

export const Route = createRootRouteWithContext<{ queryClient: QueryClient }>()({
  staticData: { sitemap: false },
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "AnaliseMelhor — Comparativos para escolhas práticas" },
      { name: "description", content: "Seleções objetivas de produtos para comparar características e escolher com confiança." },
      { name: "author", content: "Equipe AnaliseMelhor" },
      { property: "og:type", content: "website" },
      { property: "og:site_name", content: "AnaliseMelhor" },
      { property: "og:locale", content: "pt_BR" },
      { name: "robots", content: "index, follow, max-image-preview:large, max-snippet:-1" },
      { name: "twitter:card", content: "summary_large_image" },
      { name: "google-adsense-account", content: "ca-pub-5728406273184598" },
    ],
    links: [
      {
        rel: "stylesheet",
        href: appCss,
      },
      { rel: "icon", href: "/favicon.png", type: "image/png", sizes: "64x64" },
      { rel: "preconnect", href: "https://fonts.googleapis.com" },
      { rel: "preconnect", href: "https://fonts.gstatic.com", crossOrigin: "anonymous" },
      { rel: "preconnect", href: "https://images-na.ssl-images-amazon.com" },
    ],
    scripts: [
      {
        // Fonts load without blocking the first paint; ads/analytics load after the page is visible.
        children: `(function(){
var f=document.createElement('link');f.rel='stylesheet';f.href='https://fonts.googleapis.com/css2?family=Sora:wght@600;700;800&family=Source+Sans+3:wght@400;500;600;700&family=JetBrains+Mono:wght@500&display=swap';document.head.appendChild(f);
window.dataLayer = window.dataLayer || [];
window.gtag=function(){dataLayer.push(arguments);};
gtag('consent', 'default', { analytics_storage: 'denied', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied', wait_for_update: 500 });
gtag('js', new Date());
gtag('config', 'G-683XJFVZ6Q');
var done=false;function load(){if(done)return;done=true;
var g=document.createElement('script');g.async=true;g.src='https://www.googletagmanager.com/gtag/js?id=G-683XJFVZ6Q';document.head.appendChild(g);
var a=document.createElement('script');a.async=true;a.crossOrigin='anonymous';a.src='https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-5728406273184598';document.head.appendChild(a);}
['scroll','pointerdown','keydown','touchstart'].forEach(function(e){addEventListener(e,load,{once:true,passive:true});});
addEventListener('load',function(){setTimeout(load,3500);});
})();`,
      },
    ],
  }),
  shellComponent: RootShell,
  component: RootComponent,
  notFoundComponent: NotFoundComponent,
  errorComponent: ErrorComponent,
});

function RootShell({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR">
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  );
}

function RootComponent() {
  const { queryClient } = Route.useRouteContext();

  return (
    <QueryClientProvider client={queryClient}>
      <SiteHeader />
      <main><Outlet /></main>
      <SiteFooter />
      <CookieConsent />
    </QueryClientProvider>
  );
}

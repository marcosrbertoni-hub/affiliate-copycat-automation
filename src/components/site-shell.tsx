import { Link } from "@tanstack/react-router";
import { Menu, Search, ShieldCheck, X } from "lucide-react";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { articleTitle } from "@/lib/content-title";
import { searchPages, type PagePreview } from "@/lib/pages.functions";
import brandIcon from "@/assets/brand-icon.webp.asset.json";

const categories = [
  { name: "Beleza", slug: "beleza", color: "beleza" },
  { name: "Cozinha", slug: "cozinha", color: "cozinha" },
  { name: "Saúde", slug: "fitness", color: "bebe" },
  { name: "Tecnologia", slug: "tecnologia", color: "livros" },
  { name: "Casa", slug: "casa", color: "casa" },
  { name: "Pet", slug: "pet", color: "pet" },
] as const;

export function Brand() {
  return (
    <Link to="/" aria-label="AnaliseMelhor — página inicial" className="flex shrink-0 items-center gap-2 transition-transform hover:scale-[1.02] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-soft">
      <img src={brandIcon.url} alt="AnaliseMelhor" width={48} height={48} className="size-10 shrink-0 sm:size-12 object-contain" />
      <span className="font-display text-lg font-bold tracking-tight sm:text-xl text-header-foreground">AnaliseMelhor</span>
    </Link>
  );
}

export function SiteHeader() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<PagePreview[]>([]);
  const [searching, setSearching] = useState(false);
  useEffect(() => {
    if (query.trim().length < 2) { setResults([]); return; }
    const timer = window.setTimeout(async () => {
      setSearching(true);
      try { setResults(await searchPages({ data: { query } })); } finally { setSearching(false); }
    }, 250);
    return () => window.clearTimeout(timer);
  }, [query]);

  return (
    <>
      <header className="sticky top-0 z-50 border-b border-header-border bg-header/95 text-header-foreground backdrop-blur-xl">
        <div className="mx-auto flex h-14 max-w-7xl items-center justify-between px-3 sm:h-16 sm:px-4 lg:px-8">
          <Brand />
          <nav className="hidden items-center gap-5 lg:flex" aria-label="Categorias">
            {categories.map((category) => <Link key={category.slug} to="/$" params={{ _splat: category.slug }} className="flex items-center gap-2 text-sm font-medium text-header-muted transition-colors hover:text-header-foreground"><span className={`category-dot bg-category-${category.color}`} />{category.name}</Link>)}<a href="/sobre" className="text-sm font-medium text-header-muted transition-colors hover:text-header-foreground">Sobre</a><a href="/contato" className="text-sm font-medium text-header-muted transition-colors hover:text-header-foreground">Contato</a>
          </nav>
          <div className="flex items-center gap-1 sm:gap-1.5">
            <Button variant="header" size="sm" onClick={() => setSearchOpen(true)} aria-label="Pesquisar"><Search /> <span className="hidden sm:inline">Pesquisar</span><kbd className="hidden rounded border border-header-border px-1.5 py-0.5 font-mono text-[10px] text-header-muted md:inline">Ctrl K</kbd></Button>
            <Button variant="header" size="icon" className="lg:hidden" onClick={() => setMenuOpen(!menuOpen)} aria-label="Abrir menu">{menuOpen ? <X /> : <Menu />}</Button>
          </div>
        </div>
        {menuOpen && <nav className="grid grid-cols-2 gap-2 border-t border-header-border px-3 py-3 sm:px-4 sm:py-4 lg:hidden">{categories.map((category) => <Link key={category.slug} to="/$" params={{ _splat: category.slug }} onClick={() => setMenuOpen(false)} className="flex items-center gap-2 rounded-md px-3 py-2 text-sm text-header-muted hover:bg-header-surface"><span className={`category-dot bg-category-${category.color}`} />{category.name}</Link>)}<a href="/sobre" onClick={() => setMenuOpen(false)} className="rounded-md px-3 py-2 text-sm text-header-muted hover:bg-header-surface">Sobre Nós</a><a href="/contato" onClick={() => setMenuOpen(false)} className="rounded-md px-3 py-2 text-sm text-header-muted hover:bg-header-surface">Contato</a></nav>}
      </header>
      {searchOpen && <div className="fixed inset-0 z-[60] bg-overlay/70 p-3 sm:p-4 backdrop-blur-sm" role="dialog" aria-modal="true" aria-label="Busca"><div className="mx-auto mt-[7vh] max-w-2xl sm:mt-[10vh] overflow-hidden rounded-lg border border-border bg-card shadow-2xl"><div className="flex items-center gap-3 border-b border-border p-4"><Search className="text-muted-foreground"/><input autoFocus value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Busque por produtos e guias..." className="h-11 flex-1 bg-transparent text-base outline-none"/><Button variant="ghost" size="icon" onClick={() => setSearchOpen(false)} aria-label="Fechar busca"><X /></Button></div><div className="max-h-[65vh] sm:max-h-[55vh] overflow-y-auto p-3">{searching && <p className="p-4 text-center text-sm text-muted-foreground">Buscando...</p>}{!searching && results.map((post) => <Link key={post.slug} to="/$" params={{ _splat: post.slug }} onClick={() => setSearchOpen(false)} className="block rounded-md p-3 hover:bg-muted"><span className="text-xs font-bold uppercase text-brand">{post.category_name ?? "Guia"}</span><span className="mt-1 block font-semibold">{articleTitle(post.title)}</span></Link>)}{!searching && query.length >= 2 && results.length === 0 && <p className="p-6 text-center text-sm text-muted-foreground">Nenhum guia encontrado.</p>}</div></div></div>}
    </>
  );
}

export function SiteFooter() {
  return <footer className="mt-12 bg-header sm:mt-20 text-header-muted"><div className="mx-auto grid max-w-7xl gap-8 px-4 py-10 sm:gap-10 sm:py-12 sm:grid-cols-2 lg:grid-cols-[1.5fr_1fr_1fr_1fr] lg:px-8"><div><Brand /><p className="mt-4 max-w-md text-sm leading-6">Comparações objetivas para decisões práticas no dia a dia.</p><div className="mt-5 flex items-center gap-2 text-xs"><ShieldCheck className="size-4 text-brand-soft"/> Critérios claros e seleção independente</div></div><div><h3 className="font-bold text-header-foreground">Categorias</h3><div className="mt-4 grid gap-2 text-sm">{categories.slice(0,4).map((category) => <Link key={category.slug} to="/$" params={{ _splat: category.slug }} className="hover:text-header-foreground">{category.name}</Link>)}</div></div><div><h3 className="font-bold text-header-foreground">Links</h3><div className="mt-4 grid gap-2 text-sm"><a href="/sobre" className="hover:text-header-foreground">Sobre Nós</a><a href="/contato" className="hover:text-header-foreground">Contato</a><a href="/privacidade" className="hover:text-header-foreground">Privacidade</a><a href="/termos" className="hover:text-header-foreground">Termos de Uso</a></div></div><div><h3 className="font-bold text-header-foreground">Transparência</h3><p className="mt-4 text-sm leading-6">Participamos do sistema de afiliados da Amazon e podemos receber comissão por compras feitas pelos links indicados, sem custo adicional para você.</p></div></div><div className="border-t border-header-border px-4 py-5 text-center text-xs">© 2026 AnaliseMelhor · Responsável: Marcos Roberto Krauswscki Filho. <button type="button" onClick={() => window.dispatchEvent(new Event("analisemelhor:open-consent"))} className="underline underline-offset-2 hover:text-header-foreground">Preferências de cookies</button></div></footer>;
}

export function CookieConsent() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const handleReopen = () => reopenConsent();
    window.addEventListener("analisemelhor:open-consent", handleReopen);
    try {
      setVisible(localStorage.getItem("analisemelhor-cookie-consent") === null);
    } catch {
      setVisible(true);
    }
    return () => window.removeEventListener("analisemelhor:open-consent", handleReopen);
  }, []);

  function updateConsent(granted: boolean) {
    try {
      localStorage.setItem("analisemelhor-cookie-consent", granted ? "accepted" : "rejected");
    } catch {
      // Continue without persistence when storage is unavailable.
    }
    if (typeof window !== "undefined" && typeof window.gtag === "function") {
      window.gtag("consent", "update", {
        analytics_storage: granted ? "granted" : "denied",
        ad_storage: "denied",
        ad_user_data: "denied",
        ad_personalization: "denied",
      });
    }
    setVisible(false);
  }

  function reopenConsent() {
    setVisible(true);
  }

  if (!visible) return null;

  return (
    <aside
      role="region"
      aria-label="Preferências de cookies"
      className="fixed inset-x-2 bottom-2 z-[70] mx-auto max-w-3xl rounded-lg border border-border bg-card p-3 sm:inset-x-4 sm:bottom-4 sm:p-4 shadow-2xl sm:inset-x-4 sm:bottom-4 sm:flex sm:items-center sm:gap-5"
    >
      <div className="min-w-0 flex-1">
        <p className="font-semibold text-foreground">Preferências de cookies</p>
        <p className="mt-1 text-sm leading-5 text-muted-foreground">
          Usamos cookies e tecnologias semelhantes para medir o acesso e melhorar o site. Você pode aceitar ou recusar a medição não essencial. Saiba mais na{" "}
          <a href="/privacidade" className="font-semibold text-brand underline underline-offset-2">Política de Privacidade</a>.
        </p>
      </div>
      <div className="mt-3 grid shrink-0 grid-cols-2 gap-2 sm:mt-0 sm:flex">
        <button
          type="button"
          onClick={() => updateConsent(false)}
          className="rounded-md border border-border px-3 py-2.5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
        >
          Recusar
        </button>
        <button
          type="button"
          onClick={() => updateConsent(true)}
          className="rounded-md bg-brand px-4 py-2 text-sm font-semibold text-primary-foreground transition-colors hover:opacity-90"
        >
          Aceitar
        </button>
      </div>
    </aside>
  );
}

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
  }
}

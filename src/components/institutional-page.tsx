import type { ReactNode } from "react";
import { Link } from "@tanstack/react-router";
import { ChevronRight } from "lucide-react";

type InstitutionalPageProps = {
  eyebrow: string;
  title: string;
  description: string;
  children: ReactNode;
};

export function InstitutionalPage({ eyebrow, title, description, children }: InstitutionalPageProps) {
  return (
    <>
      <header className="bg-article-hero text-header-foreground">
        <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
          <nav className="flex items-center gap-1.5 text-xs text-header-muted" aria-label="Navegação estrutural">
            <Link to="/">Início</Link>
            <ChevronRight className="size-3" />
            <span>{eyebrow}</span>
          </nav>
          <span className="mt-8 inline-block border-l-4 border-line pl-3 text-xs font-bold uppercase text-header-muted">
            {eyebrow}
          </span>
          <h1 className="mt-4 max-w-4xl font-display text-4xl font-extrabold leading-tight sm:text-5xl">{title}</h1>
          <p className="mt-5 max-w-3xl text-lg leading-8 text-header-muted">{description}</p>
        </div>
      </header>
      <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <div className="max-w-3xl space-y-10 text-base leading-8 text-muted-foreground [&_a]:font-semibold [&_a]:text-primary [&_a]:underline-offset-4 hover:[&_a]:underline [&_h2]:font-display [&_h2]:text-2xl [&_h2]:font-bold [&_h2]:text-foreground [&_li]:pl-1 [&_strong]:text-foreground [&_ul]:list-disc [&_ul]:space-y-2 [&_ul]:pl-6">
          {children}
        </div>
      </div>
    </>
  );
}
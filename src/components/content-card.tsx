import { Link } from "@tanstack/react-router";
import { ArrowUpRight, Clock3 } from "lucide-react";
import { articleTitle } from "@/lib/content-title";
import type { PagePreview } from "@/lib/pages.functions";
import { SafeImage } from "@/components/safe-image";

export function ContentCard({ post, priority = false }: { post: PagePreview; priority?: boolean }) {
  return (
    <article className="group overflow-hidden rounded-lg border border-border bg-card shadow-step">
      <Link to="/$" params={{ _splat: post.slug }} className="block h-full">
        <div className="aspect-[16/10] overflow-hidden bg-muted">
          <SafeImage src={post.image ?? undefined} alt={articleTitle(post.title)} width={390} height={500} className="h-full w-full bg-card object-contain p-3 transition-transform duration-500 group-hover:scale-[1.03]" loading={priority ? "eager" : "lazy"} fetchPriority={priority ? "high" : "auto"} decoding="async" />
        </div>
        <div className="p-4 sm:p-5">
          <span className="text-xs font-bold uppercase text-brand">{post.category_name ?? "Guia de compra"}</span>
          <h3 className="mt-2 font-display text-lg font-bold leading-snug sm:text-xl group-hover:text-brand">{articleTitle(post.title)}</h3>
          <div className="mt-4 flex items-center justify-between text-xs text-muted-foreground">
            <span className="flex items-center gap-1.5"><Clock3 className="size-3.5" />{post.reading_time ?? "Leitura rápida"}</span>
            <ArrowUpRight className="size-4" />
          </div>
        </div>
      </Link>
    </article>
  );
}
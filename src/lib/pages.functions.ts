import { createServerFn } from "@tanstack/react-start";
import { z } from "zod";

async function publicClient() {
  const { createClient } = await import("@supabase/supabase-js");
  const url = process.env["SUPABASE_URL"] ?? import.meta.env['VITE_SUPABASE_URL'];
  const key = process.env["SUPABASE_PUBLISHABLE_KEY"] ?? import.meta.env['VITE_SUPABASE_PUBLISHABLE_KEY'];
  return createClient(url!, key!, { auth: { persistSession: false, autoRefreshToken: false } });
}

export type PageRecord = {
  slug: string;
  kind: string;
  title: string;
  description: string | null;
  category_name: string | null;
  category_slug: string | null;
  image: string | null;
  published_at: string | null;
  reading_time: string | null;
  html: string;
};

export type PagePreview = Omit<PageRecord, "html">;

const pageFields = "slug,kind,title,description,category_name,category_slug,image,published_at,reading_time";

export const getHomeData = createServerFn({ method: "GET" }).handler(async () => {
  const supabaseAdmin = await publicClient();
  const [{ data: posts, error: postsError }, { data: categoryRows, error: categoriesError }] = await Promise.all([
    supabaseAdmin.from("pages").select(pageFields).eq("kind", "article").not("image", "is", null).not("image", "ilike", "%og-default%").order("created_at", { ascending: false }).limit(12),
    supabaseAdmin.from("pages").select("category_name,category_slug").eq("kind", "article"),
  ]);
  if (postsError) throw postsError;
  if (categoriesError) throw categoriesError;
  const counts = new Map<string, { name: string; slug: string; count: number }>();
  for (const row of categoryRows ?? []) {
    if (!row.category_name || !row.category_slug) continue;
    const current = counts.get(row.category_slug);
    counts.set(row.category_slug, { name: row.category_name, slug: row.category_slug, count: (current?.count ?? 0) + 1 });
  }
  return { posts: (posts ?? []) as PagePreview[], categories: [...counts.values()].sort((a, b) => b.count - a.count) };
});

export const getPage = createServerFn({ method: "GET" })
  .inputValidator((data) => z.object({ slug: z.string().min(1).max(300) }).parse(data))
  .handler(async ({ data }) => {
    const supabaseAdmin = await publicClient();
    const { data: found, error } = await supabaseAdmin.from("pages").select("*").eq("slug", data.slug).maybeSingle();
    if (error) throw error;
    let page = found;
    if (!page) {
      const { data: sample } = await supabaseAdmin.from("pages").select("category_name").eq("category_slug", data.slug).limit(1).maybeSingle();
      if (!sample?.category_name) return null;
      page = { slug: data.slug, kind: "category", title: sample.category_name, description: `Guias e comparativos de ${sample.category_name}.`, category_name: sample.category_name, category_slug: data.slug, image: null, published_at: null, reading_time: null, html: "" };
    }
    const categorySlug = page.category_slug ?? page.slug;
    const { data: related } = await supabaseAdmin.from("pages").select(pageFields).eq("kind", "article").eq("category_slug", categorySlug).neq("slug", page.slug).not("image", "is", null).not("image", "ilike", "%og-default%").limit(page.slug === categorySlug ? 30 : 6);
    return { page: page as PageRecord, related: (related ?? []) as PagePreview[] };
  });

export const searchPages = createServerFn({ method: "GET" })
  .inputValidator((data) => z.object({ query: z.string().trim().min(2).max(80) }).parse(data))
  .handler(async ({ data }) => {
    const supabaseAdmin = await publicClient();
    const query = data.query.replace(/[%_,()]/g, " ").trim();
    const { data: rows, error } = await supabaseAdmin.from("pages").select(pageFields).eq("kind", "article").ilike("title", `%${query}%`).limit(10);
    if (error) throw error;
    return (rows ?? []) as PagePreview[];
  });
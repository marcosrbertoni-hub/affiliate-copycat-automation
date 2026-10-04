import { withAffiliate } from "@/lib/affiliate";
import { contentTitle } from "@/lib/content-title";
import type { PageRecord } from "@/lib/pages.functions";

export type ProductFact = {
  name: string;
  image: string | null;
  url: string;
  price: string | null;
  badge: string;
  facts: string[];
  rating: ProductRating | null;
};

export type ProductRating = {
  value: number;
  count: number;
  source: "Amazon";
};

const decode = (value: string) => value
  .replace(/<[^>]+>/g, " ")
  .replace(/&amp;/g, "&")
  .replace(/&quot;/g, '"')
  .replace(/&#39;|&apos;/g, "'")
  .replace(/&nbsp;/g, " ")
  .replace(/\s+/g, " ")
  .trim();

const lastMatch = (source: string, pattern: RegExp) => {
  const matches = [...source.matchAll(pattern)];
  return matches.at(-1) ?? null;
};

function amazonImage(url: string) {
  const asin = url.match(/\/dp\/([A-Z0-9]{10})/i)?.[1];
  return asin ? `https://images-na.ssl-images-amazon.com/images/P/${asin.toUpperCase()}.01.LZZZZZZZ.jpg` : null;
}

function parseBrazilianCount(value: string) {
  const count = Number.parseInt(value.replace(/\./g, ""), 10);
  return Number.isSafeInteger(count) && count > 0 ? count : null;
}

/** Accepts only ratings explicitly attributed to Amazon and paired with a review count. */
function extractVerifiedRating(source: string): ProductRating | null {
  const match = source.match(/(?:nota|m[eé]dia|classifica[cç][aã]o\s+m[eé]dia)(?:\s+de)?\s*([0-5](?:[,.]\d)?)\s+de\s+5\s+estrelas\s+na\s+Amazon[\s\S]{0,220}?(?:mais\s+de\s+)?([\d.]+)\s+avalia[cç][oõ]es/i);
  if (!match?.[1] || !match[2]) return null;
  const value = Number.parseFloat(match[1].replace(",", "."));
  const count = parseBrazilianCount(match[2]);
  if (!Number.isFinite(value) || value < 1 || value > 5 || !count) return null;
  return { value, count, source: "Amazon" };
}

export function extractProducts(html: string): ProductFact[] {
  const products: ProductFact[] = [];
  const seen = new Set<string>();
  const linkPattern = /<a\b[^>]*href=["'](https?:\/\/(?:www\.)?amazon\.com\.br\/[^"']+)["'][^>]*>/gi;
  for (const match of html.matchAll(linkPattern)) {
    const rawUrl = decode(match[1] ?? "");
    const url = withAffiliate(rawUrl);
    const productKey = url.split("?")[0] ?? url;
    if (seen.has(productKey)) continue;
    const offset = match.index ?? 0;
    const before = html.slice(Math.max(0, offset - 14000), offset);
    const aroundProduct = html.slice(Math.max(0, offset - 7000), Math.min(html.length, offset + 7000));
    const heading = lastMatch(before, /<h2\b[^>]*>([\s\S]*?)<\/h2>/gi);
    const imageMatch = lastMatch(before, /<img\b[^>]*src=["']([^"']+)["'][^>]*(?:alt=["']([^"']*)["'])?[^>]*>/gi);
    const priceMatch = lastMatch(before, /R\$\s*[\d.]+,\d{2}/gi);
    const badgeMatch = lastMatch(before, /<p\b[^>]*uppercase[^>]*>([\s\S]*?)<\/p>/gi);
    const name = decode(heading?.[1] ?? imageMatch?.[2] ?? `Produto ${products.length + 1}`);
    if (!name || /tabela|índice|comparativ/i.test(name)) continue;
    const factMatches = [...before.slice(-7000).matchAll(/<li\b[^>]*>([\s\S]*?)<\/li>/gi)]
      .map((item) => decode(item[1] ?? ""))
      .filter((item) => item.length > 3 && item.length < 110)
      .slice(-4);
    seen.add(productKey);
    products.push({
      name,
      image: amazonImage(url) ?? (imageMatch?.[1] && !/analisamelhor\.com\.br/i.test(imageMatch[1]) ? decode(imageMatch[1]) : null),
      url,
      price: priceMatch?.[0] ?? null,
      badge: decode(badgeMatch?.[1] ?? (products.length === 0 ? "Escolha em destaque" : "Opção selecionada")),
      facts: factMatches,
      rating: extractVerifiedRating(decode(aroundProduct)),
    });
    if (products.length >= 12) break;
  }
  return products;
}

export function makeArticleIntro(page: PageRecord, productCount: number) {
  const subject = contentTitle(page.title).replace(/\s+em\s+20\d{2}/i, "").trim();
  const category = page.category_name?.trim();
  const count = productCount || "diferentes";
  const context = category ? ` dentro da categoria ${category.toLowerCase()}` : "";
  return `Se você está pesquisando ${subject.toLowerCase()}, este guia compara ${count} opções${context}. A análise reúne características disponíveis, faixa de preço informada e pontos de atenção para ajudar você a identificar qual alternativa combina melhor com seu uso e orçamento. Antes de comprar, confira as especificações e as condições atuais na loja.`;
}

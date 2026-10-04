const SOURCE_BRAND_SUFFIX = /\s*[-–|]\s*Analis[ae]Melhor.*$/i;
const REVIEW_PREFIX = /^\s*Revis(?:ão|ao)\s*(?:(?:d[aeo]s?|sobre)\s+)?[:\-–|]?\s*/i;
const SOURCE_REFERENCE = /\s*\(\[[^\]]+\]\(https?:\/\/.*$/i;
const URL_REFERENCE = /\s*https?:\/\/.*$/i;
const DISAMBIGUATION = /\s*[—–-]\s*(?:não|nao)\s+confundir\b.*$/i;

const SHORT_TITLE_SUFFIXES = [
  " — características, preços e guia de compra",
  " — preços, análise e guia de compra",
  " — comparação para comprar melhor",
  " — guia de compra atualizado",
  " — análise e guia de compra",
  " — guia completo de compra",
  " — guia de compra",
  " — análise completa",
  " — guia completo",
  " — análise",
  " — guia",
] as const;

function cleanTitle(title: string) {
  return title
    .replace(SOURCE_BRAND_SUFFIX, "")
    .replace(REVIEW_PREFIX, "")
    .replace(SOURCE_REFERENCE, "")
    .replace(URL_REFERENCE, "")
    .replace(DISAMBIGUATION, "")
    .replace(/\s+/g, " ")
    .replace(/[\s:;,—–-]+$/, "")
    .trim();
}

function truncateAtWord(title: string, limit: number) {
  if (title.length <= limit) return title;
  const candidate = title.slice(0, limit + 1);
  const boundary = candidate.lastIndexOf(" ");
  const shortened = boundary >= 55 ? candidate.slice(0, boundary) : title.slice(0, limit);
  return shortened
    .replace(/\s+(?:a|ao|as|com|da|das|de|do|dos|e|em|modelo|na|nas|no|nos|o|os|para|por)$/i, "")
    .replace(/[\s:;,—–-]+$/, "")
    .trim();
}

/** Converts imported editorial titles into search-first Brazilian Portuguese titles. */
export function contentTitle(title: string) {
  return cleanTitle(title);
}

/** Produces a natural, keyword-first article title between 60 and 70 characters. */
export function articleTitle(title: string) {
  const cleaned = cleanTitle(title);
  if (!cleaned) return "Comparativo de produtos: análise, preços e guia de compra";

  if (cleaned.length > 70) {
    const subject = cleaned.split(":")[0]?.trim() ?? cleaned;
    if (subject.length < 60) {
      const contextual = SHORT_TITLE_SUFFIXES.find((suffix) => subject.length + suffix.length >= 60 && subject.length + suffix.length <= 70);
      if (contextual) return subject + contextual;
    }
    const shortened = truncateAtWord(subject.length >= 60 ? subject : cleaned, 68);
    if (shortened.length >= 60) return shortened;
    const withContext = SHORT_TITLE_SUFFIXES.find((suffix) => shortened.length + suffix.length >= 60 && shortened.length + suffix.length <= 70);
    return withContext ? shortened + withContext : truncateAtWord(`${shortened} — análise, preços e guia de compra`, 68);
  }

  if (cleaned.length >= 60) return cleaned;
  const suffix = SHORT_TITLE_SUFFIXES.find((candidate) => cleaned.length + candidate.length >= 60 && cleaned.length + candidate.length <= 70);
  if (suffix) return cleaned + suffix;

  const fallback = truncateAtWord(`${cleaned} — características, comparação, preços e guia de compra`, 68);
  return fallback.length >= 60 ? fallback : `${fallback} atual`;
}
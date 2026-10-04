export const AFFILIATE_QUERY =
  "tag=shoptimego09-20&linkCode=as4&ref_=onb_gen_lnk&th=1";

const trackingKeys = new Set(["tag", "linkCode", "ref_", "th"]);

export function withAffiliate(url: string) {
  try {
    const parsed = new URL(url);
    if (!/(^|\.)amazon\.com\.br$/i.test(parsed.hostname)) return url;
    for (const key of trackingKeys) parsed.searchParams.delete(key);
    for (const [key, value] of new URLSearchParams(AFFILIATE_QUERY)) {
      parsed.searchParams.set(key, value);
    }
    return parsed.toString();
  } catch {
    return url;
  }
}
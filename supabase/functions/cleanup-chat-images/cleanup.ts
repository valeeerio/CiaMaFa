// Logica pura del cleanup delle immagini della chat (provata con
// `node --test supabase/functions/cleanup-chat-images/cleanup_test.mjs`).

export interface StoredObject {
  name: string;
  created_at: string | null;
}

const romeParts = (t: number) => {
  const p = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Europe/Rome",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(new Date(t));
  const get = (type: string) => Number(p.find((x) => x.type === type)!.value);
  return { y: get("year"), m: get("month"), d: get("day"), h: get("hour"), min: get("minute") };
};

/** L'ultima mezzanotte di Europe/Rome prima di [now] (l'inizio di "oggi"). */
export function lastRomeMidnight(now: Date): Date {
  const { y, m, d } = romeParts(now.getTime());
  const wallMidnightAsUtc = Date.UTC(y, m - 1, d);
  // Roma è UTC+1 o UTC+2: prova entrambi e tieni quello che dà davvero 00:00.
  for (const offsetHours of [1, 2]) {
    const candidate = wallMidnightAsUtc - offsetHours * 3_600_000;
    const r = romeParts(candidate);
    if (r.d === d && r.h === 0 && r.min === 0) return new Date(candidate);
  }
  throw new Error("mezzanotte di Roma non trovata");
}

/** Path completi degli oggetti di [folder] creati prima di [cutoff] (i nomi sono relativi alla cartella). */
export function staleObjects(
  folder: string,
  objects: StoredObject[],
  cutoff: Date,
): string[] {
  return objects
    .filter((o) => o.created_at !== null && new Date(o.created_at) < cutoff)
    .map((o) => `${folder}/${o.name}`);
}

export function batches<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}

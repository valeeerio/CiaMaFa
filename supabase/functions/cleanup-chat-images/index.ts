// cleanup-chat-images: libera lo storage delle chat scadute.
//
// La RLS nasconde i messaggi scaduti ma non libera lo storage, e cancellare da
// SQL `storage.objects` non elimina il file vero: serve l'API di Storage.
// Ogni notte (pg_cron → public.run_chat_cleanup(), header x-push-secret come
// send-push, quindi `verify_jwt` è false):
//   1. rimuove dal bucket chat-images tutto ciò che è stato creato prima
//      dell'ultima mezzanotte di Roma (immagini dei messaggi scaduti, file
//      orfani di upload senza messaggio, immagini di profili cancellati);
//   2. elimina le righe dei messaggi scaduti (purge_expired_messages()).
// Idempotente: può girare più volte senza danni.
import { createClient } from "npm:@supabase/supabase-js@2";
import { batches, lastRomeMidnight, type StoredObject, staleObjects } from "./cleanup.ts";

const BUCKET = "chat-images";
const PAGE = 1000;

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// deno-lint-ignore no-explicit-any
type Db = any;

/** Tutti gli oggetti dentro una cartella, pagina per pagina. */
async function listFolder(db: Db, folder: string): Promise<StoredObject[]> {
  const out: StoredObject[] = [];
  for (let offset = 0;; offset += PAGE) {
    const { data, error } = await db.storage
      .from(BUCKET)
      .list(folder, { limit: PAGE, offset });
    if (error) throw new Error(error.message);
    out.push(...(data ?? []).filter((o: { id: string | null }) => o.id !== null));
    if ((data ?? []).length < PAGE) return out;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: cfg } = await db.from("push_config").select("secret").maybeSingle();
  if (!cfg || req.headers.get("x-push-secret") !== cfg.secret) {
    return json({ error: "unauthorized" }, 401);
  }

  const cutoff = lastRomeMidnight(new Date());
  try {
    // Le cartelle di primo livello sono i gruppi (id nullo = cartella).
    const { data: root, error } = await db.storage.from(BUCKET).list("", { limit: PAGE });
    if (error) throw new Error(error.message);
    const folders: string[] = (root ?? [])
      .filter((o: { id: string | null }) => o.id === null)
      .map((o: { name: string }) => o.name);

    let removed = 0;
    for (const folder of folders) {
      const stale = staleObjects(folder, await listFolder(db, folder), cutoff);
      for (const batch of batches(stale, 100)) {
        const { error: rmError } = await db.storage.from(BUCKET).remove(batch);
        if (rmError) throw new Error(rmError.message);
        removed += batch.length;
      }
    }

    // Solo dopo i file: le righe (le reazioni seguono a cascata).
    const { error: purgeError } = await db.rpc("purge_expired_messages");
    if (purgeError) throw new Error(purgeError.message);
    return json({ removed, cutoff: cutoff.toISOString() });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

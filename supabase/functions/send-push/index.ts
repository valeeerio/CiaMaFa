// send-push: invia le notifiche di CiaMaFa (nuovo piano, voto, annullamento).
//
// Chiamata SOLO dai trigger del database (pg_net) con l'header x-push-secret,
// uguale al segreto in public.push_config: per questo `verify_jwt` è false.
// Il segreto FIREBASE_SERVICE_ACCOUNT (JSON dell'account di servizio) si imposta
// dalla dashboard Supabase; se manca la funzione risponde "skipped" e non fa nulla.
import { createClient } from "npm:@supabase/supabase-js@2";
import { sendMessage, type ServiceAccount } from "./fcm.ts";
import { cancelMessage, planMessage, type PushMessage, voteMessage } from "./messages.ts";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

// deno-lint-ignore no-explicit-any
type Db = any;

interface Job {
  message: PushMessage;
  recipientIds: string[];
}

/** Chi è nel gruppo, ha le notifiche accese e non è [exceptId]. */
async function groupRecipients(db: Db, groupId: string, exceptId: string): Promise<string[]> {
  const { data } = await db
    .from("profiles")
    .select("id")
    .eq("group_id", groupId)
    .eq("notifications_enabled", true)
    .neq("id", exceptId);
  return (data ?? []).map((r: { id: string }) => r.id);
}

const PLAN_SELECT =
  "id, group_id, creator_id, emoji, label, places(name), profiles!plans_creator_id_fkey(nickname)";

async function buildJob(db: Db, body: Record<string, string>): Promise<Job | null> {
  if (body.kind === "plan") {
    const { data: p } = await db.from("plans").select(PLAN_SELECT).eq("id", body.plan_id).single();
    if (!p) return null;
    return {
      message: planMessage(p.profiles.nickname, p.emoji, p.label, p.places?.name ?? null, p.id),
      recipientIds: await groupRecipients(db, p.group_id, p.creator_id),
    };
  }
  if (body.kind === "vote") {
    const { data: p } = await db.from("plans").select(PLAN_SELECT).eq("id", body.plan_id).single();
    const { data: v } = await db
      .from("votes")
      .select("vote, profiles(nickname)")
      .eq("plan_id", body.plan_id)
      .eq("profile_id", body.voter_id)
      .single();
    // Il voto automatico del creatore non è una notizia.
    if (!p || !v || body.voter_id === p.creator_id) return null;
    const { data: owner } = await db
      .from("profiles")
      .select("notifications_enabled")
      .eq("id", p.creator_id)
      .single();
    if (!owner?.notifications_enabled) return null;
    return {
      message: voteMessage(v.profiles.nickname, v.vote, p.emoji, p.label, p.places?.name ?? null, p.id),
      recipientIds: [p.creator_id],
    };
  }
  if (body.kind === "cancel") {
    const { data: c } = await db
      .from("plan_cancellations")
      .select("group_id, creator_id, creator_nickname, emoji, label, place_name")
      .eq("id", body.cancellation_id)
      .single();
    if (!c) return null;
    return {
      message: cancelMessage(c.creator_nickname, c.emoji, c.label, c.place_name),
      recipientIds: await groupRecipients(db, c.group_id, c.creator_id),
    };
  }
  return null;
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

  let body: Record<string, string>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad-json" }, 400);
  }

  const job = await buildJob(db, body);
  if (!job || job.recipientIds.length === 0) return json({ skipped: "no-recipients" });

  const { data: rows } = await db
    .from("device_tokens")
    .select("token")
    .in("profile_id", job.recipientIds);
  const tokens: string[] = (rows ?? []).map((r: { token: string }) => r.token);
  if (tokens.length === 0) return json({ skipped: "no-tokens" });

  const raw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!raw) return json({ skipped: "no-credentials", tokens: tokens.length });

  let sa: ServiceAccount;
  try {
    sa = JSON.parse(raw);
  } catch {
    return json({ error: "bad-service-account" }, 500);
  }

  const counts = { sent: 0, unregistered: 0, error: 0 };
  const dead: string[] = [];
  await Promise.all(tokens.map(async (t) => {
    try {
      const outcome = await sendMessage(sa, t, job.message);
      counts[outcome]++;
      if (outcome === "unregistered") dead.push(t);
    } catch {
      counts.error++;
    }
  }));
  // Token spariti (app disinstallata): via dal database.
  if (dead.length > 0) await db.from("device_tokens").delete().in("token", dead);
  return json(counts);
});

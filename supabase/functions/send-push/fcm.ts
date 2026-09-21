// Invio via Firebase Cloud Messaging (HTTP v1) con un account di servizio.
import { classifyFcmResponse, type FcmOutcome, type PushMessage } from "./messages.ts";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

function b64url(data: ArrayBuffer | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[A-Z ]+-----/g, "").replace(/\s+/g, "");
  const raw = atob(b64);
  const out = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out.buffer;
}

let cached: { token: string; expiresAt: number } | null = null;

/** Token OAuth per FCM (riusato finché valido). */
export async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.expiresAt - 60 > now) return cached.token;

  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${b64url(JSON.stringify(claim))}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${b64url(sig)}`,
    }),
  });
  if (!res.ok) throw new Error(`OAuth FCM: ${res.status}`);
  const json = await res.json();
  cached = { token: json.access_token, expiresAt: now + (json.expires_in ?? 3600) };
  return cached.token;
}

export interface SendResult {
  outcome: FcmOutcome;
  /** Stato HTTP di FCM (per la diagnostica: mai il contenuto del messaggio). */
  status: number;
}

export async function sendMessage(
  sa: ServiceAccount,
  deviceToken: string,
  message: PushMessage,
): Promise<SendResult> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await accessToken(sa)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: deviceToken,
          notification: { title: message.title, body: message.body },
          data: { route: message.route },
          apns: { payload: { aps: { sound: "default" } } },
          android: { priority: "HIGH" },
        },
      }),
    },
  );
  let body: unknown = null;
  try {
    body = await res.json();
  } catch { /* corpo vuoto */ }
  return { outcome: classifyFcmResponse(res.status, body), status: res.status };
}

// Testi delle notifiche: gli stessi dei banner in-app (lib/features/plans).
// Funzioni pure, provate con `node --test supabase/functions/send-push/messages_test.mjs`.

export interface PushMessage {
  title: string;
  body: string;
  /** Rotta dentro l'app aperta al tocco (solo /plans...). */
  route: string;
}

export const UNNAMED_PLACE = "Punto sulla mappa";

export function subtitle(emoji: string, label: string, place: string | null): string {
  return `${emoji} ${label} · ${place ?? UNNAMED_PLACE}`;
}

export function planMessage(
  nickname: string,
  emoji: string,
  label: string,
  place: string | null,
  planId: string,
): PushMessage {
  return {
    title: `${nickname} ha lanciato un piano`,
    body: subtitle(emoji, label, place),
    route: `/plans/${planId}`,
  };
}

export function voteMessage(
  nickname: string,
  vote: "yes" | "no",
  emoji: string,
  label: string,
  place: string | null,
  planId: string,
): PushMessage {
  return {
    title: vote === "yes" ? `${nickname} ci sta 🙋` : `${nickname} non ci sta 😴`,
    body: subtitle(emoji, label, place),
    route: `/plans/${planId}`,
  };
}

/** Il piano non esiste più: si apre la lista. */
export function cancelMessage(
  nickname: string,
  emoji: string,
  label: string,
  place: string | null,
): PushMessage {
  return {
    title: `${nickname} ha annullato il piano`,
    body: subtitle(emoji, label, place),
    route: "/plans",
  };
}

/** Esito di una chiamata FCM: il token va eliminato solo se non esiste più. */
export type FcmOutcome = "sent" | "unregistered" | "error";

export function classifyFcmResponse(status: number, body: unknown): FcmOutcome {
  if (status >= 200 && status < 300) return "sent";
  const details = (body as { error?: { status?: string; details?: { errorCode?: string }[] } })
    ?.error;
  const code = details?.details?.find((d) => d.errorCode)?.errorCode;
  if (status === 404 || code === "UNREGISTERED" || details?.status === "NOT_FOUND") {
    return "unregistered";
  }
  return "error";
}

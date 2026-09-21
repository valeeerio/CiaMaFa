// node --test supabase/functions/send-push/messages_test.mjs
import assert from "node:assert/strict";
import { test } from "node:test";
import {
  cancelMessage,
  classifyFcmResponse,
  planMessage,
  subtitle,
  voteMessage,
} from "./messages.ts";

test("new plan: same text as the in-app banner, opens the plan", () => {
  assert.deepEqual(planMessage("Marco", "🍻", "Bar", "Pineta", "p1"), {
    title: "Marco ha lanciato un piano",
    body: "🍻 Bar · Pineta",
    route: "/plans/p1",
  });
});

test("a plan without place still reads well", () => {
  assert.equal(subtitle("🍻", "Bar", null), "🍻 Bar · Punto sulla mappa");
});

test("votes: yes / no wording, opens the plan", () => {
  assert.equal(voteMessage("Anna", "yes", "🍻", "Bar", "Pineta", "p1").title, "Anna ci sta 🙋");
  const no = voteMessage("Anna", "no", "🍻", "Bar", "Pineta", "p1");
  assert.equal(no.title, "Anna non ci sta 😴");
  assert.equal(no.route, "/plans/p1");
});

test("cancellation opens the list, never the deleted plan", () => {
  const m = cancelMessage("Marco", "🍻", "Bar", "Pineta");
  assert.equal(m.title, "Marco ha annullato il piano");
  assert.equal(m.route, "/plans");
});

test("every route stays inside /plans", () => {
  const routes = [
    planMessage("a", "x", "y", null, "p").route,
    voteMessage("a", "yes", "x", "y", null, "p").route,
    cancelMessage("a", "x", "y", null).route,
  ];
  for (const r of routes) assert.match(r, /^\/plans(\/|$)/);
});

test("FCM outcomes: only a dead token is removed", () => {
  assert.equal(classifyFcmResponse(200, { name: "x" }), "sent");
  assert.equal(
    classifyFcmResponse(404, { error: { status: "NOT_FOUND", details: [{ errorCode: "UNREGISTERED" }] } }),
    "unregistered",
  );
  assert.equal(
    classifyFcmResponse(400, { error: { status: "INVALID_ARGUMENT", details: [{ errorCode: "UNREGISTERED" }] } }),
    "unregistered",
  );
  assert.equal(classifyFcmResponse(500, { error: { status: "INTERNAL" } }), "error");
  assert.equal(classifyFcmResponse(401, null), "error");
  assert.equal(classifyFcmResponse(429, { error: { status: "QUOTA_EXCEEDED" } }), "error");
});

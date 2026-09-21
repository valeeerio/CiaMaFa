// node --test supabase/functions/cleanup-chat-images/cleanup_test.mjs
import assert from "node:assert/strict";
import { test } from "node:test";
import { batches, lastRomeMidnight, staleObjects } from "./cleanup.ts";

test("summer (CEST, UTC+2): midnight in Rome is 22:00 UTC of the day before", () => {
  const now = new Date("2026-07-15T10:30:00Z"); // 12:30 a Roma
  assert.equal(lastRomeMidnight(now).toISOString(), "2026-07-14T22:00:00.000Z");
});

test("winter (CET, UTC+1): midnight in Rome is 23:00 UTC of the day before", () => {
  const now = new Date("2026-01-15T10:30:00Z");
  assert.equal(lastRomeMidnight(now).toISOString(), "2026-01-14T23:00:00.000Z");
});

test("00:05 in Rome is already the new day", () => {
  const now = new Date("2026-09-21T22:05:00Z"); // 00:05 del 22 a Roma (CEST)
  assert.equal(lastRomeMidnight(now).toISOString(), "2026-09-21T22:00:00.000Z");
});

test("23:55 in Rome is still the old day", () => {
  const now = new Date("2026-09-21T21:55:00Z"); // 23:55 del 21 a Roma
  assert.equal(lastRomeMidnight(now).toISOString(), "2026-09-20T22:00:00.000Z");
});

test("DST change day (2026-03-29): midnight is still UTC+1", () => {
  const now = new Date("2026-03-29T12:00:00Z");
  assert.equal(lastRomeMidnight(now).toISOString(), "2026-03-28T23:00:00.000Z");
});

test("only objects created before the cutoff are stale", () => {
  const cutoff = new Date("2026-09-21T22:00:00Z");
  const objects = [
    { name: "old.jpg", created_at: "2026-09-21T21:59:59Z" },
    { name: "today.jpg", created_at: "2026-09-21T22:00:01Z" },
    { name: "nodate.jpg", created_at: null },
  ];
  assert.deepEqual(staleObjects("g", objects, cutoff), ["g/old.jpg"]);
});

test("batches split a list into chunks", () => {
  assert.deepEqual(batches([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  assert.deepEqual(batches([], 100), []);
});

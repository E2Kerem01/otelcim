// Loads functions/src/index.ts with every external dependency swapped for the
// in-memory fakes in ./fakes, and offers small helpers shared by the tests.
//
// No npm install: Node >= 22.18 strips TypeScript types natively and
// module.registerHooks lets us redirect the bare specifiers before resolution.

import assert from "node:assert/strict";
import {registerHooks} from "node:module";
import {afterEach, beforeEach} from "node:test";

const FAKE_RUNTIME = new URL("./fakes/runtime.mjs", import.meta.url).href;
const MOCKED_SPECIFIERS = new Set([
  "firebase-admin/app",
  "firebase-admin/firestore",
  "firebase-admin/messaging",
  "firebase-functions",
  "firebase-functions/params",
  "firebase-functions/v2/firestore",
  "firebase-functions/v2/https",
  "jsonwebtoken",
]);

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (MOCKED_SPECIFIERS.has(specifier)) {
      return {url: FAKE_RUNTIME, shortCircuit: true};
    }
    return nextResolve(specifier, context);
  },
});

const runtime = await import(FAKE_RUNTIME);
export const fns = await import(new URL("../../../src/index.ts", import.meta.url).href);
export const {state, HttpsError} = runtime;
export const db = state.db;

export const DAY_MS = 24 * 60 * 60 * 1000;

// --- bug tests ---------------------------------------------------------------
// Tests that document a confirmed defect assert the *correct* behaviour and
// are skipped so the suite stays green. `RUN_BUGS=1` un-skips them to prove
// they really fail against the current code.
export function bug(id, description) {
  return process.env.RUN_BUGS ? false : `BUG-t1-${id}: ${description}`;
}

// --- fetch -------------------------------------------------------------------
export const fetchCalls = [];
let fetchHandler = null;

globalThis.fetch = async (url, init = {}) => {
  fetchCalls.push({url: String(url), init});
  await new Promise((resolve) => setImmediate(resolve));
  if (!fetchHandler) throw new Error(`Unexpected network call in test: ${url}`);
  return fetchHandler(String(url), init);
};

export function onFetch(handler) {
  fetchHandler = handler;
}

export function json(status, body) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {"Content-Type": "application/json"},
  });
}

export const GOOGLE_OAUTH_URL = "https://oauth2.googleapis.com/token";
export const APPLE_PROD_URL = "https://buy.itunes.apple.com/verifyReceipt";
export const APPLE_SANDBOX_URL = "https://sandbox.itunes.apple.com/verifyReceipt";

export const VALID_SERVICE_ACCOUNT = JSON.stringify({
  client_email: "play-verifier@otelcim.iam.gserviceaccount.com",
  private_key: "-----BEGIN PRIVATE KEY-----\nfake\n-----END PRIVATE KEY-----\n",
});

export function configureGooglePlaySecrets() {
  state.secrets.PLAY_SERVICE_ACCOUNT_JSON = VALID_SERVICE_ACCOUNT;
  state.secrets.ANDROID_PACKAGE_NAME = "com.otelcim.app";
}

export function configureAppStoreSecret() {
  state.secrets.APPSTORE_SHARED_SECRET = "apple-shared-secret";
}

/**
 * Google Play happy-path network: OAuth returns a token, the Publisher API
 * returns `purchase` (by default a purchased order `GPA.0001`).
 */
export function googlePlayReturns(purchase = {purchaseState: 0, orderId: "GPA.0001"}) {
  configureGooglePlaySecrets();
  onFetch((url) => {
    if (url === GOOGLE_OAUTH_URL) return json(200, {access_token: "ya29.fake"});
    if (url.startsWith("https://androidpublisher.googleapis.com/")) return json(200, purchase);
    throw new Error(`Unexpected URL ${url}`);
  });
}

/** App Store network: production verifyReceipt returns `body`. */
export function appStoreReturns(body) {
  configureAppStoreSecret();
  onFetch((url) => {
    if (url === APPLE_PROD_URL) return json(200, body);
    throw new Error(`Unexpected URL ${url}`);
  });
}

// --- events / requests -------------------------------------------------------
export function createdEvent(params, data) {
  return {params, data: data === undefined ? undefined : {data: () => structuredClone(data)}};
}

export function updatedEvent(params, before, after) {
  return {
    params,
    data: {
      before: {data: () => (before === undefined ? undefined : structuredClone(before))},
      after: {data: () => (after === undefined ? undefined : structuredClone(after))},
    },
  };
}

export function callAs(uid, data) {
  return {auth: uid ? {uid, token: {}} : undefined, data};
}

/**
 * Profile fields for a quiet-hours window ("HH:mm", as NotificationSettingsScreen
 * stores them) that contains the current wall-clock time in Türkiye.
 */
export function quietWindowAroundNow() {
  const fmt = (offsetMs) =>
    new Intl.DateTimeFormat("en-GB", {
      timeZone: "Europe/Istanbul",
      hour: "2-digit",
      minute: "2-digit",
      hourCycle: "h23",
    }).format(new Date(Date.now() + offsetMs));
  return {quietHoursStart: fmt(-60 * 60 * 1000), quietHoursEnd: fmt(60 * 60 * 1000)};
}

/** Ids of the Android notification channels the Flutter client creates. */
export async function clientAndroidChannelIds() {
  const {readFile} = await import("node:fs/promises");
  const source = await readFile(
    new URL("../../../../lib/shared/services/notification_service.dart", import.meta.url),
    "utf8",
  );
  return [...source.matchAll(/AndroidNotificationChannel\(\s*'([^']+)'/g)].map((m) => m[1]);
}

// --- assertions --------------------------------------------------------------
export async function rejectsWithCode(promise, code, messagePattern) {
  await assert.rejects(promise, (error) => {
    assert.ok(error instanceof HttpsError, `expected HttpsError(${code}), got ${error?.constructor?.name}: ${error?.message}`);
    assert.equal(error.code, code, `unexpected HttpsError code (message: ${error.message})`);
    if (messagePattern) assert.match(error.message, messagePattern);
    return true;
  });
}

export function errorLogs() {
  return state.logs.filter((l) => l.level === "error");
}

// Every test starts from an empty world.
export function useFreshState() {
  beforeEach(() => {
    runtime.resetState();
    fetchCalls.length = 0;
    fetchHandler = null;
  });
  afterEach(() => {
    fetchHandler = null;
  });
}

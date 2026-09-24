// Single fake module that every Firebase / jsonwebtoken import of
// functions/src/index.ts is redirected to (see ../harness.mjs). It exports the
// union of the names index.ts imports and keeps all observable side effects in
// `state` so tests can assert on them.

import {FakeFirestore, FieldValue} from "./firestore.mjs";

export {FieldValue};

export const state = {
  db: new FakeFirestore(),
  sends: [],
  sendImpl: null,
  logs: [],
  secrets: {},
  jwtCalls: [],
};

export function resetState() {
  state.db.reset();
  state.sends = [];
  state.sendImpl = null;
  state.logs = [];
  state.secrets = {};
  state.jwtCalls = [];
}

// --- firebase-admin/app ----------------------------------------------------
export function initializeApp() {
  return {};
}

// --- firebase-admin/firestore ----------------------------------------------
export function getFirestore() {
  return state.db;
}

// --- firebase-admin/messaging ----------------------------------------------
export function getMessaging() {
  return {
    send: async (message) => {
      await new Promise((resolve) => setImmediate(resolve));
      if (state.sendImpl) await state.sendImpl(message);
      state.sends.push(message);
      return `projects/fake/messages/${state.sends.length}`;
    },
  };
}

// --- firebase-functions ----------------------------------------------------
export const logger = {
  info: (msg, ctx) => state.logs.push({level: "info", msg, ctx}),
  warn: (msg, ctx) => state.logs.push({level: "warn", msg, ctx}),
  error: (msg, ctx) => state.logs.push({level: "error", msg, ctx}),
};

// --- firebase-functions/params ---------------------------------------------
export function defineSecret(name) {
  return {name, value: () => state.secrets[name] ?? ""};
}

// --- firebase-functions/v2/firestore ---------------------------------------
export function onDocumentCreated(options, handler) {
  return {kind: "onDocumentCreated", options, run: handler};
}

export function onDocumentUpdated(options, handler) {
  return {kind: "onDocumentUpdated", options, run: handler};
}

// --- firebase-functions/v2/https -------------------------------------------
export class HttpsError extends Error {
  constructor(code, message, details) {
    super(message);
    this.code = code;
    this.details = details;
  }
}

export function onCall(options, handler) {
  return {kind: "onCall", options, run: handler};
}

// --- jsonwebtoken ----------------------------------------------------------
export function sign(payload, key, options) {
  state.jwtCalls.push({payload, key, options});
  return "fake.jwt.assertion";
}

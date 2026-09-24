// Minimal, dependency-free client for the Firestore + Storage emulators.
//
// It speaks the emulators' REST APIs directly (the same wire calls the
// Flutter SDK ends up making), so every write here is evaluated against the
// real firestore.rules / storage.rules by the real rules engine. Helpers
// mirror the Dart API shapes the app uses:
//   set()            -> DocumentReference.set(data)
//   set(merge:true)  -> DocumentReference.set(data, SetOptions(merge: true))
//   update()         -> DocumentReference.update(data)   (must exist)
//   create()         -> CollectionReference.add(data)    (must not exist)
//   commit()         -> WriteBatch.commit()
//   query()          -> Query.get()
import assert from 'node:assert/strict';

export const PROJECT = 'demo-otelcim';
export const BUCKET = `${PROJECT}.appspot.com`;
const FS = `http://${process.env.FIRESTORE_EMULATOR_HOST ?? '127.0.0.1:8181'}`;
const ST = `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9181'}`;
const DB_ROOT = `projects/${PROJECT}/databases/(default)/documents`;

/** FieldValue.serverTimestamp() */
export const SERVER_TIMESTAMP = Symbol('serverTimestamp');
/** FieldValue.delete() */
export const DELETE_FIELD = Symbol('deleteField');
/** Caller identity that bypasses rules, like the Admin SDK / Cloud Functions. */
export const ADMIN_SDK = Symbol('adminSdk');

/** Forces a Firestore double even for integral numbers (Dart `5.0`). */
export class Double {
  value: number;
  constructor(value: number) {
    this.value = value;
  }
}

export type Caller = string | null | typeof ADMIN_SDK;
export type Data = Record<string, unknown>;

export class RequestError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(`${status} ${code}: ${message}`);
    this.status = status;
    this.code = code;
  }
}

// ---------------------------------------------------------------------------
// Auth

function b64url(obj: unknown): string {
  return Buffer.from(JSON.stringify(obj)).toString('base64url');
}

/** Unsigned ID token, accepted by the emulators (same as rules-unit-testing). */
export function idToken(uid: string, claims: Data = {}): string {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    iat: now,
    exp: now + 3600,
    auth_time: now,
    sub: uid,
    user_id: uid,
    firebase: { sign_in_provider: 'password', identities: {} },
    ...claims,
  };
  return `${b64url({ alg: 'none', typ: 'JWT' })}.${b64url(payload)}.`;
}

function authHeader(caller: Caller, scheme: 'Bearer' | 'Firebase'): Record<string, string> {
  if (caller === null) return {};
  if (caller === ADMIN_SDK) return { Authorization: `${scheme} owner` };
  return { Authorization: `${scheme} ${idToken(caller)}` };
}

// ---------------------------------------------------------------------------
// Value encoding

function toValue(v: unknown): Data {
  if (v === null || v === undefined) return { nullValue: null };
  if (v instanceof Double) return { doubleValue: v.value };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  if (typeof v === 'object') return { mapValue: { fields: toFields(v as Data) } };
  throw new Error(`Unsupported value ${String(v)}`);
}

function toFields(data: Data): Data {
  const fields: Data = {};
  for (const [k, v] of Object.entries(data)) fields[k] = toValue(v);
  return fields;
}

function fromValue(v: Data): unknown {
  if ('nullValue' in v) return null;
  if ('booleanValue' in v) return v.booleanValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('doubleValue' in v) return v.doubleValue;
  if ('stringValue' in v) return v.stringValue;
  if ('timestampValue' in v) return new Date(v.timestampValue as string);
  if ('arrayValue' in v) return ((v.arrayValue as Data).values as Data[] | undefined ?? []).map(fromValue);
  if ('mapValue' in v) return fromFields(((v.mapValue as Data).fields ?? {}) as Data);
  if ('referenceValue' in v) return v.referenceValue;
  return v;
}

function fromFields(fields: Data): Data {
  const out: Data = {};
  for (const [k, v] of Object.entries(fields)) out[k] = fromValue(v as Data);
  return out;
}

// ---------------------------------------------------------------------------
// Firestore

export type Write = Data;

type WriteMode = { merge?: boolean; mask?: boolean; exists?: boolean };

function updateWrite(path: string, data: Data, mode: WriteMode): Write {
  const fields: Data = {};
  const maskPaths: string[] = [];
  const transforms: Data[] = [];
  for (const [k, v] of Object.entries(data)) {
    if (v === SERVER_TIMESTAMP) {
      transforms.push({ fieldPath: k, setToServerValue: 'REQUEST_TIME' });
    } else if (v === DELETE_FIELD) {
      maskPaths.push(k);
    } else {
      fields[k] = toValue(v);
      maskPaths.push(k);
    }
  }
  const write: Write = { update: { name: `${DB_ROOT}/${path}`, fields } };
  if (mode.merge || mode.mask) write.updateMask = { fieldPaths: maskPaths };
  if (transforms.length) write.updateTransforms = transforms;
  if (mode.exists !== undefined) write.currentDocument = { exists: mode.exists };
  return write;
}

/** Write builders for batches (WriteBatch.set / update / delete). */
export const w = {
  set: (path: string, data: Data, opts: { merge?: boolean } = {}): Write => updateWrite(path, data, opts),
  create: (path: string, data: Data): Write => updateWrite(path, data, { exists: false }),
  update: (path: string, data: Data): Write => updateWrite(path, data, { mask: true, exists: true }),
  delete: (path: string): Write => ({ delete: `${DB_ROOT}/${path}` }),
};

async function throwIfError(res: Response): Promise<unknown> {
  const text = await res.text();
  let body: unknown = null;
  try {
    body = text ? JSON.parse(text) : null;
  } catch {
    body = text;
  }
  const first = Array.isArray(body) ? body[0] : body;
  const err = (first as Data | null)?.error as Data | undefined;
  if (!res.ok || err) {
    throw new RequestError(res.status, String(err?.status ?? res.statusText), String(err?.message ?? text));
  }
  return body;
}

export type Filter = [field: string, op: '==' | '!=' | '<' | '<=' | '>' | '>=' | 'array-contains', value: unknown];
const OPS: Record<string, string> = {
  '==': 'EQUAL',
  '!=': 'NOT_EQUAL',
  '<': 'LESS_THAN',
  '<=': 'LESS_THAN_OR_EQUAL',
  '>': 'GREATER_THAN',
  '>=': 'GREATER_THAN_OR_EQUAL',
  'array-contains': 'ARRAY_CONTAINS',
};

export type QueryOpts = { orderBy?: [string, 'asc' | 'desc']; limit?: number };
export type QueryDoc = { id: string; path: string; data: Data };

export class Db {
  caller: Caller;
  constructor(caller: Caller) {
    this.caller = caller;
  }

  private headers(): Record<string, string> {
    return { 'Content-Type': 'application/json', ...authHeader(this.caller, 'Bearer') };
  }

  /** DocumentReference.get(); returns null when the doc does not exist. */
  async get(path: string): Promise<Data | null> {
    const res = await fetch(`${FS}/v1/${DB_ROOT}/${path}`, { headers: this.headers() });
    if (res.status === 404) {
      const body = (await res.json()) as Data;
      if (((body.error as Data | undefined)?.status) === 'NOT_FOUND') return null;
    }
    const doc = (await throwIfError(res)) as Data;
    return fromFields((doc.fields ?? {}) as Data);
  }

  async commit(writes: Write[]): Promise<void> {
    const res = await fetch(`${FS}/v1/${DB_ROOT}:commit`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({ writes }),
    });
    await throwIfError(res);
  }

  set(path: string, data: Data, opts: { merge?: boolean } = {}): Promise<void> {
    return this.commit([w.set(path, data, opts)]);
  }

  create(path: string, data: Data): Promise<void> {
    return this.commit([w.create(path, data)]);
  }

  update(path: string, data: Data): Promise<void> {
    return this.commit([w.update(path, data)]);
  }

  delete(path: string): Promise<void> {
    return this.commit([w.delete(path)]);
  }

  /** Query.get() on a (sub)collection path such as `reports` or `user_profiles/u1/talent_pool`. */
  async query(collectionPath: string, filters: Filter[] = [], opts: QueryOpts = {}): Promise<QueryDoc[]> {
    const segments = collectionPath.split('/');
    const collectionId = segments.pop() as string;
    const parent = segments.length ? `/${segments.join('/')}` : '';
    const structuredQuery: Data = { from: [{ collectionId }] };
    if (filters.length) {
      const fieldFilters = filters.map(([field, op, value]) => ({
        fieldFilter: { field: { fieldPath: field }, op: OPS[op], value: toValue(value) },
      }));
      structuredQuery.where =
        fieldFilters.length === 1 ? fieldFilters[0] : { compositeFilter: { op: 'AND', filters: fieldFilters } };
    }
    if (opts.orderBy) {
      structuredQuery.orderBy = [
        { field: { fieldPath: opts.orderBy[0] }, direction: opts.orderBy[1] === 'desc' ? 'DESCENDING' : 'ASCENDING' },
      ];
    }
    if (opts.limit !== undefined) structuredQuery.limit = opts.limit;
    const res = await fetch(`${FS}/v1/${DB_ROOT}${parent}:runQuery`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({ structuredQuery }),
    });
    const rows = (await throwIfError(res)) as Data[];
    return rows
      .filter((r) => r.document)
      .map((r) => {
        const doc = r.document as Data;
        const name = String(doc.name);
        const path = name.slice(name.indexOf('/documents/') + '/documents/'.length);
        return { id: path.split('/').pop() as string, path, data: fromFields((doc.fields ?? {}) as Data) };
      });
  }
}

export const db = (caller: Caller): Db => new Db(caller);
export const adminSdk = db(ADMIN_SDK);

export async function resetFirestore(): Promise<void> {
  const res = await fetch(`${FS}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`, {
    method: 'DELETE',
  });
  assert.ok(res.ok, `firestore reset failed: ${res.status}`);
}

// ---------------------------------------------------------------------------
// Storage (Firebase Storage REST API, as used by the client SDKs)

export async function upload(
  caller: Caller,
  path: string,
  opts: { contentType?: string; size?: number } = {},
): Promise<void> {
  const res = await fetch(`${ST}/v0/b/${BUCKET}/o?name=${encodeURIComponent(path)}`, {
    method: 'POST',
    headers: {
      'Content-Type': opts.contentType ?? 'image/jpeg',
      ...authHeader(caller, 'Firebase'),
    },
    body: Buffer.alloc(opts.size ?? 1024, 1),
  });
  await throwIfError(res);
}

export async function download(caller: Caller, path: string): Promise<void> {
  const res = await fetch(`${ST}/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media`, {
    headers: authHeader(caller, 'Firebase'),
  });
  if (!res.ok) throw new RequestError(res.status, res.statusText, await res.text());
  await res.arrayBuffer();
}

export async function deleteObject(caller: Caller, path: string): Promise<void> {
  const res = await fetch(`${ST}/v0/b/${BUCKET}/o/${encodeURIComponent(path)}`, {
    method: 'DELETE',
    headers: authHeader(caller, 'Firebase'),
  });
  if (!res.ok) throw new RequestError(res.status, res.statusText, await res.text());
}

// ---------------------------------------------------------------------------
// Assertions

/** The operation must be rejected by security rules (PERMISSION_DENIED / 403). */
export async function denied(op: Promise<unknown>, why = ''): Promise<void> {
  try {
    await op;
  } catch (e) {
    if (e instanceof RequestError && e.status === 403) return;
    throw e;
  }
  assert.fail(`expected permission-denied but the request was allowed${why ? ` (${why})` : ''}`);
}

/** The operation must succeed. */
export async function allowed<T>(op: Promise<T>): Promise<T> {
  return op;
}

/** Runs [op] and reports whether security rules allowed it. */
export async function isAllowed(op: Promise<unknown>): Promise<boolean> {
  try {
    await op;
    return true;
  } catch (e) {
    if (e instanceof RequestError && e.status === 403) return false;
    throw e;
  }
}

/**
 * Skip marker for tests that assert the CORRECT behaviour of a known bug.
 * `node run.mjs --bugs` un-skips them; they must fail there.
 */
export function bug(id: string, description: string): string | false {
  return process.env.T2_RUN_BUG_TESTS ? false : `${id}: ${description}`;
}

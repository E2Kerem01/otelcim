// Minimal in-memory stand-in for the parts of the firebase-admin Firestore API
// that functions/src/index.ts uses. Every read/commit yields to the event loop
// so that concurrent callers (Promise.all) genuinely interleave, like they do
// against the real backend. Transactions are serialized, which models the
// serializable isolation real Firestore guarantees for runTransaction.

const tick = () => new Promise((resolve) => setImmediate(resolve));

class IncrementSentinel {
  constructor(n) {
    this.n = n;
  }
}

export const FieldValue = {
  increment: (n) => new IncrementSentinel(n),
};

function clone(value) {
  if (value instanceof Date) return new Date(value.getTime());
  if (value instanceof IncrementSentinel) return value;
  if (Array.isArray(value)) return value.map(clone);
  if (value && typeof value === "object") {
    const out = {};
    for (const [k, v] of Object.entries(value)) out[k] = clone(v);
    return out;
  }
  return value;
}

function applyFields(target, fields) {
  const out = clone(target ?? {});
  for (const [k, v] of Object.entries(fields)) {
    if (v instanceof IncrementSentinel) {
      const current = out[k];
      out[k] = typeof current === "number" ? current + v.n : v.n;
    } else {
      out[k] = clone(v);
    }
  }
  return out;
}

export class FirestoreError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

class DocumentSnapshot {
  constructor(ref, data) {
    this.ref = ref;
    this.id = ref.id;
    this._data = data;
    this.exists = data !== undefined;
  }

  data() {
    return this._data === undefined ? undefined : clone(this._data);
  }
}

class QuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.size = docs.length;
    this.empty = docs.length === 0;
  }
}

class DocumentReference {
  constructor(db, path) {
    this._db = db;
    this.path = path;
    this.id = path.split("/").pop();
  }

  collection(name) {
    return new CollectionReference(this._db, `${this.path}/${name}`);
  }

  async get() {
    this._db.stats.reads += 1;
    await tick();
    return new DocumentSnapshot(this, this._db._read(this.path));
  }

  async set(data) {
    await tick();
    this._db._commit([{op: "set", path: this.path, data}]);
  }

  async update(data) {
    await tick();
    this._db._commit([{op: "update", path: this.path, data}]);
  }
}

class Query {
  constructor(db, path, filters = [], limitN = undefined) {
    this._db = db;
    this._path = path;
    this._filters = filters;
    this._limit = limitN;
  }

  where(field, op, value) {
    if (op !== "==") throw new Error(`fake Firestore: unsupported operator ${op}`);
    return new Query(this._db, this._path, [...this._filters, {field, value}], this._limit);
  }

  limit(n) {
    return new Query(this._db, this._path, this._filters, n);
  }

  async get() {
    this._db.stats.reads += 1;
    await tick();
    const prefix = `${this._path}/`;
    let docs = [];
    for (const [path, data] of this._db._docs) {
      if (!path.startsWith(prefix) || path.slice(prefix.length).includes("/")) continue;
      if (this._filters.every((f) => data[f.field] === f.value)) {
        docs.push(new DocumentSnapshot(new DocumentReference(this._db, path), clone(data)));
      }
    }
    if (this._limit !== undefined) docs = docs.slice(0, this._limit);
    return new QuerySnapshot(docs);
  }
}

class CollectionReference extends Query {
  constructor(db, path) {
    super(db, path);
    this.id = path.split("/").pop();
  }

  doc(id) {
    const docId = id ?? `auto_${++this._db._autoId}`;
    return new DocumentReference(this._db, `${this._path}/${docId}`);
  }
}

class WriteBatch {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }

  set(ref, data) {
    this._ops.push({op: "set", path: ref.path, data});
    return this;
  }

  update(ref, data) {
    this._ops.push({op: "update", path: ref.path, data});
    return this;
  }

  async commit() {
    await tick();
    this._db._commit(this._ops);
  }
}

class Transaction {
  constructor(db) {
    this._db = db;
    this._ops = [];
  }

  async get(ref) {
    return ref.get();
  }

  set(ref, data) {
    this._ops.push({op: "set", path: ref.path, data});
    return this;
  }

  update(ref, data) {
    this._ops.push({op: "update", path: ref.path, data});
    return this;
  }
}

export class FakeFirestore {
  constructor() {
    this.reset();
  }

  reset() {
    this._docs = new Map();
    this._autoId = 0;
    this._txQueue = Promise.resolve();
    // Optional hook: (op, path, data) => void. Throw from it to simulate a
    // failing write (network error, permission, contention...).
    this.beforeWrite = null;
    this.stats = {reads: 0, commits: 0};
  }

  collection(name) {
    return new CollectionReference(this, name);
  }

  doc(path) {
    return new DocumentReference(this, path);
  }

  batch() {
    return new WriteBatch(this);
  }

  runTransaction(fn) {
    const run = async () => {
      const tx = new Transaction(this);
      const result = await fn(tx);
      await tick();
      this._commit(tx._ops);
      return result;
    };
    const next = this._txQueue.then(run, run);
    this._txQueue = next.catch(() => undefined);
    return next;
  }

  // --- test helpers -------------------------------------------------------

  seed(path, data) {
    this._docs.set(path, clone(data));
  }

  read(path) {
    const data = this._read(path);
    return data === undefined ? undefined : clone(data);
  }

  list(collectionPath) {
    const prefix = `${collectionPath}/`;
    const out = [];
    for (const [path, data] of this._docs) {
      if (path.startsWith(prefix) && !path.slice(prefix.length).includes("/")) {
        out.push({id: path.slice(prefix.length), ...clone(data)});
      }
    }
    return out;
  }

  // --- internals ----------------------------------------------------------

  _read(path) {
    return this._docs.get(path);
  }

  // All-or-nothing, like a real batch/transaction commit.
  _commit(ops) {
    for (const {op, path, data} of ops) {
      if (this.beforeWrite) this.beforeWrite(op, path, data);
      if (op === "update" && !this._docs.has(path)) {
        throw new FirestoreError("not-found", `5 NOT_FOUND: No document to update: ${path}`);
      }
    }
    const staged = new Map(this._docs);
    for (const {op, path, data} of ops) {
      staged.set(path, op === "set" ? applyFields({}, data) : applyFields(staged.get(path), data));
    }
    this._docs = staged;
    this.stats.commits += 1;
  }
}

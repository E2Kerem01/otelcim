# t2 — firestore.rules / storage.rules tests

Two halves:

| Part | Runner | What it checks |
|---|---|---|
| `specs/*.spec.ts` | `node run.mjs` (Firestore + Storage emulators) | The real `firestore.rules` / `storage.rules`, driven with the exact reads/writes the Flutter services make |
| `client_payload_contract_test.dart` | `flutter test test/qa/t2_security_rules` | The Dart models still write the key sets in `fixtures/client_payload_keys.json`, which the JS payload builders (`lib/fixtures.ts`) are pinned to by `specs/payload_contract.spec.ts` |

## Running

```sh
node test/qa/t2_security_rules/run.mjs            # green run, BUG-t2-* tests skipped
node test/qa/t2_security_rules/run.mjs --bugs     # un-skips the BUG-t2-* tests; each one must FAIL
node test/qa/t2_security_rules/run.mjs storage    # only specs whose file name contains "storage"
C:\flutter\flutter\bin\flutter.bat test test/qa/t2_security_rules
```

Requirements (no npm install, zero dependencies): Node >= 22.6 (TypeScript type
stripping + `node:test`), an already-installed `firebase-tools` (found in the npx
cache or global npm; override with `FIREBASE_TOOLS_JS`), a JDK >= 21 (override
with `T2_JAVA_HOME`), and the emulator jars already in `~/.cache/firebase/emulators`.
Ports: Firestore 8181, Storage 9181, hub 4181, logging 4581.

`run.mjs` copies the repo's `firestore.rules` / `storage.rules` into `.rules/`
(gitignored) on every run, because firebase-tools refuses rules files outside the
directory holding `firebase.json`.

## Conventions

- `denied(op)` = the rules reject the call (HTTP 403); `allowed(op)` = it succeeds.
- A test that asserts the *correct* behaviour of a known bug is marked
  `{ skip: bug('BUG-t2-NN', '...') }`. Details per ID are in `FINDINGS.md`.
- `adminSdk` bypasses rules (like Cloud Functions) and is only used for seeding
  and for checking results.

# Firestore & Storage security rules tests

Positive/negative emulator tests for `firestore.rules` and `storage.rules`, using `@firebase/rules-unit-testing` + Vitest. Runs in CI on every PR that touches either rules file (see `.github/workflows/rules_tests.yml`).

## Run locally

```bash
npm --prefix rules-tests ci
firebase emulators:exec --only firestore,storage --project otelcim-7f0ba "npm --prefix rules-tests test"
```

Requires the Firebase CLI (`npm i -g firebase-tools`). The `--project` flag must match `.firebaserc`'s default project — the Storage emulator's cross-service `firestore.get()` calls (used by `isAdmin()` in `storage.rules`) resolve against that project, so a mismatched or arbitrary test project id makes those calls always miss and deny.

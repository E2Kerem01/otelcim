import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import {
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { ref, uploadBytes } from 'firebase/storage';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Must match the real project id (.firebaserc) rather than an arbitrary
// name: the Storage emulator's cross-service firestore.get() calls (used by
// isAdmin() in storage.rules) resolve against the project the emulator
// suite was started for, so a mismatched test project id here makes those
// calls always miss and deny, even with singleProjectMode.
const PROJECT_ID = 'otelcim-7f0ba';

export function makeTestEnv(): Promise<RulesTestEnvironment> {
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
    storage: {
      rules: readFileSync(resolve(__dirname, '../storage.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 9199,
    },
  });
}

type SeedFn = Parameters<RulesTestEnvironment['withSecurityRulesDisabled']>[0];

// Seeds fixture data as an admin, bypassing security rules.
export async function seed(testEnv: RulesTestEnvironment, fn: SeedFn): Promise<void> {
  await testEnv.withSecurityRulesDisabled(fn);
}

const WARMUP_BYTES = new Uint8Array([1]);

// The Storage emulator's rules runtime (a separate JVM, downloaded and
// started lazily) can still be finishing initialization for a moment after
// initializeTestEnvironment() resolves. A real rule-evaluated request in
// that window can spuriously fail even though the rule itself is correct.
// Retry a representative write until it settles, so that doesn't leak into
// the real assertions below.
export async function warmUpRulesRuntime(testEnv: RulesTestEnvironment, timeoutMs = 20_000): Promise<void> {
  const deadline = Date.now() + timeoutMs;
  let lastError: unknown;
  while (Date.now() < deadline) {
    try {
      await uploadBytes(
        ref(testEnv.authenticatedContext('_warmup').storage(), 'profile_photos/_warmup/ping.jpg'),
        WARMUP_BYTES,
        { contentType: 'image/jpeg' },
      );
      await testEnv.clearStorage();
      return;
    } catch (error) {
      lastError = error;
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }
  throw lastError;
}

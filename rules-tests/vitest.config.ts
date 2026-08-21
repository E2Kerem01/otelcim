import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // firestore.test.ts and storage.test.ts each open their own
    // RulesTestEnvironment against the same shared emulator project, and
    // each file's afterEach calls clearFirestore()/clearStorage() globally
    // for that project. Running files in parallel (vitest's default) lets
    // one file's clear wipe data the other file just seeded mid-test.
    fileParallelism: false,
  },
});

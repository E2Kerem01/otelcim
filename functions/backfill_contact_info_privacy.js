// ONE-TIME maintenance script. Moves any legacy top-level `contactInfo`
// field still sitting on public `listings/{id}` docs (from before the
// contactInfo-privacy migration - see listing_service.dart) into the
// sign-in-gated `listings/{id}/private/contact` subdoc, then deletes it
// from the public doc.
//
// listing_service.dart's updateListing() already does this cleanup on
// every edit, so this script only matters for listings nobody has
// touched since the migration shipped - it closes the leak immediately
// instead of waiting for owners to happen to edit their listing.
//
// Safe to re-run: only touches docs that still have a top-level
// contactInfo field, so already-migrated listings are skipped untouched.
//
// Usage:
//   node backfill_contact_info_privacy.js                   # dry run (default) - scans + reports only, no writes
//   node backfill_contact_info_privacy.js --apply            # actually writes, against PRODUCTION
//   FIRESTORE_EMULATOR_HOST=localhost:8080 node backfill_contact_info_privacy.js --apply   # test against local emulator first (recommended)
//
// Running --apply against production requires credentials beyond `firebase
// login` - either `gcloud auth application-default login`, or point
// GOOGLE_APPLICATION_CREDENTIALS at a service account key with Firestore
// access.

const admin = require('firebase-admin');

const PROJECT_ID = 'otelcim-7f0ba';
const APPLY = process.argv.includes('--apply');
const PAGE_SIZE = 500;
const BATCH_SIZE = 200; // listings per commit; up to 2 writes each (delete + set) stays under the 500-op batch limit

admin.initializeApp({ projectId: PROJECT_ID });
const db = admin.firestore();

async function main() {
  const usingEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
  console.log(`Target: ${usingEmulator ? `EMULATOR (${process.env.FIRESTORE_EMULATOR_HOST})` : `PRODUCTION project "${PROJECT_ID}"`}`);
  console.log(`Mode: ${APPLY ? 'APPLY (will write)' : 'DRY RUN (no writes - pass --apply to write)'}`);

  if (APPLY && !usingEmulator) {
    console.log('Writing to PRODUCTION in 5s - Ctrl+C now to abort...');
    await new Promise((resolve) => setTimeout(resolve, 5000));
  }

  let scanned = 0;
  let migrated = 0;
  let cleanupOnly = 0;
  let lastDoc = null;
  let pending = [];

  async function flush() {
    if (pending.length === 0) return;
    if (APPLY) {
      const batch = db.batch();
      for (const op of pending) op(batch);
      await batch.commit();
    }
    pending = [];
  }

  while (true) {
    let query = db.collection('listings').orderBy('__name__').limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snap = await query.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data();
      if (!Object.prototype.hasOwnProperty.call(data, 'contactInfo')) continue;

      const legacyValue = data.contactInfo;
      const privateRef = doc.ref.collection('private').doc('contact');
      const privateSnap = await privateRef.get();

      if (privateSnap.exists) {
        // Already migrated by an edit at some point - just strip the stale
        // public field, don't overwrite the (possibly newer) private value.
        cleanupOnly++;
        console.log(`[cleanup-only] ${doc.id}: private/contact already exists, deleting stale public field`);
        pending.push((batch) => batch.update(doc.ref, { contactInfo: admin.firestore.FieldValue.delete() }));
      } else {
        migrated++;
        console.log(`[migrate] ${doc.id}: moving contactInfo -> private/contact`);
        pending.push((batch) => {
          batch.set(privateRef, { value: legacyValue });
          batch.update(doc.ref, { contactInfo: admin.firestore.FieldValue.delete() });
        });
      }

      if (pending.length >= BATCH_SIZE) await flush();
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    if (snap.docs.length < PAGE_SIZE) break;
  }

  await flush();

  console.log('---');
  console.log(`Scanned: ${scanned}`);
  console.log(`Migrated (contactInfo moved to private/contact): ${migrated}`);
  console.log(`Cleanup-only (private/contact already existed): ${cleanupOnly}`);
  console.log(`Already clean (no legacy field): ${scanned - migrated - cleanupOnly}`);
  if (!APPLY) console.log('\nThis was a DRY RUN - no writes made. Re-run with --apply to write.');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });

// Catch-all `match /{document=**}` deny + the admin-only collections.
import { beforeEach, describe, test } from 'node:test';
import { adminSdk, allowed, db, denied, resetFirestore } from '../lib/emulator.ts';
import { ADMIN, ALICE, BOB, seedUsers } from '../lib/fixtures.ts';

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
});

describe('default deny', () => {
  test('an unknown top-level collection is neither readable nor writable, even for an admin', async () => {
    await adminSdk.set('unknown_collection/x', { a: 1 });
    await denied(db(ALICE).get('unknown_collection/x'));
    await denied(db(ALICE).set('unknown_collection/y', { a: 1 }));
    await denied(db(ADMIN).set('unknown_collection/y', { a: 1 }));
  });

  test('an unknown subcollection under a readable doc stays denied', async () => {
    await denied(db(ALICE).set(`user_profiles/${ALICE}/notes/n1`, { text: 'x' }));
  });

  test('anonymous callers cannot write anywhere that requires auth', async () => {
    await denied(db(null).set('listings/anon', { posterId: '' }));
    await denied(db(null).create('reports/anon', { reporterId: null }));
  });
});

describe('admin-only collections', () => {
  test('admin_audit_log: admin may read/write, a regular user may not', async () => {
    await allowed(db(ADMIN).set('admin_audit_log/a1', { adminId: ADMIN, action: 'banUser' }));
    await allowed(db(ADMIN).get('admin_audit_log/a1'));
    await denied(db(BOB).get('admin_audit_log/a1'));
    await denied(db(BOB).set('admin_audit_log/a2', { adminId: BOB, action: 'banUser' }));
  });

  test('banner_ads: public read, admin-only write', async () => {
    await allowed(db(ADMIN).set('banner_ads/b1', { title: 'Sponsor', isActive: true, order: 1 }));
    await allowed(db(null).get('banner_ads/b1'));
    await denied(db(ALICE).set('banner_ads/b2', { title: 'Self-promo', isActive: true, order: 0 }));
    await denied(db(ALICE).update('banner_ads/b1', { isActive: false }));
    await denied(db(ALICE).delete('banner_ads/b1'));
  });

  test('legacy users/{uid}: owner only', async () => {
    await allowed(db(BOB).set(`users/${BOB}`, { legacy: true }));
    await denied(db(ALICE).get(`users/${BOB}`));
    await allowed(db(ADMIN).get(`users/${BOB}`));
    await denied(db(ADMIN).set(`users/${BOB}`, { legacy: false }));
  });
});

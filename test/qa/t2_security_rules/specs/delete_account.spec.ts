// AuthService.deleteAccount replayed step by step, in the same order and
// with the same queries, against the real rules. Each step is its own test
// so the report shows exactly which parts of the cascade work in production.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { adminSdk, allowed, bug, db, resetFirestore } from '../lib/emulator.ts';
import type { Db } from '../lib/emulator.ts';
import {
  ALICE,
  BOB,
  certificatePayload,
  conversationPayload,
  interviewSlotPayload,
  ratingPayload,
  reportPayload,
  seedListing,
  seedUsers,
  verificationPayload,
} from '../lib/fixtures.ts';

const CONVO_AS_POSTER = `listing1_${BOB}`;
const CONVO_AS_SEEKER = `bobs_listing_${ALICE}`;

/** Alice's full footprint across every collection the app writes. */
async function seedAliceFootprint(): Promise<void> {
  await seedListing('listing1');
  await adminSdk.set('reports/r1', reportPayload(ALICE, 'some_listing', { createdAt: new Date() }));
  await adminSdk.set('boosts/b1', { userId: ALICE, listingId: 'listing1', status: 'active' });
  await adminSdk.set('boost_purchases/p1', { userId: ALICE, listingId: 'listing1', price: 49.99 });
  await adminSdk.set('verification_requests/v1', verificationPayload(ALICE));
  const now = { createdAt: new Date(), updatedAt: new Date() };
  await adminSdk.set(`conversations/${CONVO_AS_POSTER}`, conversationPayload('listing1', ALICE, BOB, now));
  await adminSdk.set(`conversations/${CONVO_AS_POSTER}/messages/m1`, { senderId: ALICE, text: 'Merhaba', sentAt: new Date() });
  await adminSdk.set(`conversations/${CONVO_AS_POSTER}/interview_slots/s1`, interviewSlotPayload(ALICE));
  await adminSdk.set(`conversations/${CONVO_AS_SEEKER}`, conversationPayload('bobs_listing', BOB, ALICE, now));
  await adminSdk.set(`conversations/${CONVO_AS_SEEKER}/messages/m1`, { senderId: ALICE, text: 'Selam', sentAt: new Date() });
  // Not touched by deleteAccount at all:
  await adminSdk.set(`user_profiles/${ALICE}/favorites/listing9`, { listingId: 'listing9' });
  await adminSdk.set(`user_profiles/${ALICE}/seasonal_subscriptions/s1`, { userId: ALICE, enabled: true });
  await adminSdk.set('seasonal_subscriptions/s1', { userId: ALICE, enabled: true, subscriptionId: 's1' });
  await adminSdk.set(`user_profiles/${ALICE}/talent_pool/${BOB}`, { candidateId: BOB, candidateName: 'Bob' });
  await adminSdk.set('certificates/c1', certificatePayload(ALICE));
  await adminSdk.set(`ratings/${CONVO_AS_POSTER}_${ALICE}`, ratingPayload(ALICE, BOB, CONVO_AS_POSTER, { createdAt: new Date() }));
}

/** `for (doc in query) await doc.reference.delete()` */
async function deleteAll(alice: Db, collection: string, field: string): Promise<void> {
  for (const doc of await alice.query(collection, [[field, '==', ALICE]])) await alice.delete(doc.path);
}

async function deleteConversations(alice: Db): Promise<void> {
  const convs = [
    ...(await alice.query('conversations', [['posterId', '==', ALICE]])),
    ...(await alice.query('conversations', [['seekerId', '==', ALICE]])),
  ];
  for (const conv of convs) {
    for (const msg of await alice.query(`${conv.path}/messages`)) await alice.delete(msg.path);
    await alice.delete(conv.path);
  }
}

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
  await seedAliceFootprint();
});

describe('AuthService.deleteAccount cascade (as the signed-in user, in app order)', () => {
  const alice = db(ALICE);

  test('step 1: the user can delete their own user_profiles doc', async () => {
    await allowed(alice.delete(`user_profiles/${ALICE}`));
    assert.equal(await adminSdk.get(`user_profiles/${ALICE}`), null);
  });

  test('step 2: the user can find and delete their listings (after step 1)', async () => {
    await alice.delete(`user_profiles/${ALICE}`);
    await allowed(deleteAll(alice, 'listings', 'posterId'));
    assert.equal(await adminSdk.get('listings/listing1'), null);
  });

  test(
    'step 3: the user can find and delete the reports they filed',
    { skip: bug('BUG-t2-27', 'reports: query is admin-only and there is no delete rule') },
    async () => {
      await allowed(deleteAll(alice, 'reports', 'reporterId'));
    },
  );

  test(
    'step 4: the user can delete their boosts and boost_purchases',
    { skip: bug('BUG-t2-27', 'boosts / boost_purchases: "allow write: if false" also blocks delete') },
    async () => {
      await allowed(deleteAll(alice, 'boosts', 'userId'));
      await allowed(deleteAll(alice, 'boost_purchases', 'userId'));
    },
  );

  test(
    'step 5: the user can delete their verification requests',
    { skip: bug('BUG-t2-27', 'verification_requests has no delete rule') },
    async () => {
      await allowed(deleteAll(alice, 'verification_requests', 'employerId'));
    },
  );

  test(
    'step 6: the user can delete their conversations and messages',
    { skip: bug('BUG-t2-27', 'conversations / messages have no delete rule') },
    async () => {
      await allowed(deleteConversations(alice));
    },
  );

  test(
    'after the whole cascade (errors swallowed like the app) no personal data is left behind',
    { skip: bug('BUG-t2-27', 'most steps are denied and favorites, seasonal subs, talent_pool, certificates, ratings, interview_slots and listing contact subdocs are never attempted') },
    async () => {
      const steps: Array<() => Promise<void>> = [
        () => alice.delete(`user_profiles/${ALICE}`),
        () => deleteAll(alice, 'listings', 'posterId'),
        () => deleteAll(alice, 'reports', 'reporterId'),
        async () => {
          await deleteAll(alice, 'boosts', 'userId');
          await deleteAll(alice, 'boost_purchases', 'userId');
        },
        () => deleteAll(alice, 'verification_requests', 'employerId'),
        () => deleteConversations(alice),
      ];
      for (const step of steps) {
        try {
          await step();
        } catch {
          // AuthService.deleteAccount logs and continues
        }
      }
      const leftovers: string[] = [];
      for (const path of [
        'listings/listing1/private/contact',
        'reports/r1',
        'boosts/b1',
        'boost_purchases/p1',
        'verification_requests/v1',
        `conversations/${CONVO_AS_POSTER}`,
        `conversations/${CONVO_AS_POSTER}/messages/m1`,
        `conversations/${CONVO_AS_POSTER}/interview_slots/s1`,
        `conversations/${CONVO_AS_SEEKER}`,
        `conversations/${CONVO_AS_SEEKER}/messages/m1`,
        `user_profiles/${ALICE}/favorites/listing9`,
        `user_profiles/${ALICE}/seasonal_subscriptions/s1`,
        'seasonal_subscriptions/s1',
        `user_profiles/${ALICE}/talent_pool/${BOB}`,
        'certificates/c1',
        `ratings/${CONVO_AS_POSTER}_${ALICE}`,
      ]) {
        if ((await adminSdk.get(path)) !== null) leftovers.push(path);
      }
      assert.deepEqual(leftovers, []);
    },
  );
});

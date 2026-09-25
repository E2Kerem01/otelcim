// firestore.rules: match /user_profiles/{userId} (+ favorites,
// seasonal_subscriptions, talent_pool subcollections), exercised with the
// exact payloads ProfileService / NotificationService / FavoriteService /
// SeasonalService / TalentPoolService send.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import {
  adminSdk,
  allowed,
  bug,
  db,
  DELETE_FIELD,
  denied,
  resetFirestore,
  SERVER_TIMESTAMP,
  w,
} from '../lib/emulator.ts';
import { ADMIN, ALICE, BOB, EVE, profilePayload, seedUsers } from '../lib/fixtures.ts';

const FUTURE = new Date('2027-01-01T00:00:00Z');

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
});

describe('user_profiles: legitimate client flows keep working', () => {
  test('ProfileService.createUserProfile (set merge) on a brand-new uid is allowed', async () => {
    const uid = 'new_user';
    await allowed(db(uid).set(`user_profiles/${uid}`, profilePayload(uid), { merge: true }));
    const saved = await adminSdk.get(`user_profiles/${uid}`);
    assert.equal(saved?.email, `${uid}@example.com`);
  });

  test('createUserProfile merging onto an fcmToken-only stub (registration race) is allowed', async () => {
    const uid = 'racing_user';
    await allowed(
      db(uid).set(`user_profiles/${uid}`, { fcmToken: 'tok', fcmTokenUpdatedAt: SERVER_TIMESTAMP }, { merge: true }),
    );
    await allowed(db(uid).set(`user_profiles/${uid}`, profilePayload(uid), { merge: true }));
    const saved = await adminSdk.get(`user_profiles/${uid}`);
    assert.equal(saved?.fcmToken, 'tok', 'the earlier token must survive the merge');
  });

  test('ProfileService.updateUserProfile with the full toFirestore() payload is allowed for the owner', async () => {
    await allowed(
      db(BOB).update(`user_profiles/${BOB}`, profilePayload(BOB, { bio: 'Deneyimli garson', displayName: 'بوب' })),
    );
    assert.equal((await adminSdk.get(`user_profiles/${BOB}`))?.displayName, 'بوب');
  });

  test('an already verified employer can still edit their profile (isVerified unchanged)', async () => {
    await adminSdk.update(`user_profiles/${ALICE}`, { isVerified: true, verificationStatus: 'approved' });
    await allowed(
      db(ALICE).update(
        `user_profiles/${ALICE}`,
        profilePayload(ALICE, { userType: 'employer', isVerified: true, verificationStatus: 'approved', bio: 'Yeni' }),
      ),
    );
  });

  test('a user cannot create or update somebody else\'s profile', async () => {
    await denied(db(EVE).set('user_profiles/someone_else', profilePayload('someone_else')));
    await denied(db(EVE).update(`user_profiles/${BOB}`, { displayName: 'hacked' }));
    await denied(db(null).update(`user_profiles/${BOB}`, { displayName: 'hacked' }));
  });

  test('an admin can moderate another user\'s profile (ban/suspend)', async () => {
    await allowed(db(ADMIN).update(`user_profiles/${EVE}`, { isBanned: true, banReason: 'spam' }));
    await allowed(db(ADMIN).update(`user_profiles/${EVE}`, { isSuspended: true, suspensionEnd: FUTURE }));
  });

  test('an admin cannot moderate their own profile', async () => {
    await denied(db(ADMIN).update(`user_profiles/${ADMIN}`, { isBanned: true, banReason: 'self ban' }));
    await denied(db(ADMIN).update(`user_profiles/${ADMIN}`, { isSuspended: true, suspensionEnd: FUTURE }));
  });
});

describe('user_profiles: isAdmin and referral/boost counters (already protected)', () => {
  test('an admin cannot demote themselves but can demote another admin', async () => {
    await adminSdk.set(
      'user_profiles/other_admin',
      profilePayload('other_admin', { isAdmin: true, adminRole: 'contentModerator' }),
    );

    await denied(db(ADMIN).update(`user_profiles/${ADMIN}`, { isAdmin: false, adminRole: null }));
    await allowed(db(ADMIN).update('user_profiles/other_admin', { isAdmin: false, adminRole: null }));
  });

  test('creating a profile with isAdmin:true is denied, isAdmin:false is allowed', async () => {
    await denied(db('u_admin_try').set('user_profiles/u_admin_try', profilePayload('u_admin_try', { isAdmin: true })));
    await allowed(db('u_plain').set('user_profiles/u_plain', profilePayload('u_plain', { isAdmin: false })));
  });

  for (const [field, value] of [
    ['isAdmin', true],
    ['freeBoostCredits', 999],
    ['referralCount', 50],
    ['referralRewardGranted', false],
    ['hasUsedFreeUrgentListing', false],
  ] as const) {
    test(`the owner cannot change ${field} on update`, async () => {
      await adminSdk.update(`user_profiles/${ALICE}`, { referralRewardGranted: true, hasUsedFreeUrgentListing: true });
      await denied(db(ALICE).update(`user_profiles/${ALICE}`, { [field]: value }));
    });
  }

  test('the owner cannot sneak a counter change in via set(merge:true) either', async () => {
    await denied(db(ALICE).set(`user_profiles/${ALICE}`, { freeBoostCredits: 5 }, { merge: true }));
  });
});

describe('user_profiles: moderation / trust fields the owner can still rewrite', () => {
  const moderationFields: Array<[string, unknown, Record<string, unknown>]> = [
    ['isBanned', false, { isBanned: true, banReason: 'dolandırıcılık' }],
    ['isSuspended', false, { isSuspended: true, suspensionEnd: FUTURE }],
    ['suspensionEnd', new Date('2020-01-01T00:00:00Z'), { isSuspended: true, suspensionEnd: FUTURE }],
    ['warnings', [], { warnings: [{ reason: 'spam', adminId: ADMIN }] }],
  ];
  for (const [field, value, seeded] of moderationFields) {
    test(
      `a moderated user cannot rewrite ${field} to escape moderation`,
      { skip: bug('BUG-t2-01', `owner can rewrite ${field}; rules only guard isAdmin + referral/boost counters`) },
      async () => {
        await adminSdk.update(`user_profiles/${EVE}`, seeded);
        await denied(db(EVE).update(`user_profiles/${EVE}`, { [field]: value }));
      },
    );
  }

  const trustFields: Array<[string, unknown]> = [
    ['isVerified', true],
    ['verificationStatus', 'approved'],
    ['verifiedAt', new Date('2026-09-01T00:00:00Z')],
  ];
  for (const [field, value] of trustFields) {
    test(
      `an unverified employer cannot grant themselves the verified badge via ${field}`,
      { skip: bug('BUG-t2-02', `owner can write ${field}; verified badge is self-service`) },
      async () => {
        await denied(db(ALICE).update(`user_profiles/${ALICE}`, { [field]: value }));
      },
    );
  }

  test(
    'referredBy cannot be rewritten after registration (e.g. set to self for a self-referral reward)',
    { skip: bug('BUG-t2-05', 'referredBy is not server-controlled; self-referral / late referral possible') },
    async () => {
      await denied(db(EVE).update(`user_profiles/${EVE}`, { referredBy: EVE }));
      await denied(db(EVE).update(`user_profiles/${EVE}`, { referredBy: ALICE }));
    },
  );
});

describe('user_profiles: create accepts server-controlled fields', () => {
  const createFields: Array<[string, unknown]> = [
    ['freeBoostCredits', 999],
    ['referralCount', 100],
    ['referralRewardGranted', true],
    ['hasUsedFreeUrgentListing', false],
    ['isVerified', true],
    ['verificationStatus', 'approved'],
  ];
  for (const [field, value] of createFields) {
    test(
      `a new profile cannot be created with ${field}=${JSON.stringify(value)}`,
      { skip: bug('BUG-t2-03', `create only checks isAdmin; ${field} can be forged at creation`) },
      async () => {
        const uid = `forger_${field}`;
        await denied(db(uid).set(`user_profiles/${uid}`, profilePayload(uid, { [field]: value })));
      },
    );
  }

  test(
    'deleting and re-creating one\'s profile does not reset the free-urgent slot, referral flag or a ban',
    { skip: bug('BUG-t2-04', 'owner may delete own profile and re-create it clean') },
    async () => {
      await adminSdk.update(`user_profiles/${EVE}`, {
        hasUsedFreeUrgentListing: true,
        referralRewardGranted: true,
        isBanned: true,
      });
      // Attempt the reset; either step being denied is an acceptable fix.
      try {
        await db(EVE).delete(`user_profiles/${EVE}`);
        await db(EVE).set(`user_profiles/${EVE}`, profilePayload(EVE));
      } catch {
        // denied - fine
      }
      const after = await adminSdk.get(`user_profiles/${EVE}`);
      assert.equal(after?.hasUsedFreeUrgentListing, true);
      assert.equal(after?.referralRewardGranted, true);
      assert.equal(after?.isBanned, true);
    },
  );
});

describe('user_profiles: privacy', () => {
  test('anyone (even anonymous) can read public profile fields shown on listings/chat', async () => {
    const profile = await allowed(db(null).get(`user_profiles/${ALICE}`));
    assert.equal(profile?.hotelName, 'Otel Deniz');
  });

  test(
    'an anonymous caller cannot read another user\'s email, phone number or FCM token',
    { skip: bug('BUG-t2-06', 'user_profiles is world-readable and holds email/phoneNumber/fcmToken (KVKK)') },
    async () => {
      let profile: Record<string, unknown> | null = null;
      try {
        profile = await db(null).get(`user_profiles/${BOB}`);
      } catch {
        return; // read denied entirely - acceptable
      }
      assert.equal(profile?.email, undefined);
      assert.equal(profile?.phoneNumber, undefined);
      assert.equal(profile?.fcmToken, undefined);
    },
  );
});

describe('user_profiles: FCM token lifecycle (NotificationService.setCurrentUser)', () => {
  const clearFcmToken = { fcmToken: DELETE_FIELD, fcmTokenUpdatedAt: SERVER_TIMESTAMP };

  test('clearFcmToken works while the owner is still signed in', async () => {
    await allowed(db(BOB).set(`user_profiles/${BOB}`, clearFcmToken, { merge: true }));
    assert.equal((await adminSdk.get(`user_profiles/${BOB}`))?.fcmToken, undefined);
  });

  test(
    'after sign-out the previous user\'s device token is removed from their profile',
    { skip: bug('BUG-t2-07', 'setCurrentUser(null) runs after signOut, so clearFcmToken is an anonymous write and is denied') },
    async () => {
      // main.dart: authStateProvider emits null -> setCurrentUser(null) ->
      // clearFcmToken(previousUid) with no signed-in user.
      try {
        await db(null).set(`user_profiles/${BOB}`, clearFcmToken, { merge: true });
      } catch {
        // swallowed by setCurrentUser's catch, just like in the app
      }
      assert.equal((await adminSdk.get(`user_profiles/${BOB}`))?.fcmToken, undefined);
    },
  );

  test(
    'when another account signs in on the same device, the previous account stops receiving its pushes',
    { skip: bug('BUG-t2-07', 'clearFcmToken(previousUid) runs as the NEW user and is denied; both profiles hold the device token') },
    async () => {
      try {
        await db(EVE).set(`user_profiles/${BOB}`, clearFcmToken, { merge: true });
      } catch {
        // swallowed in the app
      }
      await db(EVE).set(`user_profiles/${EVE}`, { fcmToken: 'bob-device-token', fcmTokenUpdatedAt: SERVER_TIMESTAMP }, { merge: true });
      assert.notEqual((await adminSdk.get(`user_profiles/${BOB}`))?.fcmToken, 'bob-device-token');
    },
  );
});

describe('user_profiles subcollections', () => {
  test('favorites: FavoriteService.toggleFavorite works for the owner only', async () => {
    const path = `user_profiles/${BOB}/favorites/listing1`;
    await allowed(db(BOB).set(path, { listingId: 'listing1', addedAt: SERVER_TIMESTAMP }));
    await allowed(db(BOB).query(`user_profiles/${BOB}/favorites`));
    await denied(db(EVE).get(path));
    await denied(db(EVE).set(`user_profiles/${BOB}/favorites/listing2`, { listingId: 'listing2' }));
    await denied(db(null).query(`user_profiles/${BOB}/favorites`));
    await allowed(db(BOB).delete(path));
  });

  test('seasonal_subscriptions: SeasonalService.addSubscription batch (nested + flat mirror) works for the owner', async () => {
    const sub = { userId: BOB, city: 'Muğla', category: null, season: 'yaz_2027', enabled: true, createdAt: SERVER_TIMESTAMP };
    await allowed(
      db(BOB).commit([
        w.set(`user_profiles/${BOB}/seasonal_subscriptions/s1`, sub),
        w.set('seasonal_subscriptions/s1', { ...sub, subscriptionId: 's1' }),
      ]),
    );
    // toggleSubscription + deleteSubscription batches
    await allowed(
      db(BOB).commit([
        w.update(`user_profiles/${BOB}/seasonal_subscriptions/s1`, { enabled: false }),
        w.update('seasonal_subscriptions/s1', { enabled: false }),
      ]),
    );
    await denied(db(EVE).get(`user_profiles/${BOB}/seasonal_subscriptions/s1`));
    await denied(db(EVE).get('seasonal_subscriptions/s1'));
    await denied(db(EVE).update('seasonal_subscriptions/s1', { enabled: true }));
    await allowed(
      db(BOB).commit([w.delete(`user_profiles/${BOB}/seasonal_subscriptions/s1`), w.delete('seasonal_subscriptions/s1')]),
    );
  });

  test('seasonal_subscriptions (flat mirror): creating an entry for someone else is denied', async () => {
    await denied(db(EVE).set('seasonal_subscriptions/s2', { userId: BOB, enabled: true, subscriptionId: 's2' }));
  });

  test('talent_pool: another user can never read or write an employer\'s talent pool', async () => {
    await adminSdk.set(`user_profiles/${ALICE}/talent_pool/${BOB}`, { candidateId: BOB, candidateName: 'Bob' });
    await denied(db(EVE).get(`user_profiles/${ALICE}/talent_pool/${BOB}`));
    await denied(db(BOB).query(`user_profiles/${ALICE}/talent_pool`));
    await denied(db(EVE).set(`user_profiles/${ALICE}/talent_pool/${EVE}`, { candidateId: EVE, candidateName: 'Eve' }));
  });

  test(
    'talent_pool: the employer can add, list, check and remove candidates (TalentPoolService)',
    { skip: bug('BUG-t2-08', 'no rule for user_profiles/{uid}/talent_pool -> default deny; feature dead in production') },
    async () => {
      const path = `user_profiles/${ALICE}/talent_pool/${BOB}`;
      await allowed(
        db(ALICE).set(path, { candidateId: BOB, candidateName: 'Bob', conversationId: `listing1_${BOB}`, addedAt: new Date() }),
      );
      await allowed(db(ALICE).get(path));
      await allowed(db(ALICE).query(`user_profiles/${ALICE}/talent_pool`));
      await allowed(db(ALICE).delete(path));
    },
  );
});

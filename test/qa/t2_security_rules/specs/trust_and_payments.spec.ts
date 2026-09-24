// firestore.rules: reports, verification_requests, ratings, certificates,
// boosts / boost_purchases / urgent_listing_purchases - driven by the
// queries and writes ReportService, the shared VerificationService,
// RatingService, CertificateService and BoostService make.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { adminSdk, allowed, bug, db, denied, Double, resetFirestore } from '../lib/emulator.ts';
import {
  ADMIN,
  ALICE,
  BOB,
  certificatePayload,
  CONVO,
  EVE,
  ratingPayload,
  reportPayload,
  seedConversation,
  seedUsers,
  verificationPayload,
} from '../lib/fixtures.ts';

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
});

describe('reports (ReportService)', () => {
  test('a signed-in user can file their own report (submitReport)', async () => {
    await allowed(db(BOB).create('reports/r1', reportPayload(BOB, 'listing1')));
  });

  test('reporting in someone else\'s name or anonymously is denied', async () => {
    await denied(db(EVE).create('reports/r2', reportPayload(BOB, 'listing1')));
    await denied(db(null).create('reports/r3', reportPayload(BOB, 'listing1')));
  });

  test('only admins can list and resolve reports', async () => {
    await adminSdk.set('reports/r1', reportPayload(BOB, 'listing1', { createdAt: new Date() }));
    await denied(db(EVE).query('reports'));
    await denied(db(EVE).get('reports/r1'));
    await allowed(db(ADMIN).query('reports'));
    await allowed(db(ADMIN).update('reports/r1', { status: 'resolved' }));
    await denied(db(BOB).update('reports/r1', { status: 'dismissed' }));
  });

  test(
    'hasAlreadyReported: a reporter can query their own reports so duplicate reports are blocked',
    { skip: bug('BUG-t2-19', 'reports read is admin-only -> query denied -> hasAlreadyReported swallows it and always returns false') },
    async () => {
      await adminSdk.set('reports/r1', reportPayload(BOB, 'listing1', { createdAt: new Date() }));
      const rows = await allowed(
        db(BOB).query('reports', [['reporterId', '==', BOB], ['targetId', '==', 'listing1']], { limit: 1 }),
      );
      assert.equal(rows.length, 1);
    },
  );
});

describe('verification_requests (shared VerificationService)', () => {
  test('an employer can submit a pending request for themselves', async () => {
    await allowed(db(ALICE).set('verification_requests/v1', verificationPayload(ALICE)));
  });

  test('submitting a request for another employer is denied', async () => {
    await denied(db(EVE).set('verification_requests/v2', verificationPayload(ALICE)));
  });

  test('getUserVerificationRequest primary query (employerId==me, orderBy submittedAt) is allowed', async () => {
    await adminSdk.set('verification_requests/v1', verificationPayload(ALICE));
    const rows = await allowed(
      db(ALICE).query('verification_requests', [['employerId', '==', ALICE]], { orderBy: ['submittedAt', 'desc'], limit: 1 }),
    );
    assert.equal(rows.length, 1);
  });

  test(
    'getUserVerificationRequest for an employer with no request returns empty instead of failing',
    { skip: bug('BUG-t2-21', 'legacy fallback query filters on userId, which the employerId-based read rule cannot prove -> permission-denied -> rethrown to the screen') },
    async () => {
      const primary = await db(ALICE).query('verification_requests', [['employerId', '==', ALICE]], {
        orderBy: ['submittedAt', 'desc'],
        limit: 1,
      });
      assert.equal(primary.length, 0);
      const legacy = await allowed(
        db(ALICE).query('verification_requests', [['userId', '==', ALICE]], { orderBy: ['requestedAt', 'desc'], limit: 1 }),
      );
      assert.equal(legacy.length, 0);
    },
  );

  test('other users cannot read a request; the owner cannot approve it; an admin can', async () => {
    await adminSdk.set('verification_requests/v1', verificationPayload(ALICE));
    await denied(db(EVE).get('verification_requests/v1'));
    await allowed(db(ALICE).get('verification_requests/v1'));
    await denied(db(ALICE).update('verification_requests/v1', { status: 'approved' }));
    await allowed(db(ADMIN).update('verification_requests/v1', { status: 'approved', reviewedBy: ADMIN }));
  });

  test(
    'a request cannot be submitted already approved',
    { skip: bug('BUG-t2-20', 'create only checks employerId; status/reviewedBy are client-controlled') },
    async () => {
      await denied(
        db(ALICE).set('verification_requests/v1', verificationPayload(ALICE, { status: 'approved', reviewedBy: ADMIN })),
      );
    },
  );
});

describe('boosts / boost_purchases / urgent_listing_purchases', () => {
  const collections = ['boosts', 'boost_purchases', 'urgent_listing_purchases'];

  for (const col of collections) {
    test(`${col}: every client write is denied, including a free (price 0) one`, async () => {
      await denied(db(ALICE).set(`${col}/x`, { userId: ALICE, listingId: 'listing1', price: 0, status: 'active' }));
      await adminSdk.set(`${col}/p1`, { userId: ALICE, listingId: 'listing1', price: 49.99 });
      await denied(db(ALICE).update(`${col}/p1`, { price: 0 }));
      await denied(db(ALICE).delete(`${col}/p1`));
      await denied(db(ADMIN).set(`${col}/y`, { userId: ADMIN }));
    });

    test(`${col}: the buyer and admins can read, other users cannot`, async () => {
      await adminSdk.set(`${col}/p1`, { userId: ALICE, listingId: 'listing1', price: 49.99 });
      await allowed(db(ALICE).get(`${col}/p1`));
      await allowed(db(ADMIN).get(`${col}/p1`));
      await denied(db(EVE).get(`${col}/p1`));
      await denied(db(null).get(`${col}/p1`));
    });

    test(`${col}: a userId==me query is allowed, an unscoped query is denied`, async () => {
      await adminSdk.set(`${col}/p1`, { userId: ALICE, price: 49.99 });
      await adminSdk.set(`${col}/p2`, { userId: EVE, price: 49.99 });
      assert.equal((await allowed(db(ALICE).query(col, [['userId', '==', ALICE]]))).length, 1);
      await denied(db(ALICE).query(col));
    });
  }
});

describe('ratings (RatingService.submitRating)', () => {
  beforeEach(async () => {
    await seedConversation({ hired: true });
  });

  test('a valid 1..5 rating of the other participant is allowed', async () => {
    await allowed(db(ALICE).set(`ratings/${CONVO}_${ALICE}`, ratingPayload(ALICE, BOB, CONVO, { stars: 1 })));
    await allowed(db(BOB).set(`ratings/${CONVO}_${BOB}`, ratingPayload(BOB, ALICE, CONVO, { stars: 5 })));
  });

  test('stars outside 1..5 or of the wrong type are denied', async () => {
    for (const stars of [0, 6, -1, '5', null]) {
      await denied(db(ALICE).set(`ratings/r_${String(stars)}`, ratingPayload(ALICE, BOB, CONVO, { stars })), `stars=${stars}`);
    }
  });

  test('rating yourself or rating as someone else is denied', async () => {
    await denied(db(ALICE).set('ratings/self', ratingPayload(ALICE, ALICE, CONVO)));
    await denied(db(EVE).set('ratings/spoof', ratingPayload(ALICE, BOB, CONVO)));
  });

  test('ratings are publicly readable (shown on profiles) and immutable', async () => {
    await adminSdk.set('ratings/r1', ratingPayload(ALICE, BOB, CONVO, { createdAt: new Date() }));
    await allowed(db(null).get('ratings/r1'));
    await denied(db(ALICE).update('ratings/r1', { stars: 1 }));
    await denied(db(ALICE).delete('ratings/r1'));
  });

  test(
    'only a participant of a hired conversation can rate, once per conversation',
    { skip: bug('BUG-t2-22', 'rating create does not look at the conversation; doc id is client-chosen -> unlimited ratings from strangers') },
    async () => {
      await denied(db(EVE).set('ratings/stranger', ratingPayload(EVE, BOB, CONVO)), 'Eve is not in the conversation');
      await denied(db(EVE).set('ratings/ghost', ratingPayload(EVE, BOB, 'no_such_conversation')));
      await allowed(db(ALICE).set(`ratings/${CONVO}_${ALICE}`, ratingPayload(ALICE, BOB, CONVO)));
      await denied(db(ALICE).set('ratings/again_1', ratingPayload(ALICE, BOB, CONVO)), 'second rating for the same conversation');
    },
  );

  test(
    'a new rating cannot publish itself as moderationStatus "approved"',
    { skip: bug('BUG-t2-22', 'moderationStatus is client-controlled (and Rating defaults to approved)') },
    async () => {
      await denied(db(ALICE).set(`ratings/${CONVO}_${ALICE}`, ratingPayload(ALICE, BOB, CONVO, { moderationStatus: 'approved' })));
    },
  );

  test(
    'fractional stars (3.5) are rejected',
    { skip: bug('BUG-t2-23', 'rule checks "is number", the model is int; 3.5 is stored and silently truncated by Rating.fromDoc') },
    async () => {
      await denied(db(ALICE).set('ratings/half', ratingPayload(ALICE, BOB, CONVO, { stars: 3.5 })));
    },
  );

  test('an integral double (5.0 from a non-Dart client) is accepted like 5', async () => {
    await allowed(db(ALICE).set('ratings/double', ratingPayload(ALICE, BOB, CONVO, { stars: new Double(5) })));
  });
});

describe('certificates (CertificateService)', () => {
  test('a user can upload a pending certificate for themselves only', async () => {
    await allowed(db(BOB).set('certificates/c1', certificatePayload(BOB)));
    await denied(db(EVE).set('certificates/c2', certificatePayload(BOB)));
  });

  test('the owner cannot approve their own certificate; an admin can approve or reject', async () => {
    await adminSdk.set('certificates/c1', certificatePayload(BOB));
    await denied(db(BOB).update('certificates/c1', { status: 'approved' }));
    await allowed(db(ADMIN).update('certificates/c1', { status: 'rejected', rejectionReason: 'Okunaksız', reviewedBy: ADMIN }));
  });

  test('read: owner and admin yes (incl. the pending-review query), other users no', async () => {
    await adminSdk.set('certificates/c1', certificatePayload(BOB));
    await allowed(db(BOB).get('certificates/c1'));
    await allowed(db(BOB).query('certificates', [['userId', '==', BOB]]));
    await allowed(db(ADMIN).query('certificates', [['status', '==', 'pending']]));
    await denied(db(EVE).get('certificates/c1'));
    await denied(db(EVE).query('certificates', [['status', '==', 'pending']]));
  });

  test('the owner can delete their certificate, another user cannot', async () => {
    await adminSdk.set('certificates/c1', certificatePayload(BOB));
    await denied(db(EVE).delete('certificates/c1'));
    await allowed(db(BOB).delete('certificates/c1'));
  });

  test(
    'a certificate cannot be created already approved',
    { skip: bug('BUG-t2-24', 'create only checks userId; status is client-controlled') },
    async () => {
      await denied(db(BOB).set('certificates/c1', certificatePayload(BOB, { status: 'approved', reviewedBy: ADMIN })));
    },
  );
});

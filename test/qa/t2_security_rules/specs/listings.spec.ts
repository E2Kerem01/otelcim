// firestore.rules: match /listings/{listingId} (+ private/contact), driven by
// the exact writes ListingService / CreateListingScreen / EditListingScreen /
// ModerationService make.
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
import type { Data } from '../lib/emulator.ts';
import { ADMIN, ALICE, BOB, EVE, listingPayload, seedListing, seedUsers } from '../lib/fixtures.ts';

const FAR_FUTURE = new Date('2099-01-01T00:00:00Z');
const BOOST_END = new Date('2026-10-07T10:00:00.123Z');

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
});

/**
 * The map EditListingScreen._submit -> ListingService.updateListing sends:
 * Listing.toMap() minus createdAt, plus contactInfo: FieldValue.delete().
 * The screen rebuilds Listing without isUrgent / lat / lng, so they go out
 * as their defaults (false / null / null).
 */
function editScreenPayload(original: Data, changes: Data = {}): Data {
  const data: Data = {
    ...listingPayload(original.posterId as string),
    posterName: original.posterName,
    posterVerified: original.posterVerified,
    status: original.status,
    isBoosted: original.isBoosted,
    boostExpiresAt: original.boostExpiresAt,
    boostType: original.boostType,
    boostPurchaseId: original.boostPurchaseId,
    viewCount: original.viewCount,
    messageCount: original.messageCount,
    isUrgent: false,
    lat: null,
    lng: null,
    contactInfo: DELETE_FIELD,
    ...changes,
  };
  delete data.createdAt;
  return data;
}

describe('listings: create (CreateListingScreen -> createListingWithId)', () => {
  test('the owner can create a listing and then its private contact subdoc', async () => {
    await allowed(db(ALICE).set('listings/new1', listingPayload(ALICE)));
    await allowed(db(ALICE).set('listings/new1/private/contact', { value: '+90 555 111 22 33' }));
  });

  test('a first urgent listing may be published as isUrgent:true (reconciled server-side)', async () => {
    await allowed(db(ALICE).set('listings/urgent1', listingPayload(ALICE, { isUrgent: true })));
  });

  test('a listing whose posterId is somebody else is denied; anonymous create is denied', async () => {
    await denied(db(EVE).set('listings/fake', listingPayload(ALICE)));
    await denied(db(null).set('listings/anon', listingPayload(ALICE)));
  });

  test('ListingService.seedSampleListings (posterId "system_demo") can never succeed from a client', async () => {
    await denied(db(ALICE).create('listings/demo', listingPayload('system_demo')));
  });

  test(
    'a listing cannot be born boosted (isBoosted / boostExpiresAt / boostType / boostPurchaseId)',
    { skip: bug('BUG-t2-09', 'create only checks posterId; free lifetime boost without paying') },
    async () => {
      await denied(
        db(EVE).set('listings/free_boost', listingPayload(EVE, { isBoosted: true, boostExpiresAt: FAR_FUTURE, boostType: 'days30' })),
      );
      await denied(db(EVE).set('listings/free_boost2', listingPayload(EVE, { boostPurchaseId: 'forged' })));
      await denied(db(EVE).set('listings/free_urgent_paid', listingPayload(EVE, { urgentListingPurchaseId: 'forged' })));
    },
  );

  test(
    'a listing cannot be born with the verified-poster badge',
    { skip: bug('BUG-t2-10', 'posterVerified is client-controlled on create') },
    async () => {
      await denied(db(EVE).set('listings/fake_badge', listingPayload(EVE, { posterVerified: true })));
    },
  );

  test(
    'view/message counters cannot be forged at creation',
    { skip: bug('BUG-t2-11', 'viewCount/messageCount are unconstrained on create and update') },
    async () => {
      await denied(db(EVE).set('listings/popular', listingPayload(EVE, { viewCount: 999999, messageCount: 5000 })));
    },
  );
});

describe('listings: owner updates', () => {
  beforeEach(async () => {
    await seedListing('listing1', {
      isBoosted: true,
      boostExpiresAt: BOOST_END,
      boostType: 'days7',
      boostPurchaseId: 'gp_order_1',
      urgentListingPurchaseId: null,
    });
  });

  const protectedFields: Array<[string, unknown]> = [
    ['isBoosted', false],
    ['boostExpiresAt', FAR_FUTURE],
    ['boostType', 'days30'],
    ['boostPurchaseId', 'forged'],
    ['posterId', EVE],
    ['isUrgent', true],
    ['urgentListingPurchaseId', 'forged'],
  ];
  for (const [field, value] of protectedFields) {
    test(`the owner cannot change server-controlled field ${field}`, async () => {
      await denied(db(ALICE).update('listings/listing1', { [field]: value }));
    });
  }

  test('ListingService.closeListing / reactivateListing (active <-> closed) are allowed', async () => {
    await allowed(db(ALICE).update('listings/listing1', { status: 'closed' }));
    await allowed(db(ALICE).update('listings/listing1', { status: 'active' }));
  });

  test('the owner cannot take their own listing down as "removed" (moderation-only state)', async () => {
    await denied(db(ALICE).update('listings/listing1', { status: 'removed' }));
  });

  test('a removed listing cannot be reactivated or edited by its owner, but an admin can restore it', async () => {
    await allowed(db(ADMIN).update('listings/listing1', { status: 'removed' }));
    await denied(db(ALICE).update('listings/listing1', { status: 'active' }));
    await denied(db(ALICE).update('listings/listing1', { title: 'Yeni başlık' }));
    await allowed(db(ADMIN).update('listings/listing1', { status: 'active' }));
  });

  test('another user cannot update or delete the listing; the owner and an admin can delete', async () => {
    await denied(db(EVE).update('listings/listing1', { title: 'hacked' }));
    await denied(db(EVE).delete('listings/listing1'));
    await denied(db(null).update('listings/listing1', { title: 'hacked' }));
    await allowed(db(ADMIN).update('listings/listing1', { isBoosted: false }));
    await allowed(db(ALICE).delete('listings/listing1'));
  });

  test('EditListingScreen payload on a boosted, non-urgent listing is allowed (boost fields round-trip)', async () => {
    const original = (await adminSdk.get('listings/listing1')) as Data;
    await allowed(db(ALICE).update('listings/listing1', editScreenPayload(original, { title: 'Kat Görevlisi' })));
    const saved = await adminSdk.get('listings/listing1');
    assert.equal(saved?.title, 'Kat Görevlisi');
    assert.equal(saved?.isBoosted, true);
    assert.equal(saved?.createdAt instanceof Date, true, 'createdAt must be preserved');
  });

  test('EditListingScreen payload with an Arabic title is stored verbatim', async () => {
    const original = (await adminSdk.get('listings/listing1')) as Data;
    await allowed(db(ALICE).update('listings/listing1', editScreenPayload(original, { title: 'موظف استقبال' })));
    assert.equal((await adminSdk.get('listings/listing1'))?.title, 'موظف استقبال');
  });

  test(
    'the owner cannot flip posterVerified on their listing',
    { skip: bug('BUG-t2-10', 'posterVerified is not in isNotChangingBoostOrOwnershipFields') },
    async () => {
      await denied(db(ALICE).update('listings/listing1', { posterVerified: true }));
    },
  );

  test(
    'the owner cannot inflate viewCount / messageCount',
    async () => {
      await denied(db(ALICE).update('listings/listing1', { viewCount: 999999 }));
    },
  );

  test('a signed-in non-owner may increment viewCount by exactly one only', async () => {
    await allowed(db(BOB).update('listings/listing1', { viewCount: 1 }));
    await denied(db(BOB).update('listings/listing1', { viewCount: 3 }));
    await denied(db(BOB).update('listings/listing1', { viewCount: 2, title: 'hacked' }));
    await denied(db(null).update('listings/listing1', { viewCount: 2 }));
  });
});

describe('listings: EditListingScreen contract on urgent / geo-tagged listings', () => {
  test(
    'editing an urgent listing through EditListingScreen succeeds and keeps it urgent',
    { skip: bug('BUG-t2-12', 'screen rebuilds Listing without isUrgent -> sends false -> rules reject (isUrgent is protected)') },
    async () => {
      await seedListing('urgent1', { isUrgent: true });
      const original = (await adminSdk.get('listings/urgent1')) as Data;
      await allowed(db(ALICE).update('listings/urgent1', editScreenPayload(original, { title: 'Acil: Garson' })));
      assert.equal((await adminSdk.get('listings/urgent1'))?.isUrgent, true);
    },
  );

  test(
    'editing a listing through EditListingScreen keeps its map coordinates',
    { skip: bug('BUG-t2-12', 'screen rebuilds Listing without lat/lng -> they are overwritten with null (see t4)') },
    async () => {
      await seedListing('geo1');
      const original = (await adminSdk.get('listings/geo1')) as Data;
      await allowed(db(ALICE).update('listings/geo1', editScreenPayload(original, { title: 'Barmen' })));
      const saved = await adminSdk.get('listings/geo1');
      assert.equal(saved?.lat, 36.8969);
      assert.equal(saved?.lng, 30.7133);
    },
  );
});

describe('listings: batch create (BatchCreateListingScreen -> createBatchListings)', () => {
  test(
    'one batch with N listings + their private/contact subdocs is accepted',
    { skip: bug('BUG-t2-13', 'contact rule uses get() on the listing, which does not exist until the batch commits -> whole batch denied') },
    async () => {
      await allowed(
        db(ALICE).commit([
          w.set('listings/b1', listingPayload(ALICE, { title: 'Garson' })),
          w.set('listings/b1/private/contact', { value: '0532 000 00 01' }),
          w.set('listings/b2', listingPayload(ALICE, { title: 'Komi' })),
          w.set('listings/b2/private/contact', { value: '0532 000 00 02' }),
        ]),
      );
    },
  );

  test('the same batch without contact subdocs is accepted (the listing part is fine)', async () => {
    await allowed(
      db(ALICE).commit([
        w.set('listings/b1', listingPayload(ALICE, { title: 'Garson' })),
        w.set('listings/b2', listingPayload(ALICE, { title: 'Komi' })),
      ]),
    );
  });
});

describe('listings: private/contact subdoc', () => {
  beforeEach(async () => {
    await seedListing('listing1');
  });

  test('anonymous users cannot read contact info; any signed-in user can', async () => {
    await denied(db(null).get('listings/listing1/private/contact'));
    const contact = await allowed(db(BOB).get('listings/listing1/private/contact'));
    assert.equal(contact?.value, '+90 555 000 11 22');
  });

  test('only the listing owner or an admin can write contact info', async () => {
    await denied(db(EVE).set('listings/listing1/private/contact', { value: 'scam number' }));
    await allowed(db(ALICE).set('listings/listing1/private/contact', { value: '0242 111 22 33' }));
    await allowed(db(ADMIN).set('listings/listing1/private/contact', { value: '' }));
  });

  test('writing contact info for a listing that does not exist yet is denied', async () => {
    await denied(db(ALICE).set('listings/not_yet/private/contact', { value: '0242' }));
  });

  test('the public listing doc (Listing.toMap) never carries contactInfo', async () => {
    await allowed(db(ALICE).set('listings/new1', listingPayload(ALICE)));
    const doc = await db(null).get('listings/new1');
    assert.equal(doc?.contactInfo, undefined);
  });

  test(
    'deleting a listing does not leave its contact info readable',
    { skip: bug('BUG-t2-14', 'Firestore does not cascade; ListingService/deleteAccount never delete private/contact and the owner can no longer delete it') },
    async () => {
      await allowed(db(ALICE).delete('listings/listing1'));
      // What the owner could still do to clean up (get() on the deleted listing fails):
      try {
        await db(ALICE).delete('listings/listing1/private/contact');
      } catch {
        // denied
      }
      assert.equal(await db(BOB).get('listings/listing1/private/contact'), null);
    },
  );

  test(
    'a legacy listing with a top-level contactInfo field does not expose it to anonymous readers',
    { skip: bug('BUG-t2-15', 'no migration: legacy contactInfo stays public until the owner edits the listing') },
    async () => {
      await adminSdk.set('listings/legacy', listingPayload(ALICE, { createdAt: new Date(), updatedAt: new Date(), contactInfo: '0532 999 88 77' }));
      const doc = await db(null).get('listings/legacy');
      assert.equal(doc?.contactInfo, undefined);
    },
  );

  test('ListingService.updateListing strips a legacy top-level contactInfo field', async () => {
    await adminSdk.set('listings/legacy', listingPayload(ALICE, { createdAt: new Date(), updatedAt: new Date(), contactInfo: '0532 999 88 77' }));
    await allowed(db(ALICE).update('listings/legacy', { contactInfo: DELETE_FIELD, updatedAt: SERVER_TIMESTAMP }));
    assert.equal((await adminSdk.get('listings/legacy'))?.contactInfo, undefined);
  });
});

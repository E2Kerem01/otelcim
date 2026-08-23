import { afterAll, afterEach, beforeAll, describe, it } from 'vitest';
import { assertFails, assertSucceeds, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import { makeTestEnv, seed, warmUpRulesRuntime } from './env';

const OWNER = 'owner-uid';
const OTHER = 'other-uid';
const ADMIN = 'admin-uid';

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await makeTestEnv();
  await warmUpRulesRuntime(testEnv);
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('listings', () => {
  it('anyone can read a listing, including signed-out users', async () => {
    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'listings/L1'), { posterId: OWNER, status: 'active' });
    });
    const db = testEnv.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(db, 'listings/L1')));
  });

  it('a signed-in user can create a listing only under their own posterId', async () => {
    const ownerDb = testEnv.authenticatedContext(OWNER).firestore();
    await assertSucceeds(
      setDoc(doc(ownerDb, 'listings/L1'), { posterId: OWNER, status: 'active' }),
    );
    await assertFails(
      setDoc(doc(ownerDb, 'listings/L2'), { posterId: OTHER, status: 'active' }),
    );
  });

  it('the owner can edit ordinary fields but not boost/ownership fields', async () => {
    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'listings/L1'), {
        posterId: OWNER,
        status: 'active',
        title: 'Original',
        isBoosted: false,
      });
    });
    const ownerDb = testEnv.authenticatedContext(OWNER).firestore();

    await assertSucceeds(updateDoc(doc(ownerDb, 'listings/L1'), { title: 'Updated' }));
    await assertFails(updateDoc(doc(ownerDb, 'listings/L1'), { isBoosted: true }));
    await assertFails(updateDoc(doc(ownerDb, 'listings/L1'), { boostExpiresAt: new Date() }));
    await assertFails(updateDoc(doc(ownerDb, 'listings/L1'), { posterId: OTHER }));
  });

  it('a non-owner cannot update or delete someone else\'s listing', async () => {
    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'listings/L1'), { posterId: OWNER, status: 'active' });
    });
    const otherDb = testEnv.authenticatedContext(OTHER).firestore();

    await assertFails(updateDoc(doc(otherDb, 'listings/L1'), { title: 'Hijacked' }));
    await assertFails(deleteDoc(doc(otherDb, 'listings/L1')));
  });

  it('an owner cannot un-remove a moderated listing, but an admin can', async () => {
    await seed(testEnv, async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'listings/L1'), { posterId: OWNER, status: 'removed' });
      await setDoc(doc(db, 'user_profiles/' + ADMIN), { isAdmin: true });
    });
    const ownerDb = testEnv.authenticatedContext(OWNER).firestore();
    const adminDb = testEnv.authenticatedContext(ADMIN).firestore();

    await assertFails(updateDoc(doc(ownerDb, 'listings/L1'), { status: 'active' }));
    await assertSucceeds(updateDoc(doc(adminDb, 'listings/L1'), { status: 'active' }));
  });

  describe('private contact subdocument', () => {
    it('is hidden from signed-out users but readable once signed in', async () => {
      await seed(testEnv, async (context) => {
        const db = context.firestore();
        await setDoc(doc(db, 'listings/L1'), { posterId: OWNER, status: 'active' });
        await setDoc(doc(db, 'listings/L1/private/contact'), { phone: '5551234567' });
      });
      const anonDb = testEnv.unauthenticatedContext().firestore();
      const otherDb = testEnv.authenticatedContext(OTHER).firestore();

      await assertFails(getDoc(doc(anonDb, 'listings/L1/private/contact')));
      await assertSucceeds(getDoc(doc(otherDb, 'listings/L1/private/contact')));
    });

    it('can only be written by the listing owner or an admin', async () => {
      await seed(testEnv, async (context) => {
        await setDoc(doc(context.firestore(), 'listings/L1'), { posterId: OWNER, status: 'active' });
      });
      const ownerDb = testEnv.authenticatedContext(OWNER).firestore();
      const otherDb = testEnv.authenticatedContext(OTHER).firestore();

      await assertFails(setDoc(doc(otherDb, 'listings/L1/private/contact'), { phone: '000' }));
      await assertSucceeds(setDoc(doc(ownerDb, 'listings/L1/private/contact'), { phone: '5551234567' }));
    });
  });
});

describe('user_profiles', () => {
  it('cannot self-grant isAdmin on create', async () => {
    const db = testEnv.authenticatedContext(OTHER).firestore();
    await assertFails(setDoc(doc(db, 'user_profiles/' + OTHER), { isAdmin: true }));
    await assertSucceeds(setDoc(doc(db, 'user_profiles/' + OTHER), { isAdmin: false }));
  });

  it('cannot change server-controlled fields (isAdmin, boost credits, referral state) on update', async () => {
    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'user_profiles/' + OWNER), {
        isAdmin: false,
        freeBoostCredits: 0,
        referralCount: 0,
        referralRewardGranted: false,
        bio: 'hello',
      });
    });
    const db = testEnv.authenticatedContext(OWNER).firestore();

    await assertSucceeds(updateDoc(doc(db, 'user_profiles/' + OWNER), { bio: 'updated' }));
    await assertFails(updateDoc(doc(db, 'user_profiles/' + OWNER), { isAdmin: true }));
    await assertFails(updateDoc(doc(db, 'user_profiles/' + OWNER), { freeBoostCredits: 999 }));
    await assertFails(updateDoc(doc(db, 'user_profiles/' + OWNER), { referralCount: 999 }));
    await assertFails(updateDoc(doc(db, 'user_profiles/' + OWNER), { referralRewardGranted: true }));
  });
});

describe('starting a new conversation', () => {
  // Regression test: ChatService.getOrCreateConversation() does a getDoc()
  // on the conversation id *before* it exists, to decide whether to create
  // it. Firestore rules evaluate `resource` as null for a nonexistent doc,
  // so a read rule that unconditionally dereferences `resource.data`
  // throws and comes back as permission-denied instead of "not found" -
  // silently breaking "send message" for every first-time contact.
  it('a participant can read a not-yet-created conversation id and then create it', async () => {
    const seekerDb = testEnv.authenticatedContext(OTHER).firestore();
    await assertSucceeds(getDoc(doc(seekerDb, 'conversations/C1')));
    await assertSucceeds(
      setDoc(doc(seekerDb, 'conversations/C1'), { posterId: OWNER, seekerId: OTHER }),
    );
  });
});

describe('conversation messages', () => {
  async function seedConversation() {
    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'conversations/C1'), {
        posterId: OWNER,
        seekerId: OTHER,
      });
    });
  }

  it('a participant can only send a message as themselves, with allowlisted fields', async () => {
    await seedConversation();
    const seekerDb = testEnv.authenticatedContext(OTHER).firestore();

    await assertSucceeds(
      addDoc(collection(seekerDb, 'conversations/C1/messages'), {
        senderId: OTHER,
        text: 'merhaba',
        sentAt: serverTimestamp(),
      }),
    );
    // Impersonating the other participant.
    await assertFails(
      addDoc(collection(seekerDb, 'conversations/C1/messages'), {
        senderId: OWNER,
        text: 'merhaba',
        sentAt: serverTimestamp(),
      }),
    );
    // Extra field outside the allowlist.
    await assertFails(
      addDoc(collection(seekerDb, 'conversations/C1/messages'), {
        senderId: OTHER,
        text: 'merhaba',
        sentAt: serverTimestamp(),
        readByPoster: true,
      }),
    );
    // Client-chosen timestamp instead of the server timestamp.
    await assertFails(
      addDoc(collection(seekerDb, 'conversations/C1/messages'), {
        senderId: OTHER,
        text: 'merhaba',
        sentAt: new Date('2020-01-01'),
      }),
    );
  });

  it('a non-participant cannot read or send messages', async () => {
    await seedConversation();
    const strangerDb = testEnv.authenticatedContext('stranger-uid').firestore();

    await assertFails(getDoc(doc(strangerDb, 'conversations/C1')));
    await assertFails(
      addDoc(collection(strangerDb, 'conversations/C1/messages'), {
        senderId: 'stranger-uid',
        text: 'hi',
        sentAt: serverTimestamp(),
      }),
    );
  });
});

describe('boosts and boost_purchases', () => {
  it('are entirely read-only for clients, even the resource owner', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();

    await assertFails(setDoc(doc(db, 'boosts/B1'), { userId: OWNER, listingId: 'L1' }));
    await assertFails(
      setDoc(doc(db, 'boost_purchases/P1'), { userId: OWNER, price: 0, platform: 'referral_reward' }),
    );

    await seed(testEnv, async (context) => {
      await setDoc(doc(context.firestore(), 'boosts/B1'), { userId: OWNER, listingId: 'L1' });
    });
    await assertFails(updateDoc(doc(db, 'boosts/B1'), { listingId: 'L2' }));
    await assertSucceeds(getDoc(doc(db, 'boosts/B1')));
  });
});

describe('ratings', () => {
  it('requires the rater to be the authenticated user, rating someone else, with a valid score', async () => {
    const raterDb = testEnv.authenticatedContext(OTHER).firestore();

    await assertSucceeds(
      addDoc(collection(raterDb, 'ratings'), { raterId: OTHER, ratedUserId: OWNER, stars: 5 }),
    );
    await assertFails(
      addDoc(collection(raterDb, 'ratings'), { raterId: OWNER, ratedUserId: OTHER, stars: 5 }),
    );
    await assertFails(
      addDoc(collection(raterDb, 'ratings'), { raterId: OTHER, ratedUserId: OTHER, stars: 5 }),
    );
    await assertFails(
      addDoc(collection(raterDb, 'ratings'), { raterId: OTHER, ratedUserId: OWNER, stars: 6 }),
    );
  });
});

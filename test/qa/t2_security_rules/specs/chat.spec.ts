// firestore.rules: match /conversations/{id} (+ messages, interview_slots),
// driven by ChatService.getOrCreateConversation / sendMessage /
// markConversationHired / proposeInterviewSlots / confirmInterviewSlot.
import assert from 'node:assert/strict';
import { beforeEach, describe, test } from 'node:test';
import { adminSdk, allowed, bug, db, denied, resetFirestore, SERVER_TIMESTAMP } from '../lib/emulator.ts';
import {
  ADMIN,
  ALICE,
  BOB,
  CONVO,
  conversationPayload,
  EVE,
  interviewSlotPayload,
  messagePayload,
  seedConversation,
  seedListing,
  seedUsers,
} from '../lib/fixtures.ts';

beforeEach(async () => {
  await resetFirestore();
  await seedUsers();
  await seedListing('listing1');
});

describe('conversations: getOrCreateConversation', () => {
  test('a seeker can probe a not-yet-existing conversation id and then create it', async () => {
    assert.equal(await allowed(db(BOB).get(`conversations/${CONVO}`)), null);
    await allowed(db(BOB).set(`conversations/${CONVO}`, conversationPayload('listing1', ALICE, BOB)));
    const saved = await allowed(db(BOB).get(`conversations/${CONVO}`));
    assert.equal(saved?.seekerId, BOB);
  });

  test('an anonymous caller cannot even probe a conversation id', async () => {
    await denied(db(null).get(`conversations/${CONVO}`));
  });

  test('a third party cannot read an existing conversation; participants and admins can', async () => {
    await seedConversation();
    await denied(db(EVE).get(`conversations/${CONVO}`));
    await allowed(db(ALICE).get(`conversations/${CONVO}`));
    await allowed(db(ADMIN).get(`conversations/${CONVO}`));
  });

  test('watchConversations queries (posterId==me / seekerId==me) are allowed; an unfiltered list is not', async () => {
    await seedConversation();
    assert.equal((await allowed(db(ALICE).query('conversations', [['posterId', '==', ALICE]]))).length, 1);
    assert.equal((await allowed(db(BOB).query('conversations', [['seekerId', '==', BOB]]))).length, 1);
    await denied(db(EVE).query('conversations'));
    await denied(db(EVE).query('conversations', [['posterId', '==', ALICE]]));
  });

  test('a conversation between two other users cannot be created by a third party', async () => {
    await denied(db(EVE).set('conversations/listing1_x', conversationPayload('listing1', ALICE, BOB)));
  });

  test(
    'a seeker cannot open a conversation naming someone who does not own the listing as the poster',
    { skip: bug('BUG-t2-16', 'create only checks auth is posterId OR seekerId; nothing ties posterId to the listing') },
    async () => {
      // Eve drops a "job" conversation into Bob's inbox for Alice's listing.
      await denied(db(EVE).set(`conversations/listing1_${EVE}`, conversationPayload('listing1', BOB, EVE)));
    },
  );

  test(
    'an employer cannot push conversations into arbitrary users\' inboxes',
    { skip: bug('BUG-t2-16', 'poster may create conversations with any seekerId (spam; also feeds referral-reward trigger, see t1)') },
    async () => {
      await denied(db(EVE).set('conversations/fake_listing_bob', conversationPayload('fake_listing', EVE, BOB)));
    },
  );

  test('participants cannot re-assign posterId / seekerId', async () => {
    await seedConversation();
    await denied(db(BOB).update(`conversations/${CONVO}`, { posterId: EVE }));
    await denied(db(ALICE).update(`conversations/${CONVO}`, { seekerId: EVE }));
  });
});

describe('messages: sendMessage', () => {
  beforeEach(async () => {
    await seedConversation();
  });
  const msgs = `conversations/${CONVO}/messages`;

  test('a participant can send a message exactly like ChatService.sendMessage', async () => {
    await allowed(db(BOB).create(`${msgs}/m1`, messagePayload(BOB, 'Merhaba, ilan hâlâ geçerli mi?')));
    await allowed(db(ALICE).create(`${msgs}/m2`, messagePayload(ALICE, 'Evet 🙂')));
    await allowed(db(ALICE).update(`conversations/${CONVO}`, { lastMessage: 'Evet 🙂', lastSenderId: ALICE, updatedAt: SERVER_TIMESTAMP }));
  });

  test('Arabic (RTL) message text is accepted', async () => {
    await allowed(db(BOB).create(`${msgs}/ar`, messagePayload(BOB, 'مرحبا، هل الوظيفة متاحة؟')));
  });

  test('a message sent on behalf of the other participant is denied', async () => {
    await denied(db(BOB).create(`${msgs}/spoof`, messagePayload(ALICE, 'İşe alındın!')));
  });

  test('text length boundaries: 0 denied, 1 and 5000 allowed, 5001 denied', async () => {
    await denied(db(BOB).create(`${msgs}/len0`, messagePayload(BOB, '')));
    await allowed(db(BOB).create(`${msgs}/len1`, messagePayload(BOB, 'a')));
    await allowed(db(BOB).create(`${msgs}/len5000`, messagePayload(BOB, 'a'.repeat(5000))));
    await denied(db(BOB).create(`${msgs}/len5001`, messagePayload(BOB, 'a'.repeat(5001))));
  });

  test('non-string text and missing text are denied', async () => {
    await denied(db(BOB).create(`${msgs}/num`, messagePayload(BOB, 'x', { text: 42 })));
    await denied(db(BOB).create(`${msgs}/null`, messagePayload(BOB, 'x', { text: null })));
    await denied(db(BOB).create(`${msgs}/missing`, { senderId: BOB, sentAt: SERVER_TIMESTAMP }));
  });

  test('extra fields are denied', async () => {
    await denied(db(BOB).create(`${msgs}/extra`, messagePayload(BOB, 'hi', { attachmentUrl: 'http://evil' })));
  });

  test('a client-chosen sentAt (back-dating) is denied; serverTimestamp is required', async () => {
    await denied(db(BOB).create(`${msgs}/old`, messagePayload(BOB, 'hi', { sentAt: new Date('2020-01-01T00:00:00Z') })));
    await denied(db(BOB).create(`${msgs}/nosent`, { senderId: BOB, text: 'hi' }));
  });

  test('non-participants cannot send or read messages; admins can read', async () => {
    await adminSdk.set(`${msgs}/m1`, { senderId: BOB, text: 'hi', sentAt: new Date() });
    await denied(db(EVE).create(`${msgs}/eve`, messagePayload(EVE, 'hi')));
    await denied(db(EVE).query(msgs));
    await allowed(db(ALICE).query(msgs));
    await allowed(db(ADMIN).query(msgs));
  });

  test('messages are immutable once sent', async () => {
    await adminSdk.set(`${msgs}/m1`, { senderId: BOB, text: 'hi', sentAt: new Date() });
    await denied(db(BOB).update(`${msgs}/m1`, { text: 'edited' }));
  });

  test(
    'the conversation preview cannot be spoofed or blown past the message size limit',
    { skip: bug('BUG-t2-17', 'conversation update only protects posterId/seekerId; lastMessage/lastSenderId/listingId are free-form') },
    async () => {
      await denied(db(BOB).update(`conversations/${CONVO}`, { lastMessage: 'x'.repeat(6000) }));
      await denied(db(BOB).update(`conversations/${CONVO}`, { lastMessage: 'İşe alındın', lastSenderId: ALICE }));
      await denied(db(BOB).update(`conversations/${CONVO}`, { listingId: 'other_listing' }));
    },
  );
});

describe('conversations: hired flag (ChatService.markConversationHired)', () => {
  beforeEach(async () => {
    await seedConversation();
  });

  test('the employer (poster) can mark the seeker as hired', async () => {
    await allowed(
      db(ALICE).update(`conversations/${CONVO}`, { hired: true, hiredAt: SERVER_TIMESTAMP, updatedAt: SERVER_TIMESTAMP }),
    );
  });

  test(
    'the seeker cannot mark themselves as hired (it unlocks ratings)',
    { skip: bug('BUG-t2-17', 'any participant may write hired/hiredAt') },
    async () => {
      await denied(
        db(BOB).update(`conversations/${CONVO}`, { hired: true, hiredAt: SERVER_TIMESTAMP, updatedAt: SERVER_TIMESTAMP }),
      );
    },
  );
});

describe('interview_slots', () => {
  beforeEach(async () => {
    await seedConversation();
  });
  const slots = `conversations/${CONVO}/interview_slots`;

  test('a participant can propose slots and the other participant can confirm one', async () => {
    await allowed(db(ALICE).set(`${slots}/s1`, interviewSlotPayload(ALICE)));
    await allowed(
      db(BOB).update(`${slots}/s1`, {
        selectedSlot: new Date('2026-10-01T09:00:00Z'),
        status: 'confirmed',
        updatedAt: SERVER_TIMESTAMP,
      }),
    );
  });

  test('non-participants cannot propose, read or confirm', async () => {
    await adminSdk.set(`${slots}/s1`, interviewSlotPayload(ALICE));
    await denied(db(EVE).set(`${slots}/s2`, interviewSlotPayload(EVE)));
    await denied(db(EVE).query(slots));
    await denied(db(EVE).update(`${slots}/s1`, { status: 'confirmed' }));
  });

  test(
    'the proposer cannot confirm their own proposal, and only an offered slot can be selected',
    { skip: bug('BUG-t2-18', 'interview_slots allow read, write to both participants with no field checks') },
    async () => {
      await adminSdk.set(`${slots}/s1`, interviewSlotPayload(ALICE));
      await denied(db(ALICE).update(`${slots}/s1`, { selectedSlot: new Date('2026-10-01T09:00:00Z'), status: 'confirmed' }));
      await denied(db(BOB).update(`${slots}/s1`, { selectedSlot: new Date('2030-01-01T00:00:00Z'), status: 'confirmed' }));
      await denied(db(BOB).set(`${slots}/s3`, interviewSlotPayload(ALICE)), 'proposedBy must be the caller');
    },
  );
});

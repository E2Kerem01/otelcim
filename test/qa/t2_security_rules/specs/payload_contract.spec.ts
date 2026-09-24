// JS half of the client-payload contract: every payload builder the rules
// tests use must produce exactly the key set recorded in
// fixtures/client_payload_keys.json. The Dart half
// (client_payload_contract_test.dart) pins the same file to the real models,
// so a model change that is not mirrored here fails one side or the other.
import assert from 'node:assert/strict';
import { describe, test } from 'node:test';
import {
  certificatePayload,
  conversationPayload,
  interviewSlotPayload,
  listingPayload,
  messagePayload,
  PAYLOAD_KEYS,
  profilePayload,
  ratingPayload,
  reportPayload,
  verificationPayload,
} from '../lib/fixtures.ts';

const builders: Record<string, () => Record<string, unknown>> = {
  'UserProfile.toFirestore': () => profilePayload('u'),
  'Listing.toMap': () => listingPayload('u'),
  'Conversation.toMap': () => conversationPayload('l', 'p', 's'),
  'Message.toMap': () => messagePayload('u', 'hi'),
  'Report.toMap': () => reportPayload('u', 't'),
  'Rating.toMap': () => ratingPayload('a', 'b', 'c'),
  'Certificate.toMap': () => certificatePayload('u'),
  'VerificationRequest.toFirestore': () => verificationPayload('u'),
  'InterviewSlot.toMap': () => interviewSlotPayload('u'),
};

describe('payload builders mirror the Dart models', () => {
  for (const [model, build] of Object.entries(builders)) {
    test(`${model} key set`, () => {
      assert.deepEqual(Object.keys(build()).sort(), [...PAYLOAD_KEYS[model]].sort());
    });
  }

  test('model defaults the rules tests rely on', () => {
    const defaults = PAYLOAD_KEYS.defaults as unknown as Record<string, unknown>;
    assert.equal(ratingPayload('a', 'b', 'c').moderationStatus, defaults['Rating.moderationStatus']);
    assert.equal(verificationPayload('u').status, defaults['VerificationRequest.status']);
    assert.equal(listingPayload('u').isUrgent, defaults['Listing.isUrgent']);
    assert.equal(listingPayload('u').posterVerified, defaults['Listing.posterVerified']);
  });
});

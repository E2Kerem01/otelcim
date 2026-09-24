// sendInterviewConfirmedNotification — both participants are told when an
// interview slot flips to "confirmed" (ChatService.confirmInterviewSlot).

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {bug, db, errorLogs, fns, state, updatedEvent, useFreshState} from "./harness.mjs";

const PARAMS = {conversationId: "C1", slotId: "S1"};
const change = (before, after) => fns.sendInterviewConfirmedNotification.run(updatedEvent(PARAMS, before, after));
const PENDING = {proposedBy: "poster", status: "pending"};
const CONFIRMED = {proposedBy: "poster", status: "confirmed"};

function seed({poster = {}, seeker = {}, conversation = {posterId: "poster", seekerId: "seeker"}} = {}) {
  if (conversation) db.seed("conversations/C1", conversation);
  if (poster) db.seed("user_profiles/poster", {fcmToken: "tok-poster", ...poster});
  if (seeker) db.seed("user_profiles/seeker", {fcmToken: "tok-seeker", ...seeker});
}

const tokens = () => state.sends.map((m) => m.token).sort();

describe("sendInterviewConfirmedNotification — transitions", () => {
  useFreshState();

  test("pending → confirmed notifies both participants once each", async () => {
    seed();
    await change(PENDING, CONFIRMED);
    assert.deepEqual(tokens(), ["tok-poster", "tok-seeker"]);
    for (const msg of state.sends) {
      assert.equal(msg.notification.title, "Mülakat Onaylandı");
      assert.deepEqual(msg.data, {type: "interview_confirmed", conversationId: "C1", slotId: "S1"});
      assert.equal(msg.android.notification.channelId, "messages");
    }
  });

  test("confirmed → confirmed (e.g. another field edited) sends nothing", async () => {
    seed();
    await change(CONFIRMED, {...CONFIRMED, updatedAt: "later"});
    assert.equal(state.sends.length, 0);
  });

  test("pending → pending and pending → rejected send nothing", async () => {
    seed();
    await change(PENDING, {...PENDING, slots: ["x"]});
    await change(PENDING, {...PENDING, status: "rejected"});
    assert.equal(state.sends.length, 0);
  });

  test("a deleted slot (no after data) sends nothing", async () => {
    seed();
    await change(PENDING, undefined);
    assert.equal(state.sends.length, 0);
  });

  test("an update without before data but confirmed after still notifies", async () => {
    seed();
    await change(undefined, CONFIRMED);
    assert.equal(state.sends.length, 2);
  });
});

describe("sendInterviewConfirmedNotification — partial data", () => {
  useFreshState();

  test("missing conversation sends nothing and is not an error", async () => {
    seed({conversation: null});
    await change(PENDING, CONFIRMED);
    assert.equal(state.sends.length, 0);
    assert.equal(errorLogs().length, 0);
  });

  test("a participant without a token is skipped, the other still notified", async () => {
    seed({poster: {fcmToken: undefined}});
    await change(PENDING, CONFIRMED);
    assert.deepEqual(tokens(), ["tok-seeker"]);
  });

  test("a participant without a profile is skipped, the other still notified", async () => {
    seed({seeker: null});
    await change(PENDING, CONFIRMED);
    assert.deepEqual(tokens(), ["tok-poster"]);
  });

  test("a conversation missing seekerId notifies only the poster", async () => {
    seed({conversation: {posterId: "poster"}});
    await change(PENDING, CONFIRMED);
    assert.deepEqual(tokens(), ["tok-poster"]);
  });

  test(
    "BUG-t1-13: a failed push to the first participant (stale token) does not stop the second one",
    {skip: bug("13", "for döngüsü tek try içinde; poster'a send hata verirse seeker'a hiç gönderilmiyor")},
    async () => {
      seed();
      state.sendImpl = (msg) => {
        if (msg.token === "tok-poster") throw new Error("registration-token-not-registered");
      };
      await change(PENDING, CONFIRMED);
      assert.deepEqual(tokens(), ["tok-seeker"]);
    },
  );

  test(
    "BUG-t1-14: a participant who turned message notifications off is not pushed",
    {skip: bug("14", "mülakat bildirimi notificationPreferences'ı hiç okumuyor ('messages' kanalı kullanıyor)")},
    async () => {
      seed({seeker: {notificationPreferences: {messages: false}}});
      await change(PENDING, CONFIRMED);
      assert.deepEqual(tokens(), ["tok-poster"]);
    },
  );
});

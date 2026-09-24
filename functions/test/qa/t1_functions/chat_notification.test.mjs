// sendChatMessageNotification — push to the other participant when a message
// lands in conversations/{id}/messages.

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {bug, createdEvent, db, errorLogs, fns, quietWindowAroundNow, state, useFreshState} from "./harness.mjs";

const PARAMS = {conversationId: "C1", messageId: "M1"};
const deliver = (message) => fns.sendChatMessageNotification.run(createdEvent(PARAMS, message));

function seedConversation({poster = {}, seeker = {}, conversation = {posterId: "poster", seekerId: "seeker"}} = {}) {
  if (conversation) db.seed("conversations/C1", conversation);
  if (poster) db.seed("user_profiles/poster", {displayName: "Otel Lara", fcmToken: "tok-poster", ...poster});
  if (seeker) db.seed("user_profiles/seeker", {displayName: "Ayşe", fcmToken: "tok-seeker", ...seeker});
}

describe("sendChatMessageNotification — skipped deliveries", () => {
  useFreshState();

  test("an event without document data sends nothing", async () => {
    seedConversation();
    await deliver(undefined);
    assert.equal(state.sends.length, 0);
  });

  test("a message without senderId or with empty text sends nothing", async () => {
    seedConversation();
    await deliver({text: "Merhaba"});
    await deliver({senderId: "seeker", text: ""});
    assert.equal(state.sends.length, 0);
  });

  test("a message in a conversation that no longer exists sends nothing", async () => {
    seedConversation({conversation: null});
    await deliver({senderId: "seeker", text: "Merhaba"});
    assert.equal(state.sends.length, 0);
    assert.equal(errorLogs().length, 0);
  });

  test("a sender who is neither poster nor seeker never triggers a push", async () => {
    seedConversation();
    await deliver({senderId: "stranger", text: "spam"});
    assert.equal(state.sends.length, 0);
  });

  test("a conversation with a missing seekerId cannot notify anybody", async () => {
    seedConversation({conversation: {posterId: "poster"}});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends.length, 0);
  });

  test("recipient who turned message notifications off gets nothing", async () => {
    seedConversation({seeker: {notificationPreferences: {messages: false}}});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends.length, 0);
  });

  test("recipient without an FCM token gets nothing", async () => {
    seedConversation({seeker: {fcmToken: ""}});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends.length, 0);
  });

  test("recipient without a profile document gets nothing and no error is logged", async () => {
    seedConversation({seeker: null});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends.length, 0);
    assert.equal(errorLogs().length, 0);
  });

  test("a messaging failure is logged and swallowed so the message write is unaffected", async () => {
    seedConversation();
    state.sendImpl = () => {
      throw Object.assign(new Error("Requested entity was not found."), {code: "messaging/registration-token-not-registered"});
    };
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(errorLogs().length, 1);
    assert.match(errorLogs()[0].msg, /gönderilemedi/);
  });
});

describe("sendChatMessageNotification — delivered push", () => {
  useFreshState();

  test("poster → seeker: goes to the seeker's token with the chat payload and 'messages' channel", async () => {
    seedConversation();
    await deliver({senderId: "poster", text: "Yarın görüşmeye gelebilir misiniz?"});
    assert.equal(state.sends.length, 1);
    const [msg] = state.sends;
    assert.equal(msg.token, "tok-seeker");
    assert.deepEqual(msg.notification, {title: "Otel Lara", body: "Yarın görüşmeye gelebilir misiniz?"});
    assert.deepEqual(msg.data, {type: "chat", conversationId: "C1", senderId: "poster"});
    assert.equal(msg.android.priority, "high");
    assert.equal(msg.android.notification.channelId, "messages");
    assert.equal(msg.apns.payload.aps.sound, "default");
  });

  test("seeker → poster: goes to the poster's token, titled with the seeker's name", async () => {
    seedConversation();
    await deliver({senderId: "seeker", text: "Merhaba"});
    assert.equal(state.sends[0].token, "tok-poster");
    assert.equal(state.sends[0].notification.title, "Ayşe");
  });

  test("preferences present but without a 'messages' key still deliver (default on)", async () => {
    seedConversation({seeker: {notificationPreferences: {marketing: false}}});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends.length, 1);
  });

  test("title falls back to hotelName when the sender has no displayName", async () => {
    seedConversation({poster: {displayName: undefined, hotelName: "Kaya Palazzo"}});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends[0].notification.title, "Kaya Palazzo");
  });

  test("title is 'Yeni mesaj' when the sender profile is missing", async () => {
    seedConversation({poster: null});
    await deliver({senderId: "poster", text: "Merhaba"});
    assert.equal(state.sends[0].notification.title, "Yeni mesaj");
  });

  test("Arabic (RTL) text and sender name are passed through untouched", async () => {
    seedConversation({seeker: {displayName: "أحمد"}});
    await deliver({senderId: "seeker", text: "مرحبا، هل الوظيفة متاحة؟"});
    assert.deepEqual(state.sends[0].notification, {title: "أحمد", body: "مرحبا، هل الوظيفة متاحة؟"});
  });

  test("preview: exactly 120 chars is sent as-is, 121 chars is cut to 117 + '...'", async () => {
    seedConversation();
    await deliver({senderId: "poster", text: "a".repeat(120)});
    await deliver({senderId: "poster", text: "b".repeat(121)});
    assert.equal(state.sends[0].notification.body, "a".repeat(120));
    assert.equal(state.sends[1].notification.body, `${"b".repeat(117)}...`);
    assert.equal(state.sends[1].notification.body.length, 120);
  });

  test(
    "BUG-t1-11: the sender's e-mail address is never used as the notification title",
    {skip: bug("11", "displayName/hotelName yoksa gönderenin e-postası bildirim başlığında karşı tarafa gidiyor (PII)")},
    async () => {
      seedConversation({seeker: {displayName: undefined, email: "ayse.private@gmail.com"}});
      await deliver({senderId: "seeker", text: "Merhaba"});
      assert.doesNotMatch(state.sends[0].notification.title, /@/);
    },
  );

  test(
    "BUG-t1-17: truncating a long emoji message never leaves a broken (lone surrogate) character",
    {skip: bug("17", "substring(0,117) UTF-16 surrogate çiftini ortadan bölüyor; bildirimde � görünür")},
    async () => {
      seedConversation();
      await deliver({senderId: "poster", text: `${"a".repeat(116)}${"😀".repeat(5)}`});
      assert.ok(state.sends[0].notification.body.isWellFormed(), "preview contains a lone surrogate");
    },
  );

  test(
    "BUG-t1-18: a conversation whose poster and seeker are the same user does not push to the sender",
    {skip: bug("18", "posterId === seekerId ise gönderen kendi mesajının bildirimini alıyor")},
    async () => {
      db.seed("conversations/C1", {posterId: "poster", seekerId: "poster"});
      db.seed("user_profiles/poster", {displayName: "Otel Lara", fcmToken: "tok-poster"});
      await deliver({senderId: "poster", text: "test"});
      assert.equal(state.sends.length, 0);
    },
  );

  test(
    "BUG-t1-12: a message arriving inside the recipient's quiet hours is not pushed audibly",
    {skip: bug("12", "quietHoursStart/End profilde saklanıyor ama hiçbir fonksiyon dikkate almıyor")},
    async () => {
      seedConversation({seeker: quietWindowAroundNow()});
      await deliver({senderId: "poster", text: "Gece mesajı"});
      const msg = state.sends[0];
      // Either suppressed entirely or delivered silently (no sound / no notification block).
      const audible = msg && msg.notification && msg.apns?.payload?.aps?.sound === "default";
      assert.ok(!audible, "push was delivered with sound during quiet hours");
    },
  );
});

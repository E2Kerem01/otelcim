// sendSeasonalReminders — fires when a seasonal_subscriptions mirror doc is
// created (SeasonalService.addSubscription writes it).

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {bug, clientAndroidChannelIds, createdEvent, db, errorLogs, fns, state, useFreshState} from "./harness.mjs";

const subscribe = (sub, subscriptionId = "S1") => fns.sendSeasonalReminders.run(createdEvent({subscriptionId}, sub));

// Shape written by SeasonalService.addSubscription for the flat mirror doc.
const subscription = (overrides = {}) => ({
  userId: "u1",
  city: "Antalya",
  category: "reception",
  season: "Yaz Sezonu",
  enabled: true,
  subscriptionId: "S1",
  ...overrides,
});

function seedUser(extra = {}) {
  db.seed("user_profiles/u1", {fcmToken: "tok-u1", notificationPreferences: {seasonalReminders: true}, ...extra});
}

describe("sendSeasonalReminders — skipped deliveries", () => {
  useFreshState();

  test("missing event data or a disabled subscription sends nothing", async () => {
    seedUser();
    await subscribe(undefined);
    await subscribe(subscription({enabled: false}));
    assert.equal(state.sends.length, 0);
  });

  test("a subscription without userId sends nothing", async () => {
    seedUser();
    await subscribe(subscription({userId: undefined}));
    assert.equal(state.sends.length, 0);
  });

  test("a subscription for a user without a profile sends nothing", async () => {
    await subscribe(subscription());
    assert.equal(state.sends.length, 0);
    assert.equal(errorLogs().length, 0);
  });

  test("user who turned seasonal reminders off gets nothing", async () => {
    seedUser({notificationPreferences: {seasonalReminders: false}});
    await subscribe(subscription());
    assert.equal(state.sends.length, 0);
  });

  test("user without an FCM token gets nothing", async () => {
    seedUser({fcmToken: undefined});
    await subscribe(subscription());
    assert.equal(state.sends.length, 0);
  });

  test("a messaging failure is logged, not thrown", async () => {
    seedUser();
    state.sendImpl = () => {
      throw new Error("unavailable");
    };
    await subscribe(subscription());
    assert.equal(errorLogs().length, 1);
  });
});

describe("sendSeasonalReminders — delivered push", () => {
  useFreshState();

  test("sends a seasonal_reminder to the subscriber's token with city and season in the body and data", async () => {
    seedUser();
    await subscribe(subscription());
    assert.equal(state.sends.length, 1);
    const [msg] = state.sends;
    assert.equal(msg.token, "tok-u1");
    assert.equal(msg.notification.title, "Sezonluk İşe Alım Hatırlatması");
    assert.match(msg.notification.body, /Yaz Sezonu için Antalya bölgesinde/);
    assert.deepEqual(msg.data, {type: "seasonal_reminder", subscriptionId: "S1", city: "Antalya", season: "Yaz Sezonu"});
  });

  test("a subscription with no city (SeasonalService writes city: null) falls back to 'Tüm Bölgeler'", async () => {
    seedUser();
    await subscribe(subscription({city: null, season: null}));
    const [msg] = state.sends;
    assert.equal(msg.data.city, "Tüm Bölgeler");
    assert.equal(msg.data.season, "Yaklaşan Sezon");
    assert.match(msg.notification.body, /^Yaklaşan Sezon için Tüm Bölgeler bölgesinde/);
  });

  test("a profile without notificationPreferences is treated as opted in", async () => {
    db.seed("user_profiles/u1", {fcmToken: "tok-u1"});
    await subscribe(subscription());
    assert.equal(state.sends.length, 1);
  });

  test(
    "BUG-t1-15: the body shows a human season label, never the raw season code SeasonalService stores",
    {skip: bug("15", "SeasonalService 'yaz_2025' gibi ham kodu yazıyor; bildirimde 'yaz_2025 için ...' görünür (üstelik geçmiş sezon)")},
    async () => {
      seedUser();
      await subscribe(subscription({season: "yaz_2025"}));
      assert.doesNotMatch(state.sends[0].notification.body, /\b[a-z]+_\d{4}(_\d{2})?\b/);
    },
  );

  test(
    "BUG-t1-16: the Android channel used ('reminders') is one the Flutter client actually creates",
    {skip: bug("16", "istemci sadece 'messages' ve 'urgent_listings' kanallarını oluşturuyor; 'reminders' yok")},
    async () => {
      seedUser();
      await subscribe(subscription());
      const channels = await clientAndroidChannelIds();
      assert.ok(channels.includes(state.sends[0].android.notification.channelId), `client channels: ${channels}`);
    },
  );

  test(
    "BUG-t1-19: a user who explicitly subscribes with the default preferences receives the reminder",
    {skip: bug("19", "UserProfile varsayılanı seasonalReminders:false; abone olan yeni kullanıcı hiç hatırlatma almıyor")},
    async () => {
      // UserProfile.defaultNotificationPreferences, as written by toFirestore() on sign-up.
      seedUser({
        notificationPreferences: {messages: true, listingAlerts: true, seasonalReminders: false, urgentListings: true, marketing: false},
      });
      await subscribe(subscription());
      assert.equal(state.sends.length, 1);
    },
  );
});

describe("client ↔ functions notification channel contract", () => {
  test("the chat and urgent-listing channels used by the functions exist on the client", async () => {
    const channels = await clientAndroidChannelIds();
    assert.ok(channels.includes("messages"), `client channels: ${channels}`);
    assert.ok(channels.includes("urgent_listings"), `client channels: ${channels}`);
  });
});

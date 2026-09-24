// grantReferralRewardIfEligible via its two triggers:
// grantReferralRewardOnListingCreated (poster's first listing) and
// grantReferralRewardOnConversationCreated (seeker's first chat).

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {bug, createdEvent, db, errorLogs, fns, useFreshState} from "./harness.mjs";

const listingCreated = (listing, listingId = "L1") =>
  fns.grantReferralRewardOnListingCreated.run(createdEvent({listingId}, listing));
const conversationCreated = (conversation, conversationId = "C1") =>
  fns.grantReferralRewardOnConversationCreated.run(createdEvent({conversationId}, conversation));

function seedReferral({referee = {}, referrer = {}} = {}) {
  if (referrer) db.seed("user_profiles/referrer", {displayName: "Davet Eden", freeBoostCredits: 0, referralCount: 0, ...referrer});
  if (referee) db.seed("user_profiles/newbie", {displayName: "Yeni", referredBy: "referrer", ...referee});
}

const referrer = () => db.read("user_profiles/referrer");
const referee = () => db.read("user_profiles/newbie");

describe("referral reward — eligibility", () => {
  useFreshState();

  test("first listing by a referred poster: referrer +1 free boost credit and +1 referral, referee flagged", async () => {
    seedReferral();
    await listingCreated({posterId: "newbie"});
    assert.equal(referrer().freeBoostCredits, 1);
    assert.equal(referrer().referralCount, 1);
    assert.equal(referee().referralRewardGranted, true);
  });

  test("first conversation by a referred seeker grants the same reward", async () => {
    seedReferral();
    await conversationCreated({posterId: "employer", seekerId: "newbie"});
    assert.equal(referrer().freeBoostCredits, 1);
    assert.equal(referee().referralRewardGranted, true);
  });

  test("a referrer profile without the counter fields starts them at 1", async () => {
    seedReferral({referrer: null});
    db.seed("user_profiles/referrer", {displayName: "Eski profil"});
    await listingCreated({posterId: "newbie"});
    assert.equal(referrer().freeBoostCredits, 1);
    assert.equal(referrer().referralCount, 1);
  });

  test("the reward is granted only once: a second listing and a later chat do nothing", async () => {
    seedReferral();
    await listingCreated({posterId: "newbie"}, "L1");
    await listingCreated({posterId: "newbie"}, "L2");
    await conversationCreated({seekerId: "newbie"});
    assert.equal(referrer().freeBoostCredits, 1);
    assert.equal(referrer().referralCount, 1);
  });

  test("a user who was not referred triggers nothing", async () => {
    seedReferral({referee: {referredBy: undefined}});
    await listingCreated({posterId: "newbie"});
    assert.equal(referrer().freeBoostCredits, 0);
    assert.equal(referee().referralRewardGranted, undefined);
  });

  test("an empty-string referredBy is treated as not referred", async () => {
    seedReferral({referee: {referredBy: ""}});
    await listingCreated({posterId: "newbie"});
    assert.equal(db.stats.commits, 0);
  });

  test("referrer account no longer exists → no reward, no error, referee not flagged", async () => {
    seedReferral({referrer: null});
    await listingCreated({posterId: "newbie"});
    assert.equal(referee().referralRewardGranted, undefined);
    assert.equal(errorLogs().length, 0);
  });

  test("listing without posterId, or poster without a profile → nothing happens", async () => {
    seedReferral();
    await listingCreated({title: "posterId yok"});
    await listingCreated({posterId: "ghost"});
    await listingCreated(undefined);
    assert.equal(referrer().freeBoostCredits, 0);
  });

  test("conversation without seekerId, or seeker without a profile → nothing happens", async () => {
    seedReferral();
    await conversationCreated({posterId: "newbie"});
    await conversationCreated({seekerId: "ghost"});
    await conversationCreated(undefined);
    assert.equal(referrer().freeBoostCredits, 0);
  });

  test("a referred user who only appears as the POSTER of a conversation gets no reward from the chat trigger", async () => {
    seedReferral();
    await conversationCreated({posterId: "newbie", seekerId: "someone-else"});
    assert.equal(referrer().freeBoostCredits, 0);
  });

  test(
    "BUG-t1-05: a user who sets referredBy to their own uid does not reward themselves",
    {skip: bug("05", "referredBy === refereeId kontrolü yok; kullanıcı kendine ücretsiz boost kazandırabiliyor")},
    async () => {
      db.seed("user_profiles/newbie", {referredBy: "newbie", freeBoostCredits: 0});
      await listingCreated({posterId: "newbie"});
      assert.equal(referee().freeBoostCredits, 0);
    },
  );
});

describe("referral reward — atomicity and concurrency", () => {
  useFreshState();

  test(
    "BUG-t1-09: listing and conversation created at the same time still grant exactly one credit",
    {skip: bug("09", "bayrak kontrolü tetikleyici anlık görüntüsünden, yazma transaction'sız; eşzamanlı iki tetikleyici çift ödül verir")},
    async () => {
      seedReferral();
      await Promise.all([listingCreated({posterId: "newbie"}), conversationCreated({seekerId: "newbie"})]);
      assert.equal(referrer().freeBoostCredits, 1);
      assert.equal(referrer().referralCount, 1);
    },
  );

  test(
    "BUG-t1-10: if flagging the referee fails, the credit is not granted (so a retry cannot double it)",
    {skip: bug("10", "ödül ve bayrak iki ayrı update; ikincisi hata verirse ödül kalır, bayrak yazılmaz → sonraki tetikleyici tekrar ödüllendirir")},
    async () => {
      seedReferral();
      db.beforeWrite = (_op, path) => {
        if (path === "user_profiles/newbie") throw new Error("DEADLINE_EXCEEDED");
      };
      await listingCreated({posterId: "newbie"}, "L1");
      db.beforeWrite = null;
      await conversationCreated({seekerId: "newbie"}); // next qualifying action
      assert.equal(referrer().freeBoostCredits, 1);
      assert.equal(referee().referralRewardGranted, true);
    },
  );

  test("a failure while crediting the referrer is logged and leaves both profiles unchanged", async () => {
    seedReferral();
    db.beforeWrite = (_op, path) => {
      if (path === "user_profiles/referrer") throw new Error("unavailable");
    };
    await listingCreated({posterId: "newbie"});
    db.beforeWrite = null;
    assert.equal(errorLogs().length, 1);
    assert.equal(referrer().freeBoostCredits, 0);
    assert.equal(referee().referralRewardGranted, undefined);
  });
});

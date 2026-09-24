// redeemFreeBoost — spends one referral-earned credit on a 7-day boost.

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {DAY_MS, bug, callAs, db, fns, rejectsWithCode, useFreshState} from "./harness.mjs";

const redeem = (uid, data) => fns.redeemFreeBoost.run(callAs(uid, data));

function seed({credits, listing = {posterId: "u1", title: "Barmen"}} = {}) {
  if (listing) db.seed("listings/L1", listing);
  if (credits !== null) db.seed("user_profiles/u1", credits === undefined ? {displayName: "Ayşe"} : {freeBoostCredits: credits});
}

function assertNoBoostWritten() {
  assert.deepEqual(db.list("boosts"), []);
  assert.deepEqual(db.list("boost_purchases"), []);
  assert.equal(db.read("listings/L1")?.isBoosted, undefined);
}

describe("redeemFreeBoost — guards", () => {
  useFreshState();

  test("unauthenticated → unauthenticated", async () => {
    await rejectsWithCode(redeem(null, {listingId: "L1"}), "unauthenticated");
  });

  test("missing listingId, empty payload or null payload → invalid-argument", async () => {
    await rejectsWithCode(redeem("u1", {}), "invalid-argument");
    await rejectsWithCode(redeem("u1", {listingId: ""}), "invalid-argument");
    await rejectsWithCode(redeem("u1", null), "invalid-argument");
  });

  for (const [label, credits] of [["0 credits", 0], ["negative credits", -3], ["no freeBoostCredits field", undefined]]) {
    test(`${label} → failed-precondition, nothing written`, async () => {
      seed({credits});
      await rejectsWithCode(redeem("u1", {listingId: "L1"}), "failed-precondition");
      assertNoBoostWritten();
    });
  }

  test("caller without a profile document → failed-precondition (no crash on update)", async () => {
    seed({credits: null});
    await rejectsWithCode(redeem("u1", {listingId: "L1"}), "failed-precondition");
    assertNoBoostWritten();
  });

  test("missing listing → not-found and the credit is kept", async () => {
    seed({credits: 2, listing: null});
    await rejectsWithCode(redeem("u1", {listingId: "L1"}), "not-found");
    assert.equal(db.read("user_profiles/u1").freeBoostCredits, 2);
  });

  test("someone else's listing → permission-denied and the credit is kept", async () => {
    seed({credits: 2, listing: {posterId: "other"}});
    await rejectsWithCode(redeem("u1", {listingId: "L1"}), "permission-denied");
    assert.equal(db.read("user_profiles/u1").freeBoostCredits, 2);
    assert.equal(db.read("listings/L1").isBoosted, undefined);
  });
});

describe("redeemFreeBoost — success", () => {
  useFreshState();

  test("decrements the credit and writes a 7-day referral boost", async () => {
    seed({credits: 2});
    const before = Date.now();
    const result = await redeem("u1", {listingId: "L1"});

    const [boost] = db.list("boosts");
    const [purchase] = db.list("boost_purchases");
    const listing = db.read("listings/L1");

    assert.equal(db.read("user_profiles/u1").freeBoostCredits, 1);
    assert.equal(result.success, true);
    assert.equal(result.boostId, boost.id);
    assert.equal(result.purchaseId, purchase.id);

    assert.equal(boost.durationDays, 7);
    assert.equal(boost.price, 0);
    assert.equal(boost.platform, "referral_reward");
    assert.equal(boost.transactionId, `referral_${boost.id}`);
    assert.ok(boost.expiresAt.getTime() >= before + 7 * DAY_MS);

    assert.equal(purchase.durationType, "7");
    assert.equal(purchase.productId, "referral_free_boost");
    assert.equal(purchase.boostId, boost.id);

    assert.equal(listing.isBoosted, true);
    assert.equal(listing.boostType, "referral_free_boost");
    assert.equal(listing.boostPurchaseId, purchase.id);
    assert.equal(listing.title, "Barmen");
  });

  test("the last credit can be spent exactly once even when two redemptions race", async () => {
    seed({credits: 1});
    const results = await Promise.allSettled([redeem("u1", {listingId: "L1"}), redeem("u1", {listingId: "L1"})]);
    assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
    const rejected = results.find((r) => r.status === "rejected");
    assert.equal(rejected.reason.code, "failed-precondition");
    assert.equal(db.read("user_profiles/u1").freeBoostCredits, 0);
    assert.equal(db.list("boosts").length, 1);
  });

  test(
    "BUG-t1-02: boosts.durationType for a free boost is '7' (the value Boost.fromDoc parses)",
    {skip: bug("02", "redeemFreeBoost da boosts.durationType='days7' yazıyor")},
    async () => {
      seed({credits: 1});
      await redeem("u1", {listingId: "L1"});
      assert.equal(db.list("boosts")[0].durationType, "7");
    },
  );

  test(
    "BUG-t1-03: redeeming a free 7-day boost on a listing boosted for 25 more days never shortens it",
    {skip: bug("03", "redeemFreeBoost da boostExpiresAt'i now+7g ile eziyor")},
    async () => {
      const existingExpiry = new Date(Date.now() + 25 * DAY_MS);
      seed({credits: 1, listing: {posterId: "u1", isBoosted: true, boostExpiresAt: existingExpiry}});
      await redeem("u1", {listingId: "L1"});
      assert.ok(db.read("listings/L1").boostExpiresAt.getTime() >= existingExpiry.getTime());
    },
  );
});

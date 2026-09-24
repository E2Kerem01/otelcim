// verifyAndProcessUrgentListingPurchase (paid "acil ihtiyaç" path) and its
// hand-off to sendUrgentListingNotificationOnUpgrade.

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {
  GOOGLE_OAUTH_URL,
  appStoreReturns,
  callAs,
  configureGooglePlaySecrets,
  db,
  fetchCalls,
  fns,
  googlePlayReturns,
  json,
  onFetch,
  rejectsWithCode,
  state,
  updatedEvent,
  useFreshState,
} from "./harness.mjs";

const buyUrgent = (uid, data) => fns.verifyAndProcessUrgentListingPurchase.run(callAs(uid, data));
const buyBoost = (uid, data) => fns.verifyAndProcessBoostPurchase.run(callAs(uid, data));

const request = (overrides = {}) => ({
  listingId: "L1",
  productId: "urgent_listing",
  platform: "google_play",
  purchaseToken: "urgent-token",
  ...overrides,
});

function seedListing(extra = {}) {
  db.seed("listings/L1", {posterId: "u1", title: "Garson", region: "Bodrum", isUrgent: false, ...extra});
}

describe("verifyAndProcessUrgentListingPurchase — validation", () => {
  useFreshState();

  test("unauthenticated → unauthenticated", async () => {
    await rejectsWithCode(buyUrgent(null, request()), "unauthenticated");
  });

  test("missing listingId → invalid-argument", async () => {
    await rejectsWithCode(buyUrgent("u1", request({listingId: ""})), "invalid-argument");
  });

  test("a boost product id is not accepted on the urgent endpoint", async () => {
    await rejectsWithCode(buyUrgent("u1", request({productId: "boost_7_days"})), "invalid-argument", /acil ilan ürünü/);
    assert.equal(fetchCalls.length, 0);
  });

  test("unknown platform → invalid-argument", async () => {
    await rejectsWithCode(buyUrgent("u1", request({platform: "web"})), "invalid-argument");
  });

  test("google_play without token / app_store without receipt → invalid-argument", async () => {
    await rejectsWithCode(buyUrgent("u1", request({purchaseToken: undefined})), "invalid-argument");
    await rejectsWithCode(
      buyUrgent("u1", request({platform: "app_store", purchaseToken: undefined})),
      "invalid-argument",
    );
  });
});

describe("verifyAndProcessUrgentListingPurchase — verification and ownership", () => {
  useFreshState();

  test("asks Google Play about the urgent_listing product, not a client-chosen one", async () => {
    seedListing();
    googlePlayReturns({purchaseState: 0, orderId: "GPA.U1"});
    await buyUrgent("u1", request());
    const publisher = fetchCalls.find((c) => c.url.startsWith("https://androidpublisher"));
    assert.match(publisher.url, /\/purchases\/products\/urgent_listing\/tokens\/urgent-token$/);
  });

  test("a boost token cannot be reused for urgent: Play answers 404 for the wrong product", async () => {
    seedListing();
    configureGooglePlaySecrets();
    onFetch((url) => {
      if (url === GOOGLE_OAUTH_URL) return json(200, {access_token: "t"});
      // The token belongs to boost_7_days, so only that product path resolves.
      return url.includes("/products/boost_7_days/")
        ? json(200, {purchaseState: 0, orderId: "GPA.BOOST"})
        : json(404, {});
    });
    await buyBoost("u1", {listingId: "L1", productId: "boost_7_days", platform: "google_play", purchaseToken: "boost-token"});
    await rejectsWithCode(buyUrgent("u1", request({purchaseToken: "boost-token"})), "permission-denied");
    assert.equal(db.read("listings/L1").isUrgent, false);
  });

  test("an App Store receipt containing only a boost does not unlock urgent", async () => {
    seedListing();
    appStoreReturns({status: 0, receipt: {in_app: [{product_id: "boost_7_days", transaction_id: "b-1"}]}});
    await rejectsWithCode(
      buyUrgent("u1", request({platform: "app_store", verificationData: "r"})),
      "permission-denied",
    );
    assert.deepEqual(db.list("urgent_listing_purchases"), []);
  });

  test("missing listing → not-found; someone else's listing → permission-denied", async () => {
    googlePlayReturns({purchaseState: 0, orderId: "GPA.A"});
    await rejectsWithCode(buyUrgent("u1", request()), "not-found");
    db.seed("listings/L1", {posterId: "other", isUrgent: false});
    googlePlayReturns({purchaseState: 0, orderId: "GPA.B"});
    await rejectsWithCode(buyUrgent("u1", request()), "permission-denied");
    assert.equal(db.read("listings/L1").isUrgent, false);
    assert.deepEqual(db.list("urgent_listing_purchases"), []);
  });

  test("the same orderId twice → already-exists, one purchase record", async () => {
    seedListing();
    googlePlayReturns({purchaseState: 0, orderId: "GPA.SAME"});
    await buyUrgent("u1", request());
    await rejectsWithCode(buyUrgent("u1", request()), "already-exists");
    assert.equal(db.list("urgent_listing_purchases").length, 1);
  });

  test("a store failure leaves the listing non-urgent", async () => {
    seedListing();
    googlePlayReturns({purchaseState: 1, orderId: "GPA.CANCELED"});
    await rejectsWithCode(buyUrgent("u1", request()), "permission-denied");
    assert.equal(db.read("listings/L1").isUrgent, false);
  });
});

describe("verifyAndProcessUrgentListingPurchase — success", () => {
  useFreshState();

  test("records the purchase and flips isUrgent with a back-reference", async () => {
    seedListing();
    appStoreReturns({status: 0, receipt: {in_app: [{product_id: "urgent_listing", transaction_id: "apl-9"}]}});
    const result = await buyUrgent("u1", request({platform: "app_store", purchaseToken: undefined, verificationData: "r"}));

    const [purchase] = db.list("urgent_listing_purchases");
    assert.deepEqual(result, {success: true, purchaseId: purchase.id});
    assert.equal(purchase.transactionId, "apl-9");
    assert.equal(purchase.price, 149.99);
    assert.equal(purchase.platform, "app_store");
    assert.equal(purchase.purchaseToken, null);
    assert.equal(purchase.verificationData, "r");
    assert.equal(purchase.status, "completed");

    const listing = db.read("listings/L1");
    assert.equal(listing.isUrgent, true);
    assert.equal(listing.urgentListingPurchaseId, purchase.id);
    assert.ok(listing.updatedAt instanceof Date);
  });

  test("the resulting false → true update fans out exactly one regional push", async () => {
    seedListing();
    const before = db.read("listings/L1");
    googlePlayReturns({purchaseState: 0, orderId: "GPA.PUSH"});
    await buyUrgent("u1", request());
    const after = db.read("listings/L1");

    await fns.sendUrgentListingNotificationOnUpgrade.run(updatedEvent({listingId: "L1"}, before, after));
    assert.equal(state.sends.length, 1);
    assert.equal(state.sends[0].topic, "region_bodrum");
    assert.equal(state.sends[0].data.listingId, "L1");
  });
});

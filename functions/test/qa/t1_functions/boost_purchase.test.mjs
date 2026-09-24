// verifyAndProcessBoostPurchase + the store verification helpers it drives
// (verifyGooglePlayPurchase, getGooglePlayAccessToken, verifyAppStorePurchase,
// callAppleVerifyReceipt).

import assert from "node:assert/strict";
import {describe, test} from "node:test";
import {
  APPLE_PROD_URL,
  APPLE_SANDBOX_URL,
  DAY_MS,
  GOOGLE_OAUTH_URL,
  appStoreReturns,
  bug,
  callAs,
  configureAppStoreSecret,
  configureGooglePlaySecrets,
  db,
  fetchCalls,
  fns,
  googlePlayReturns,
  json,
  onFetch,
  rejectsWithCode,
  state,
  useFreshState,
} from "./harness.mjs";

const buy = (uid, data) => fns.verifyAndProcessBoostPurchase.run(callAs(uid, data));

const googleRequest = (overrides = {}) => ({
  listingId: "L1",
  productId: "boost_14_days",
  platform: "google_play",
  purchaseToken: "token-abc",
  ...overrides,
});

const appleRequest = (overrides = {}) => ({
  listingId: "L1",
  productId: "boost_7_days",
  platform: "app_store",
  verificationData: "base64-receipt",
  ...overrides,
});

function seedOwnListing(extra = {}) {
  db.seed("listings/L1", {posterId: "u1", title: "Resepsiyonist", status: "active", ...extra});
}

function assertNothingWritten() {
  assert.deepEqual(db.list("boosts"), []);
  assert.deepEqual(db.list("boost_purchases"), []);
  assert.equal(db.read("listings/L1")?.isBoosted, undefined);
}

describe("verifyAndProcessBoostPurchase — request validation", () => {
  useFreshState();

  test("rejects an unauthenticated caller before touching the network", async () => {
    await rejectsWithCode(buy(null, googleRequest()), "unauthenticated");
    assert.equal(fetchCalls.length, 0);
  });

  test("rejects missing listingId or productId", async () => {
    await rejectsWithCode(buy("u1", googleRequest({listingId: undefined})), "invalid-argument");
    await rejectsWithCode(buy("u1", googleRequest({productId: ""})), "invalid-argument");
  });

  test("rejects an unknown boost product id", async () => {
    await rejectsWithCode(buy("u1", googleRequest({productId: "boost_999_days"})), "invalid-argument", /Geçersiz boost/);
  });

  test("rejects the urgent_listing product (it has its own callable)", async () => {
    await rejectsWithCode(buy("u1", googleRequest({productId: "urgent_listing"})), "invalid-argument");
  });

  test(
    "BUG-t1-08: an inherited Object property ('constructor') is rejected as an unknown product",
    {skip: bug("08", "BOOST_PRODUCTS[productId] prototype anahtarlarını kabul ediyor; sadece mağaza doğrulaması kurtarıyor")},
    async () => {
      // BOOST_PRODUCTS is a plain object literal, so "constructor"/"toString"
      // resolve through the prototype. Today the request reaches the store
      // and, if the store answered positively, a boost with NaN expiry
      // would be written.
      seedOwnListing();
      googlePlayReturns();
      await rejectsWithCode(buy("u1", googleRequest({productId: "constructor"})), "invalid-argument");
      assert.equal(fetchCalls.length, 0);
    },
  );

  test("rejects a missing platform and BoostService's default 'in_app_purchase'", async () => {
    await rejectsWithCode(buy("u1", googleRequest({platform: undefined})), "invalid-argument", /Geçersiz platform/);
    await rejectsWithCode(buy("u1", googleRequest({platform: "in_app_purchase"})), "invalid-argument", /Geçersiz platform/);
    assert.equal(fetchCalls.length, 0);
  });

  test("google_play without purchaseToken is invalid-argument", async () => {
    await rejectsWithCode(buy("u1", googleRequest({purchaseToken: undefined})), "invalid-argument", /purchaseToken/);
  });

  test("app_store without verificationData is invalid-argument", async () => {
    await rejectsWithCode(buy("u1", appleRequest({verificationData: ""})), "invalid-argument", /verificationData/);
  });
});

describe("verifyAndProcessBoostPurchase — Google Play verification", () => {
  useFreshState();

  test("missing Play secrets → failed-precondition, no network call", async () => {
    seedOwnListing();
    await rejectsWithCode(buy("u1", googleRequest()), "failed-precondition");
    state.secrets.PLAY_SERVICE_ACCOUNT_JSON = "{}";
    await rejectsWithCode(buy("u1", googleRequest()), "failed-precondition"); // package name still empty
    assert.equal(fetchCalls.length, 0);
  });

  test("malformed service-account JSON → internal", async () => {
    configureGooglePlaySecrets();
    state.secrets.PLAY_SERVICE_ACCOUNT_JSON = "{not json";
    await rejectsWithCode(buy("u1", googleRequest()), "internal", /geçersiz JSON/);
  });

  test("service account without private_key → internal", async () => {
    configureGooglePlaySecrets();
    state.secrets.PLAY_SERVICE_ACCOUNT_JSON = JSON.stringify({client_email: "x@y"});
    await rejectsWithCode(buy("u1", googleRequest()), "internal", /private_key/);
  });

  test("signs an RS256 assertion for the androidpublisher scope, issued by client_email", async () => {
    seedOwnListing();
    googlePlayReturns();
    await buy("u1", googleRequest());
    assert.equal(state.jwtCalls.length, 1);
    const {payload, options} = state.jwtCalls[0];
    assert.equal(payload.scope, "https://www.googleapis.com/auth/androidpublisher");
    assert.equal(payload.aud, GOOGLE_OAUTH_URL);
    assert.equal(payload.exp - payload.iat, 3600);
    assert.deepEqual(options, {algorithm: "RS256", issuer: "play-verifier@otelcim.iam.gserviceaccount.com"});
  });

  test("OAuth token endpoint 500 → internal", async () => {
    configureGooglePlaySecrets();
    onFetch(() => json(500, {error: "boom"}));
    await rejectsWithCode(buy("u1", googleRequest()), "internal", /kimlik doğrulaması/);
  });

  test("OAuth 200 without access_token → internal", async () => {
    configureGooglePlaySecrets();
    onFetch(() => json(200, {}));
    await rejectsWithCode(buy("u1", googleRequest()), "internal", /erişim jetonu/);
  });

  test("queries the Publisher API with URL-encoded package/product/token and a Bearer token", async () => {
    seedOwnListing();
    googlePlayReturns();
    await buy("u1", googleRequest({purchaseToken: "tok/with?odd&chars"}));
    const publisher = fetchCalls.find((c) => c.url.startsWith("https://androidpublisher"));
    assert.equal(
      publisher.url,
      "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.otelcim.app" +
        "/purchases/products/boost_14_days/tokens/tok%2Fwith%3Fodd%26chars",
    );
    assert.equal(publisher.init.headers.Authorization, "Bearer ya29.fake");
  });

  test("Publisher API 404 (unknown token) → permission-denied, nothing written", async () => {
    seedOwnListing();
    configureGooglePlaySecrets();
    onFetch((url) => (url === GOOGLE_OAUTH_URL ? json(200, {access_token: "t"}) : json(404, {})));
    await rejectsWithCode(buy("u1", googleRequest()), "permission-denied");
    assertNothingWritten();
  });

  for (const [label, purchaseState] of [["canceled (1)", 1], ["pending (2)", 2], ["missing", undefined]]) {
    test(`purchaseState ${label} → permission-denied, nothing written`, async () => {
      seedOwnListing();
      googlePlayReturns({purchaseState, orderId: "GPA.1"});
      await rejectsWithCode(buy("u1", googleRequest()), "permission-denied");
      assertNothingWritten();
    });
  }

  test("purchased but without orderId → permission-denied", async () => {
    seedOwnListing();
    googlePlayReturns({purchaseState: 0});
    await rejectsWithCode(buy("u1", googleRequest()), "permission-denied", /orderId/);
    assertNothingWritten();
  });
});

describe("verifyAndProcessBoostPurchase — App Store verification", () => {
  useFreshState();

  test("missing shared secret → failed-precondition, no network call", async () => {
    await rejectsWithCode(buy("u1", appleRequest()), "failed-precondition");
    assert.equal(fetchCalls.length, 0);
  });

  test("posts receipt-data, password and exclude-old-transactions to production first", async () => {
    seedOwnListing();
    appStoreReturns({status: 0, latest_receipt_info: [{product_id: "boost_7_days", transaction_id: "1000"}]});
    await buy("u1", appleRequest());
    assert.equal(fetchCalls.length, 1);
    assert.equal(fetchCalls[0].url, APPLE_PROD_URL);
    assert.deepEqual(JSON.parse(fetchCalls[0].init.body), {
      "receipt-data": "base64-receipt",
      "password": "apple-shared-secret",
      "exclude-old-transactions": true,
    });
  });

  test("status 21007 (sandbox receipt) retries against the sandbox endpoint", async () => {
    seedOwnListing();
    configureAppStoreSecret();
    onFetch((url) =>
      url === APPLE_PROD_URL
        ? json(200, {status: 21007})
        : json(200, {status: 0, receipt: {in_app: [{product_id: "boost_7_days", transaction_id: "sbx-1"}]}}),
    );
    const result = await buy("u1", appleRequest());
    assert.deepEqual(fetchCalls.map((c) => c.url), [APPLE_PROD_URL, APPLE_SANDBOX_URL]);
    assert.equal(result.success, true);
    assert.equal(db.list("boost_purchases")[0].transactionId, "sbx-1");
  });

  test("status 21002 (malformed receipt) → permission-denied", async () => {
    seedOwnListing();
    appStoreReturns({status: 21002});
    await rejectsWithCode(buy("u1", appleRequest()), "permission-denied");
    assertNothingWritten();
  });

  test("receipt without the requested product → permission-denied", async () => {
    seedOwnListing();
    appStoreReturns({status: 0, receipt: {in_app: [{product_id: "boost_30_days", transaction_id: "9"}]}});
    await rejectsWithCode(buy("u1", appleRequest()), "permission-denied", /bulunamadı/);
    assertNothingWritten();
  });

  test("receipt with no transactions at all → permission-denied", async () => {
    seedOwnListing();
    appStoreReturns({status: 0});
    await rejectsWithCode(buy("u1", appleRequest()), "permission-denied");
  });

  test("refunded/cancelled transaction (cancellation_date_ms) → permission-denied", async () => {
    seedOwnListing();
    appStoreReturns({
      status: 0,
      latest_receipt_info: [{product_id: "boost_7_days", transaction_id: "7", cancellation_date_ms: "1700000000000"}],
    });
    await rejectsWithCode(buy("u1", appleRequest()), "permission-denied", /iptal/);
    assertNothingWritten();
  });

  test("latest_receipt_info takes precedence over receipt.in_app", async () => {
    seedOwnListing();
    appStoreReturns({
      status: 0,
      latest_receipt_info: [{product_id: "boost_7_days", transaction_id: "from-latest"}],
      receipt: {in_app: [{product_id: "boost_7_days", transaction_id: "from-in-app"}]},
    });
    await buy("u1", appleRequest());
    assert.equal(db.list("boost_purchases")[0].transactionId, "from-latest");
  });

  test(
    "BUG-t1-07: a non-JSON Apple outage page is surfaced as an HttpsError, not a raw SyntaxError",
    {skip: bug("07", "callAppleVerifyReceipt response.ok kontrol etmiyor; HTML 503 ham SyntaxError fırlatır")},
    async () => {
      seedOwnListing();
      configureAppStoreSecret();
      onFetch(() => new Response("<html>503 Service Unavailable</html>", {status: 503}));
      await rejectsWithCode(buy("u1", appleRequest()), "unavailable");
    },
  );

  test(
    "BUG-t1-06: a receipt that still lists an already-processed transaction verifies the NEW one",
    {skip: bug("06", "verifyAppStorePurchase find() ilk eşleşmeyi alıyor; eski işlem yeni alımı already-exists'e düşürür")},
    async () => {
      // First boost: transaction 1000 processed.
      seedOwnListing();
      appStoreReturns({status: 0, receipt: {in_app: [{product_id: "boost_7_days", transaction_id: "1000"}]}});
      await buy("u1", appleRequest());
      // User pays again for the same consumable; the receipt now lists the old
      // (still unfinished / not yet dropped) transaction first and the new one second.
      appStoreReturns({
        status: 0,
        receipt: {
          in_app: [
            {product_id: "boost_7_days", transaction_id: "1000"},
            {product_id: "boost_7_days", transaction_id: "1001"},
          ],
        },
      });
      const result = await buy("u1", appleRequest());
      assert.equal(result.success, true);
      assert.deepEqual(db.list("boost_purchases").map((p) => p.transactionId).sort(), ["1000", "1001"]);
    },
  );
});

describe("verifyAndProcessBoostPurchase — listing ownership and replay", () => {
  useFreshState();

  test("listing that does not exist → not-found, nothing written", async () => {
    googlePlayReturns();
    await rejectsWithCode(buy("u1", googleRequest({listingId: "missing"})), "not-found");
    assert.deepEqual(db.list("boost_purchases"), []);
  });

  test("someone else's listing → permission-denied, listing untouched", async () => {
    db.seed("listings/L1", {posterId: "owner"});
    googlePlayReturns();
    await rejectsWithCode(buy("intruder", googleRequest()), "permission-denied");
    assert.deepEqual(db.read("listings/L1"), {posterId: "owner"});
    assert.deepEqual(db.list("boosts"), []);
  });

  test("listing document without posterId cannot be boosted by anyone", async () => {
    db.seed("listings/L1", {title: "legacy"});
    googlePlayReturns();
    await rejectsWithCode(buy("u1", googleRequest()), "permission-denied");
  });

  test("replaying the same store orderId a second time → already-exists, still exactly one boost", async () => {
    seedOwnListing();
    googlePlayReturns({purchaseState: 0, orderId: "GPA.REPLAY"});
    await buy("u1", googleRequest());
    await rejectsWithCode(buy("u1", googleRequest()), "already-exists");
    assert.equal(db.list("boosts").length, 1);
    assert.equal(db.list("boost_purchases").length, 1);
  });

  test("a client-chosen transactionId is ignored; the store orderId is what gets recorded", async () => {
    seedOwnListing();
    googlePlayReturns({purchaseState: 0, orderId: "GPA.REAL"});
    await buy("u1", {...googleRequest(), transactionId: "client-fake"});
    assert.equal(db.list("boost_purchases")[0].transactionId, "GPA.REAL");
    assert.equal(db.list("boosts")[0].transactionId, "GPA.REAL");
  });

  test(
    "BUG-t1-01: two concurrent calls with the same purchase token produce only ONE boost",
    {skip: bug("01", "replay kontrolü (query) ve yazma (batch) transaction dışında; eşzamanlı iki çağrı iki boost üretir")},
    async () => {
      seedOwnListing();
      googlePlayReturns({purchaseState: 0, orderId: "GPA.RACE"});
      const results = await Promise.allSettled([buy("u1", googleRequest()), buy("u1", googleRequest())]);
      assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
      assert.equal(db.list("boost_purchases").length, 1);
    },
  );
});

describe("verifyAndProcessBoostPurchase — successful purchase", () => {
  useFreshState();

  test("writes boosts, boost_purchases and flips the listing to boosted for 14 days", async () => {
    seedOwnListing();
    googlePlayReturns({purchaseState: 0, orderId: "GPA.14"});
    const before = Date.now();
    const result = await buy("u1", googleRequest());
    const after = Date.now();

    const [boost] = db.list("boosts");
    const [purchase] = db.list("boost_purchases");
    const listing = db.read("listings/L1");

    assert.equal(result.success, true);
    assert.equal(result.boostId, boost.id);
    assert.equal(result.purchaseId, purchase.id);

    const expires = boost.expiresAt.getTime();
    assert.ok(expires >= before + 14 * DAY_MS && expires <= after + 14 * DAY_MS);
    assert.equal(result.expiresAt, boost.expiresAt.toISOString());

    assert.equal(boost.listingId, "L1");
    assert.equal(boost.userId, "u1");
    assert.equal(boost.durationDays, 14);
    assert.equal(boost.price, 89.99);
    assert.equal(boost.status, "active");
    assert.equal(boost.platform, "google_play");
    assert.equal(boost.transactionId, "GPA.14");

    assert.equal(purchase.boostId, boost.id);
    assert.equal(purchase.durationType, "14");
    assert.equal(purchase.productId, "boost_14_days");
    assert.equal(purchase.purchaseToken, "token-abc");
    assert.equal(purchase.verificationData, null);
    assert.equal(purchase.status, "completed");

    assert.equal(listing.isBoosted, true);
    assert.equal(listing.boostType, "boost_14_days");
    assert.equal(listing.boostPurchaseId, purchase.id);
    assert.equal(listing.boostExpiresAt.getTime(), expires);
    assert.equal(listing.title, "Resepsiyonist", "unrelated listing fields are preserved");
  });

  for (const [productId, days, price] of [["boost_7_days", 7, 49.99], ["boost_30_days", 30, 149.99]]) {
    test(`${productId} → ${days}-day boost priced ${price}`, async () => {
      seedOwnListing();
      appStoreReturns({status: 0, receipt: {in_app: [{product_id: productId, transaction_id: `t-${days}`}]}});
      const before = Date.now();
      await buy("u1", appleRequest({productId}));
      const [boost] = db.list("boosts");
      assert.equal(boost.durationDays, days);
      assert.equal(boost.price, price);
      assert.equal(boost.platform, "app_store");
      assert.ok(boost.expiresAt.getTime() >= before + days * DAY_MS);
      assert.equal(db.list("boost_purchases")[0].verificationData, "base64-receipt");
    });
  }

  test(
    "BUG-t1-02: boosts.durationType uses the format Boost.fromDoc parses ('7' | '14' | '30')",
    {skip: bug("02", "sunucu boosts.durationType='days14' yazıyor, Dart Boost.fromDoc '14' bekliyor → her boost 7 günlük görünür")},
    async () => {
      seedOwnListing();
      googlePlayReturns();
      await buy("u1", googleRequest());
      assert.equal(db.list("boosts")[0].durationType, "14");
    },
  );

  test(
    "BUG-t1-03: buying a 7-day boost on a listing boosted for 25 more days never shortens the boost",
    {skip: bug("03", "uzatma expiresAt = now + süre ile üzerine yazıyor; kalan 25 gün 7 güne iniyor")},
    async () => {
      const existingExpiry = new Date(Date.now() + 25 * DAY_MS);
      seedOwnListing({isBoosted: true, boostExpiresAt: existingExpiry, boostType: "boost_30_days"});
      appStoreReturns({status: 0, receipt: {in_app: [{product_id: "boost_7_days", transaction_id: "ext-1"}]}});
      await buy("u1", appleRequest());
      const newExpiry = db.read("listings/L1").boostExpiresAt.getTime();
      assert.ok(
        newExpiry >= existingExpiry.getTime(),
        `boost shrank from +25d to +${Math.round((newExpiry - Date.now()) / DAY_MS)}d`,
      );
    },
  );
});

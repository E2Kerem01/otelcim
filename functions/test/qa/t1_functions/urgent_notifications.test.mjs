// "Acil ihtiyaç" server side: the regional push (notifyRegionOfUrgentListing via
// sendUrgentListingNotification / sendUrgentListingNotificationOnUpgrade) and
// the free-slot policing in reconcileFreeUrgentListingOnCreate.

import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {describe, test} from "node:test";
import {bug, createdEvent, db, errorLogs, fns, state, updatedEvent, useFreshState} from "./harness.mjs";

const created = (listing, listingId = "L1") => createdEvent({listingId}, listing);
const onCreate = (listing, listingId) => fns.sendUrgentListingNotification.run(created(listing, listingId));
const onUpgrade = (before, after) => fns.sendUrgentListingNotificationOnUpgrade.run(updatedEvent({listingId: "L1"}, before, after));
const reconcile = (listing, listingId = "L1") => fns.reconcileFreeUrgentListingOnCreate.run(created(listing, listingId));

const urgentListing = (overrides = {}) => ({posterId: "u1", title: "Acil Garson", region: "bodrum", isUrgent: true, ...overrides});

// Region → topic table. The Dart side (regionTopicName in
// lib/shared/services/notification_service.dart) uses the same trim/lowercase/
// regex; every expected value below was produced by running the real Dart
// regionTopicName on the Dart VM (table in FINDINGS.md), so both sides agree.
// "İzmir" is the one input where they do not — see BUG-t1-21.
const TOPIC_TABLE = [
  ["bodrum", "region_bodrum"],
  ["Bodrum", "region_bodrum"],
  ["  Antalya ", "region_antalya"],
  ["Ege Bölgesi", "region_ege_b_lgesi"],
  ["Muğla", "region_mu_la"],
  ["Çeşme", "region__e_me"],
  ["KAPADOKYA", "region_kapadokya"],
  ["🏖️ Bodrum", "region_____bodrum"],
  ["side-manavgat.v2~%", "region_side-manavgat.v2~%"],
];

describe("notifyRegionOfUrgentListing — topic naming", () => {
  useFreshState();

  for (const [region, topic] of TOPIC_TABLE) {
    test(`region ${JSON.stringify(region)} → topic ${topic}`, async () => {
      await onCreate(urgentListing({region}));
      assert.equal(state.sends[0].topic, topic);
      assert.match(state.sends[0].topic, /^[a-zA-Z0-9-_.~%]+$/, "FCM topic charset");
      assert.equal(state.sends[0].data.region, region, "data.region keeps the original value");
    });
  }

  test("every TourismRegion id the create form can store maps to region_<id>", async () => {
    const source = await readFile(new URL("../../../../lib/features/discovery/domain/tourism_region.dart", import.meta.url), "utf8");
    const ids = [...source.matchAll(/\bid:\s*'([^']+)'/g)].map((m) => m[1]);
    assert.ok(ids.length >= 10, `parsed ${ids.length} region ids`);
    for (const [i, id] of ids.entries()) {
      await onCreate(urgentListing({region: id}), `L${i}`);
    }
    assert.deepEqual(state.sends.map((m) => m.topic), ids.map((id) => `region_${id}`));
  });

  test(
    "BUG-t1-21: 'İzmir' maps to the same topic the Dart client subscribes to (region_izmir)",
    {skip: bug("21", "JS 'İ'.toLowerCase() → 'i̇' (U+0307) → 'region_i_zmir'; Dart → 'region_izmir'; push kaybolur")},
    async () => {
      await onCreate(urgentListing({region: "İzmir"}));
      assert.equal(state.sends[0].topic, "region_izmir");
    },
  );

  test("an empty region sends nothing", async () => {
    await onCreate(urgentListing({region: ""}));
    await onCreate(urgentListing({region: undefined}));
    assert.equal(state.sends.length, 0);
  });

  test(
    "BUG-t1-20: a whitespace-only region is treated as missing, not pushed to the catch-all topic 'region_'",
    {skip: bug("20", "'   ' trim sonrası boş; 'region_' konusuna push gidiyor (Dart selectRegion boş bölgeyi reddediyor)")},
    async () => {
      await onCreate(urgentListing({region: "   "}));
      assert.equal(state.sends.length, 0);
    },
  );
});

describe("sendUrgentListingNotification (create trigger)", () => {
  useFreshState();

  test("an urgent listing pushes once to its region with the urgent payload", async () => {
    await onCreate(urgentListing());
    assert.equal(state.sends.length, 1);
    const [msg] = state.sends;
    assert.equal(msg.token, undefined, "topic message, not a device token");
    assert.deepEqual(msg.notification, {title: "Acil Personel İhtiyacı", body: "Acil Garson için hemen başvurun."});
    assert.deepEqual(msg.data, {type: "urgent_listing", listingId: "L1", region: "bodrum"});
    assert.equal(msg.android.notification.channelId, "urgent_listings");
  });

  test("a listing without a title still gets a sensible body", async () => {
    await onCreate(urgentListing({title: undefined}));
    assert.equal(state.sends[0].notification.body, "Yeni ilan için hemen başvurun.");
  });

  test("non-urgent listings (false, missing, or the string 'true') never push", async () => {
    await onCreate(urgentListing({isUrgent: false}));
    await onCreate(urgentListing({isUrgent: undefined}));
    await onCreate(urgentListing({isUrgent: "true"}));
    await onCreate(undefined);
    assert.equal(state.sends.length, 0);
  });

  test("an FCM failure is logged with the topic and not rethrown", async () => {
    state.sendImpl = () => {
      throw new Error("quota exceeded");
    };
    await onCreate(urgentListing());
    assert.equal(errorLogs().length, 1);
    assert.equal(errorLogs()[0].ctx.topic, "region_bodrum");
  });

  test(
    "BUG-t1-04: a poster whose free urgent slot is already spent cannot push to the whole region",
    {skip: bug("04", "sendUrgentListingNotification reconcile'dan bağımsız; hak bitmiş kullanıcı da bölgeye push yollatıyor (spam)")},
    async () => {
      db.seed("user_profiles/u1", {hasUsedFreeUrgentListing: true});
      db.seed("listings/L1", urgentListing());
      // Both create triggers fire for the same event; run the policing one first
      // (the most favourable order for the current code).
      await reconcile(urgentListing());
      await onCreate(urgentListing());
      assert.equal(db.read("listings/L1").isUrgent, false, "reconcile downgraded the listing");
      assert.equal(state.sends.length, 0, "…but the region was notified anyway");
    },
  );
});

describe("sendUrgentListingNotificationOnUpgrade (update trigger)", () => {
  useFreshState();
  const base = urgentListing({isUrgent: false});

  test("false → true (paid upgrade) pushes once", async () => {
    await onUpgrade(base, {...base, isUrgent: true});
    assert.equal(state.sends.length, 1);
    assert.equal(state.sends[0].topic, "region_bodrum");
  });

  test("missing → true (legacy listing without the field) pushes once", async () => {
    const {isUrgent: _omit, ...legacy} = base;
    await onUpgrade(legacy, {...legacy, isUrgent: true});
    assert.equal(state.sends.length, 1);
  });

  test("true → true edits (e.g. title change) never re-notify", async () => {
    await onUpgrade(urgentListing(), urgentListing({title: "Acil Komi"}));
    assert.equal(state.sends.length, 0);
  });

  test("reconcile's true → false downgrade does not notify", async () => {
    await onUpgrade(urgentListing(), urgentListing({isUrgent: false}));
    assert.equal(state.sends.length, 0);
  });

  test("false → false edits and deletes (no after data) do not notify", async () => {
    await onUpgrade(base, {...base, title: "x"});
    await onUpgrade(base, undefined);
    assert.equal(state.sends.length, 0);
  });

  test("an update event without before data but urgent after is treated as an upgrade", async () => {
    await onUpgrade(undefined, urgentListing());
    assert.equal(state.sends.length, 1);
  });

  test("the upgrade uses the region of the AFTER state", async () => {
    await onUpgrade({...base, region: "bodrum"}, {...base, region: "fethiye", isUrgent: true});
    assert.equal(state.sends[0].topic, "region_fethiye");
  });
});

describe("reconcileFreeUrgentListingOnCreate", () => {
  useFreshState();

  test("a non-urgent listing is ignored entirely (no reads, no writes)", async () => {
    db.seed("listings/L1", urgentListing({isUrgent: false}));
    await reconcile(urgentListing({isUrgent: false}));
    assert.equal(db.stats.reads, 0);
    assert.equal(db.stats.commits, 0);
  });

  test("an urgent listing without posterId is left alone", async () => {
    db.seed("listings/L1", urgentListing({posterId: undefined}));
    await reconcile(urgentListing({posterId: undefined}));
    assert.equal(db.stats.commits, 0);
  });

  test("first urgent listing consumes the free slot and stays urgent", async () => {
    db.seed("user_profiles/u1", {displayName: "Otel"});
    db.seed("listings/L1", urgentListing());
    await reconcile(urgentListing());
    assert.equal(db.read("user_profiles/u1").hasUsedFreeUrgentListing, true);
    assert.equal(db.read("listings/L1").isUrgent, true);
  });

  test("hasUsedFreeUrgentListing: false explicitly behaves like the first time", async () => {
    db.seed("user_profiles/u1", {hasUsedFreeUrgentListing: false});
    db.seed("listings/L1", urgentListing());
    await reconcile(urgentListing());
    assert.equal(db.read("listings/L1").isUrgent, true);
    assert.equal(db.read("user_profiles/u1").hasUsedFreeUrgentListing, true);
  });

  test("second urgent listing after the free slot was spent is downgraded", async () => {
    db.seed("user_profiles/u1", {hasUsedFreeUrgentListing: true});
    db.seed("listings/L2", urgentListing());
    await reconcile(urgentListing(), "L2");
    assert.equal(db.read("listings/L2").isUrgent, false);
    assert.equal(db.read("listings/L2").title, "Acil Garson", "only isUrgent is touched");
  });

  test("a poster without a profile document cannot keep an urgent listing", async () => {
    db.seed("listings/L1", urgentListing());
    await reconcile(urgentListing());
    assert.equal(db.read("listings/L1").isUrgent, false);
    assert.equal(db.read("user_profiles/u1"), undefined, "no profile is created");
  });

  test("two urgent listings created at the same time: exactly one keeps the free slot", async () => {
    db.seed("user_profiles/u1", {});
    db.seed("listings/A", urgentListing());
    db.seed("listings/B", urgentListing());
    await Promise.all([reconcile(urgentListing(), "A"), reconcile(urgentListing(), "B")]);
    const urgentCount = ["A", "B"].filter((id) => db.read(`listings/${id}`).isUrgent).length;
    assert.equal(urgentCount, 1);
    assert.equal(db.read("user_profiles/u1").hasUsedFreeUrgentListing, true);
  });

  test("a listing deleted before reconcile runs does not crash the trigger", async () => {
    db.seed("user_profiles/u1", {hasUsedFreeUrgentListing: true});
    await reconcile(urgentListing()); // listings/L1 does not exist → tx.update fails
    assert.equal(errorLogs().length, 1);
    assert.match(errorLogs()[0].msg, /uzlaştırılamadı/);
  });
});

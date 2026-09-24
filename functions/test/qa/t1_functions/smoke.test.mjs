import assert from "node:assert/strict";
import {test} from "node:test";
import {fns} from "./harness.mjs";

test("index.ts loads against the fakes and exports every function", () => {
  assert.deepEqual(Object.keys(fns).sort(), [
    "grantReferralRewardOnConversationCreated",
    "grantReferralRewardOnListingCreated",
    "reconcileFreeUrgentListingOnCreate",
    "redeemFreeBoost",
    "sendChatMessageNotification",
    "sendInterviewConfirmedNotification",
    "sendSeasonalReminders",
    "sendUrgentListingNotification",
    "sendUrgentListingNotificationOnUpgrade",
    "verifyAndProcessBoostPurchase",
    "verifyAndProcessUrgentListingPurchase",
  ]);
});

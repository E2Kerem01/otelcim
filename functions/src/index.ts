import * as jwt from "jsonwebtoken";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {defineSecret} from "firebase-functions/params";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

// --- Store purchase verification secrets ---------------------------------
// Configure with `firebase functions:secrets:set <NAME>` once the app is
// registered on each store. See verifyGooglePlayPurchase / verifyAppStorePurchase.
const playServiceAccountJson = defineSecret("PLAY_SERVICE_ACCOUNT_JSON");
const androidPackageName = defineSecret("ANDROID_PACKAGE_NAME");
const appStoreSharedSecret = defineSecret("APPSTORE_SHARED_SECRET");

export const sendChatMessageNotification = onDocumentCreated(
  {
    document: "conversations/{conversationId}/messages/{messageId}",
    region: "europe-west1",
  },
  async (event) => {
    const message = event.data?.data();
    const conversationId = event.params.conversationId;

    if (!message) {
      logger.info("Mesaj verisi bulunamadı.", {conversationId});
      return;
    }

    const senderId = message.senderId as string | undefined;
    const text = message.text as string | undefined;
    if (!senderId || !text) {
      logger.info("senderId veya text eksik; bildirim atlandı.", {conversationId});
      return;
    }

    try {
      const conversationSnapshot = await db.collection("conversations").doc(conversationId).get();
      if (!conversationSnapshot.exists) {
        logger.info("Konuşma bulunamadı; bildirim atlandı.", {conversationId});
        return;
      }

      const conversation = conversationSnapshot.data() ?? {};
      const posterId = conversation.posterId as string | undefined;
      const seekerId = conversation.seekerId as string | undefined;
      const recipientId = senderId === posterId ? seekerId : senderId === seekerId ? posterId : undefined;

      if (!recipientId) {
        logger.info("Alıcı belirlenemedi; bildirim atlandı.", {conversationId, senderId});
        return;
      }

      const [recipientSnapshot, senderSnapshot] = await Promise.all([
        db.collection("user_profiles").doc(recipientId).get(),
        db.collection("user_profiles").doc(senderId).get(),
      ]);

      const recipientData = recipientSnapshot.data();
      const notificationPreferences = recipientData?.notificationPreferences;
      if (notificationPreferences && notificationPreferences.messages === false) {
        logger.info("Alıcı mesaj bildirimlerini kapatmış; bildirim atlandı.", {conversationId, recipientId});
        return;
      }

      const token = recipientData?.fcmToken as string | undefined;
      if (!token) {
        logger.info("Alıcının FCM token'ı yok; bildirim atlandı.", {conversationId, recipientId});
        return;
      }

      const sender = senderSnapshot.data() ?? {};
      const senderName = (sender.displayName ?? sender.hotelName ?? sender.email ?? "Yeni mesaj") as string;
      const preview = text.length > 120 ? `${text.substring(0, 117)}...` : text;

      await getMessaging().send({
        token,
        notification: {
          title: senderName,
          body: preview,
        },
        data: {
          type: "chat",
          conversationId,
          senderId,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "messages",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      logger.info("Mesaj bildirimi gönderildi.", {conversationId, recipientId});
    } catch (error) {
      // Mesaj yazma akışını etkilememek için hata yeniden fırlatılmaz.
      logger.error("Mesaj bildirimi gönderilemedi.", {conversationId, error});
    }
  },
);

export const sendSeasonalReminders = onDocumentCreated(
  {
    document: "seasonal_subscriptions/{subscriptionId}",
    region: "europe-west1",
  },
  async (event) => {
    const sub = event.data?.data();
    const subscriptionId = event.params.subscriptionId;

    if (!sub || sub.enabled === false) {
      logger.info("Sezonluk abonelik aktif değil veya veri yok.", {subscriptionId});
      return;
    }

    const userId = sub.userId as string | undefined;
    if (!userId) {
      logger.info("Abonelikte userId bulunamadı.", {subscriptionId});
      return;
    }

    try {
      const userSnapshot = await db.collection("user_profiles").doc(userId).get();
      if (!userSnapshot.exists) {
        logger.info("Kullanıcı profili bulunamadı.", {userId});
        return;
      }

      const userData = userSnapshot.data() ?? {};
      const prefs = userData.notificationPreferences;
      if (prefs && prefs.seasonalReminders === false) {
        logger.info("Kullanıcı sezonluk hatırlatıcı bildirimlerini kapatmış; bildirim atlandı.", {userId});
        return;
      }

      const token = userData.fcmToken as string | undefined;
      if (!token) {
        logger.info("Kullanıcının FCM token'ı yok; bildirim atlandı.", {userId});
        return;
      }

      const city = (sub.city as string) || "Tüm Bölgeler";
      const season = (sub.season as string) || "Yaklaşan Sezon";

      await getMessaging().send({
        token,
        notification: {
          title: "Sezonluk İşe Alım Hatırlatması",
          body: `${season} için ${city} bölgesinde işe alım dönemi yaklaşıyor. Yeni ilanlara hemen göz atın!`,
        },
        data: {
          type: "seasonal_reminder",
          subscriptionId,
          city,
          season,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "reminders",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });

      logger.info("Sezonluk hatırlatma bildirimi başarıyla gönderildi.", {userId, subscriptionId});
    } catch (error) {
      logger.error("Sezonluk hatırlatma bildirimi gönderilemedi.", {subscriptionId, error});
    }
  },
);

/**
 * Pushes an "urgent listing" notification to everyone subscribed to the
 * listing's region topic. Shared by the create trigger (free urgent slot,
 * listing born with isUrgent: true) and the update trigger (paid urgent
 * slot, verifyAndProcessUrgentListingPurchase flips isUrgent false -> true
 * after the listing already exists).
 */
async function notifyRegionOfUrgentListing(
  listingId: string,
  listing: FirebaseFirestore.DocumentData,
): Promise<void> {
  const region = listing.region as string | undefined;
  if (!region) {
    logger.info("Acil ilanın bölgesi yok; bildirim atlandı.", {listingId});
    return;
  }

  const safeRegion = region.trim().toLowerCase().replace(/[^a-z0-9-_.~%]/g, "_");
  const topic = `region_${safeRegion}`;
  try {
    await getMessaging().send({
      topic,
      notification: {
        title: "Acil Personel İhtiyacı",
        body: `${(listing.title as string | undefined) ?? "Yeni ilan"} için hemen başvurun.`,
      },
      data: {
        type: "urgent_listing",
        listingId,
        region,
      },
      android: {
        priority: "high",
        notification: {channelId: "urgent_listings"},
      },
      apns: {payload: {aps: {sound: "default"}}},
    });
    logger.info("Acil ilan bildirimi gönderildi.", {listingId, topic});
  } catch (error) {
    logger.error("Acil ilan bildirimi gönderilemedi.", {listingId, topic, error});
  }
}

export const sendUrgentListingNotification = onDocumentCreated(
  {
    document: "listings/{listingId}",
    region: "europe-west1",
  },
  async (event) => {
    const listing = event.data?.data();
    const listingId = event.params.listingId;
    if (!listing || listing.isUrgent !== true) {
      return;
    }
    await notifyRegionOfUrgentListing(listingId, listing);
  },
);

export const sendUrgentListingNotificationOnUpgrade = onDocumentUpdated(
  {
    document: "listings/{listingId}",
    region: "europe-west1",
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const listingId = event.params.listingId;
    // Only the false -> true transition (a paid urgent upgrade). A listing
    // that was already urgent, or edits that leave isUrgent untouched, must
    // not re-notify the region.
    if (!after || after.isUrgent !== true || before?.isUrgent === true) {
      return;
    }
    await notifyRegionOfUrgentListing(listingId, after);
  },
);

export const sendInterviewConfirmedNotification = onDocumentUpdated(
  {
    document: "conversations/{conversationId}/interview_slots/{slotId}",
    region: "europe-west1",
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    const conversationId = event.params.conversationId;
    const slotId = event.params.slotId;

    if (!afterData || afterData.status !== "confirmed" || beforeData?.status === "confirmed") {
      return;
    }

    try {
      const conversationDoc = await db.collection("conversations").doc(conversationId).get();
      if (!conversationDoc.exists) {
        logger.info("Konuşma bulunamadı.", {conversationId});
        return;
      }

      const conversationData = conversationDoc.data() ?? {};
      const posterId = conversationData.posterId as string | undefined;
      const seekerId = conversationData.seekerId as string | undefined;

      const participantIds = [posterId, seekerId].filter((id): id is string => Boolean(id));

      for (const participantId of participantIds) {
        const userDoc = await db.collection("user_profiles").doc(participantId).get();
        if (!userDoc.exists) continue;

        const userData = userDoc.data() ?? {};
        const token = userData.fcmToken as string | undefined;
        if (!token) continue;

        await getMessaging().send({
          token,
          notification: {
            title: "Mülakat Onaylandı",
            body: "Mülakat zamanı tarafınıza ve karşı tarafa onaylandı.",
          },
          data: {
            type: "interview_confirmed",
            conversationId,
            slotId,
          },
          android: {
            priority: "high",
            notification: {
              channelId: "messages",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        });
      }

      logger.info("Mülakat onay bildirimi gönderildi.", {conversationId, slotId});
    } catch (error) {
      logger.error("Mülakat onay bildirimi gönderilemedi.", {conversationId, slotId, error});
    }
  },
);

interface BoostPurchaseRequest {
  listingId: string;
  productId: string;
  purchaseToken?: string;
  verificationData?: string;
  platform?: string;
}

const BOOST_PRODUCTS: Record<string, { durationDays: number; price: number; durationTypeEnum: string; durationTypeStr: string }> = {
  "boost_7_days": { durationDays: 7, price: 49.99, durationTypeEnum: "days7", durationTypeStr: "7" },
  "boost_14_days": { durationDays: 14, price: 89.99, durationTypeEnum: "days14", durationTypeStr: "14" },
  "boost_30_days": { durationDays: 30, price: 149.99, durationTypeEnum: "days30", durationTypeStr: "30" },
};

// The single paid "acil ihtiyaç" product. `price` here is only the
// bookkeeping fallback written onto the purchase record; the real charge is
// whatever the store product is configured at. Keep the id in sync with
// PaymentService._productIds and UrgentListingService.urgentListingProductId.
const URGENT_LISTING_PRODUCT_ID = "urgent_listing";
const URGENT_LISTING_PRICE = 149.99;

type SupportedStorePlatform = "google_play" | "app_store";

async function getGooglePlayAccessToken(serviceAccountJson: string): Promise<string> {
  let credentials: { client_email?: string; private_key?: string };
  try {
    credentials = JSON.parse(serviceAccountJson);
  } catch {
    throw new HttpsError("internal", "Play servis hesabı anahtarı okunamadı (geçersiz JSON).");
  }
  if (!credentials.client_email || !credentials.private_key) {
    throw new HttpsError("internal", "Play servis hesabı anahtarında client_email/private_key eksik.");
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = jwt.sign(
    {
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    },
    credentials.private_key,
    {algorithm: "RS256", issuer: credentials.client_email}
  );

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    logger.error("Google OAuth2 erişim jetonu alınamadı.", {status: response.status});
    throw new HttpsError("internal", "Google Play kimlik doğrulaması başarısız.");
  }

  const body = (await response.json()) as { access_token?: string };
  if (!body.access_token) {
    throw new HttpsError("internal", "Google Play erişim jetonu alınamadı.");
  }
  return body.access_token;
}

/**
 * Verifies a Google Play purchase token against the Android Publisher API
 * (purchases.products.get) and returns the store's authoritative orderId,
 * to be used as the canonical transaction id — never trust a client-chosen
 * transactionId, since a client could reuse a genuine token/receipt while
 * claiming a fresh id to bypass replay protection.
 *
 * Requires two Firebase secrets, set once the app has a real Play Console
 * listing: `PLAY_SERVICE_ACCOUNT_JSON` (a Play Console API-access service
 * account's JSON key, Settings > API access) and `ANDROID_PACKAGE_NAME`
 * (the app's real applicationId — currently still the Flutter placeholder
 * `com.example.otelcim` in android/app/build.gradle.kts, so this cannot be
 * wired up until the app is actually registered on Play Console).
 */
async function verifyGooglePlayPurchase(purchaseToken: string, productId: string): Promise<string> {
  const serviceAccountJson = playServiceAccountJson.value();
  const packageName = androidPackageName.value();
  if (!serviceAccountJson || !packageName) {
    throw new HttpsError(
      "failed-precondition",
      "Google Play satın alma doğrulaması henüz yapılandırılmadı. Lütfen destek ile iletişime geçin."
    );
  }

  const accessToken = await getGooglePlayAccessToken(serviceAccountJson);

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}` +
    `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const response = await fetch(url, {headers: {Authorization: `Bearer ${accessToken}`}});
  if (!response.ok) {
    logger.error("Android Publisher API isteği başarısız.", {status: response.status});
    throw new HttpsError("permission-denied", "Google Play satın alma doğrulanamadı.");
  }

  const purchase = (await response.json()) as { purchaseState?: number; orderId?: string };

  // purchaseState: 0 = purchased, 1 = canceled, 2 = pending
  if (purchase.purchaseState !== 0) {
    throw new HttpsError("permission-denied", "Satın alma tamamlanmamış veya iptal edilmiş.");
  }
  if (!purchase.orderId) {
    throw new HttpsError("permission-denied", "Google Play satın alma kimliği (orderId) alınamadı.");
  }
  return purchase.orderId;
}

interface AppleVerifyReceiptTransaction {
  product_id: string;
  transaction_id: string;
  cancellation_date_ms?: string;
}

interface AppleVerifyReceiptResponse {
  status: number;
  receipt?: { in_app?: AppleVerifyReceiptTransaction[] };
  latest_receipt_info?: AppleVerifyReceiptTransaction[];
}

async function callAppleVerifyReceipt(
  url: string,
  receiptData: string,
  sharedSecret: string
): Promise<AppleVerifyReceiptResponse> {
  const response = await fetch(url, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      "receipt-data": receiptData,
      "password": sharedSecret,
      "exclude-old-transactions": true,
    }),
  });
  return (await response.json()) as AppleVerifyReceiptResponse;
}

/**
 * Verifies an App Store receipt against Apple's verifyReceipt endpoint and
 * returns the store's authoritative transaction_id for the matching
 * product — never trust a client-chosen transactionId (same reasoning as
 * verifyGooglePlayPurchase above).
 *
 * `verifyReceipt` (not the newer App Store Server API) is the correct
 * endpoint for this app because the installed in_app_purchase_storekit
 * (^0.3.0) plugin is StoreKit1-based, so `serverVerificationData` is the
 * base64 App Store receipt blob, not a StoreKit2 signed transaction.
 *
 * Requires the `APPSTORE_SHARED_SECRET` Firebase secret (App Store Connect
 * > your app > App Information > App-Specific Shared Secret), which can
 * only be generated once the app is actually registered on App Store
 * Connect — the bundle id is currently still the Flutter placeholder
 * `com.example.otelcim` in ios/Runner.xcodeproj/project.pbxproj.
 */
async function verifyAppStorePurchase(verificationData: string, productId: string): Promise<string> {
  const sharedSecret = appStoreSharedSecret.value();
  if (!sharedSecret) {
    throw new HttpsError(
      "failed-precondition",
      "App Store satın alma doğrulaması henüz yapılandırılmadı. Lütfen destek ile iletişime geçin."
    );
  }

  let result = await callAppleVerifyReceipt("https://buy.itunes.apple.com/verifyReceipt", verificationData, sharedSecret);

  // 21007: this receipt is from the sandbox environment — retry there.
  if (result.status === 21007) {
    result = await callAppleVerifyReceipt("https://sandbox.itunes.apple.com/verifyReceipt", verificationData, sharedSecret);
  }

  if (result.status !== 0) {
    logger.error("App Store makbuz doğrulaması başarısız.", {status: result.status});
    throw new HttpsError("permission-denied", "App Store satın alma doğrulanamadı.");
  }

  const transactions = result.latest_receipt_info ?? result.receipt?.in_app ?? [];
  const matchingTransaction = transactions.find((item) => item.product_id === productId);
  if (!matchingTransaction) {
    throw new HttpsError("permission-denied", "Makbuzda bu ürüne ait bir satın alma bulunamadı.");
  }
  if (matchingTransaction.cancellation_date_ms) {
    throw new HttpsError("permission-denied", "Satın alma iptal edilmiş.");
  }
  return matchingTransaction.transaction_id;
}

export const verifyAndProcessBoostPurchase = onCall(
  {
    region: "europe-west1",
    secrets: [playServiceAccountJson, androidPackageName, appStoreSharedSecret],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Kullanıcı girişi yapılmalıdır.");
    }

    const userId = request.auth.uid;
    const data = request.data as BoostPurchaseRequest;

    if (!data.listingId || !data.productId) {
      throw new HttpsError("invalid-argument", "Eksik parametreler (listingId, productId).");
    }

    const productConfig = BOOST_PRODUCTS[data.productId];
    if (!productConfig) {
      throw new HttpsError("invalid-argument", "Geçersiz boost ürünü.");
    }

    // The store token/receipt is mandatory: the caller must prove the
    // purchase actually happened via a real store receipt, not just assert
    // a price/product. The transaction id used below comes from the
    // verified receipt/token itself (orderId / transaction_id), never from
    // client input — a client-supplied transactionId could otherwise be
    // used to replay the same genuine receipt under a "fresh" fake id.
    const platform = data.platform as SupportedStorePlatform | undefined;
    let transactionId: string;
    if (platform === "google_play") {
      if (!data.purchaseToken) {
        throw new HttpsError("invalid-argument", "purchaseToken zorunludur (Google Play).");
      }
      transactionId = await verifyGooglePlayPurchase(data.purchaseToken, data.productId);
    } else if (platform === "app_store") {
      if (!data.verificationData) {
        throw new HttpsError("invalid-argument", "verificationData zorunludur (App Store).");
      }
      transactionId = await verifyAppStorePurchase(data.verificationData, data.productId);
    } else {
      throw new HttpsError("invalid-argument", "Geçersiz platform. 'google_play' veya 'app_store' olmalıdır.");
    }

    // Check duplicate transactionId (replay prevention)
    const existingPurchases = await db
      .collection("boost_purchases")
      .where("transactionId", "==", transactionId)
      .limit(1)
      .get();

    if (!existingPurchases.empty) {
      throw new HttpsError("already-exists", "Bu satın alma daha önce işlenmiş.");
    }

    const listingRef = db.collection("listings").doc(data.listingId);
    const listingDoc = await listingRef.get();
    if (!listingDoc.exists) {
      throw new HttpsError("not-found", "İlan bulunamadı.");
    }

    const listingData = listingDoc.data() ?? {};
    if (listingData.posterId !== userId) {
      throw new HttpsError("permission-denied", "Sadece kendi ilanınızı öne çıkarabilirsiniz.");
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + productConfig.durationDays * 24 * 60 * 60 * 1000);

    const boostRef = db.collection("boosts").doc();
    const purchaseRef = db.collection("boost_purchases").doc();

    const batch = db.batch();

    batch.set(boostRef, {
      id: boostRef.id,
      listingId: data.listingId,
      userId,
      durationType: productConfig.durationTypeEnum,
      durationDays: productConfig.durationDays,
      price: productConfig.price,
      purchasedAt: now,
      expiresAt: expiresAt,
      platform,
      transactionId,
      status: "active",
    });

    batch.set(purchaseRef, {
      id: purchaseRef.id,
      userId,
      listingId: data.listingId,
      boostId: boostRef.id,
      durationType: productConfig.durationTypeStr,
      price: productConfig.price,
      platform,
      transactionId,
      productId: data.productId,
      purchaseToken: data.purchaseToken || null,
      verificationData: data.verificationData || null,
      status: "completed",
      purchasedAt: now,
      verifiedAt: now,
    });

    batch.update(listingRef, {
      isBoosted: true,
      boostExpiresAt: expiresAt,
      boostType: data.productId,
      boostPurchaseId: purchaseRef.id,
      updatedAt: now,
    });

    await batch.commit();

    logger.info("Boost işlemi başarıyla tamamlandı.", {
      userId,
      listingId: data.listingId,
      productId: data.productId,
      transactionId,
    });

    return {
      success: true,
      boostId: boostRef.id,
      purchaseId: purchaseRef.id,
      expiresAt: expiresAt.toISOString(),
    };
  },
);

interface UrgentListingPurchaseRequest {
  listingId: string;
  productId: string;
  purchaseToken?: string;
  verificationData?: string;
  platform?: string;
}

/**
 * Verifies a real store receipt for the `urgent_listing` product and then
 * flips `isUrgent: true` on the caller's listing under the Admin SDK. This
 * is the paid path for "acil ihtiyaç": the first urgent listing per account
 * is free (consumed in reconcileFreeUrgentListingOnCreate), every one after
 * that comes through here.
 *
 * Mirrors verifyAndProcessBoostPurchase: store token/receipt is mandatory,
 * the transaction id comes from the verified receipt (never client input),
 * and duplicate transaction ids are rejected as replays.
 */
export const verifyAndProcessUrgentListingPurchase = onCall(
  {
    region: "europe-west1",
    secrets: [playServiceAccountJson, androidPackageName, appStoreSharedSecret],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Kullanıcı girişi yapılmalıdır.");
    }

    const userId = request.auth.uid;
    const data = request.data as UrgentListingPurchaseRequest;

    if (!data.listingId || !data.productId) {
      throw new HttpsError("invalid-argument", "Eksik parametreler (listingId, productId).");
    }
    if (data.productId !== URGENT_LISTING_PRODUCT_ID) {
      throw new HttpsError("invalid-argument", "Geçersiz acil ilan ürünü.");
    }

    const platform = data.platform as SupportedStorePlatform | undefined;
    let transactionId: string;
    if (platform === "google_play") {
      if (!data.purchaseToken) {
        throw new HttpsError("invalid-argument", "purchaseToken zorunludur (Google Play).");
      }
      transactionId = await verifyGooglePlayPurchase(data.purchaseToken, data.productId);
    } else if (platform === "app_store") {
      if (!data.verificationData) {
        throw new HttpsError("invalid-argument", "verificationData zorunludur (App Store).");
      }
      transactionId = await verifyAppStorePurchase(data.verificationData, data.productId);
    } else {
      throw new HttpsError("invalid-argument", "Geçersiz platform. 'google_play' veya 'app_store' olmalıdır.");
    }

    const existingPurchases = await db
      .collection("urgent_listing_purchases")
      .where("transactionId", "==", transactionId)
      .limit(1)
      .get();
    if (!existingPurchases.empty) {
      throw new HttpsError("already-exists", "Bu satın alma daha önce işlenmiş.");
    }

    const listingRef = db.collection("listings").doc(data.listingId);
    const listingDoc = await listingRef.get();
    if (!listingDoc.exists) {
      throw new HttpsError("not-found", "İlan bulunamadı.");
    }
    if ((listingDoc.data() ?? {}).posterId !== userId) {
      throw new HttpsError("permission-denied", "Sadece kendi ilanınızı acil yapabilirsiniz.");
    }

    const now = new Date();
    const purchaseRef = db.collection("urgent_listing_purchases").doc();
    const batch = db.batch();

    batch.set(purchaseRef, {
      id: purchaseRef.id,
      userId,
      listingId: data.listingId,
      price: URGENT_LISTING_PRICE,
      platform,
      transactionId,
      productId: data.productId,
      purchaseToken: data.purchaseToken || null,
      verificationData: data.verificationData || null,
      status: "completed",
      purchasedAt: now,
      verifiedAt: now,
    });

    batch.update(listingRef, {
      isUrgent: true,
      urgentListingPurchaseId: purchaseRef.id,
      updatedAt: now,
    });

    await batch.commit();

    logger.info("Acil ilan satın alması tamamlandı.", {
      userId,
      listingId: data.listingId,
      transactionId,
    });

    return {success: true, purchaseId: purchaseRef.id};
  },
);

/**
 * Redeems one of the caller's free (referral-earned) 7-day boost credits on
 * one of their own listings. Runs entirely under the Admin SDK so the
 * freeBoostCredits check-and-decrement, the boosts/boost_purchases writes,
 * and the listing update all happen atomically in one transaction that the
 * client cannot partially perform or spoof — firestore.rules denies all
 * client writes to boosts/boost_purchases and to freeBoostCredits, so this
 * function is the only way those documents change.
 */
export const redeemFreeBoost = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Kullanıcı girişi yapılmalıdır.");
    }

    const userId = request.auth.uid;
    const listingId = (request.data as { listingId?: string })?.listingId;
    if (!listingId) {
      throw new HttpsError("invalid-argument", "Eksik parametre (listingId).");
    }

    const listingRef = db.collection("listings").doc(listingId);
    const userRef = db.collection("user_profiles").doc(userId);
    const boostRef = db.collection("boosts").doc();
    const purchaseRef = db.collection("boost_purchases").doc();

    const durationDays = 7;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
    const transactionId = `referral_${boostRef.id}`;

    const result = await db.runTransaction(async (transaction) => {
      const [listingDoc, userDoc] = await Promise.all([
        transaction.get(listingRef),
        transaction.get(userRef),
      ]);

      if (!listingDoc.exists) {
        throw new HttpsError("not-found", "İlan bulunamadı.");
      }
      if (listingDoc.data()?.posterId !== userId) {
        throw new HttpsError("permission-denied", "Sadece kendi ilanınızı öne çıkarabilirsiniz.");
      }

      const freeBoostCredits = (userDoc.data()?.freeBoostCredits as number | undefined) ?? 0;
      if (freeBoostCredits <= 0) {
        throw new HttpsError("failed-precondition", "Kullanılabilir ücretsiz boost hakkınız yok.");
      }

      transaction.set(boostRef, {
        id: boostRef.id,
        listingId,
        userId,
        durationType: "days7",
        durationDays,
        price: 0,
        purchasedAt: now,
        expiresAt,
        platform: "referral_reward",
        transactionId,
        status: "active",
      });

      transaction.set(purchaseRef, {
        id: purchaseRef.id,
        userId,
        listingId,
        boostId: boostRef.id,
        durationType: "7",
        price: 0,
        platform: "referral_reward",
        transactionId,
        productId: "referral_free_boost",
        status: "completed",
        purchasedAt: now,
        verifiedAt: now,
      });

      transaction.update(listingRef, {
        isBoosted: true,
        boostExpiresAt: expiresAt,
        boostType: "referral_free_boost",
        boostPurchaseId: purchaseRef.id,
        updatedAt: now,
      });

      transaction.update(userRef, {
        freeBoostCredits: FieldValue.increment(-1),
      });

      return {boostId: boostRef.id, purchaseId: purchaseRef.id};
    });

    logger.info("Ücretsiz boost kullanıldı.", {userId, listingId, boostId: result.boostId});

    return {
      success: true,
      boostId: result.boostId,
      purchaseId: result.purchaseId,
      expiresAt: expiresAt.toISOString(),
    };
  },
);

/**
 * Grants a referral reward (1 free 7-day boost credit) to the user who
 * referred `refereeId`, the first time `refereeId` completes a qualifying
 * action (publishing their first listing, or starting their first chat).
 *
 * Idempotent via the `referralRewardGranted` flag on the referee's own
 * profile — this flag is only ever written here, never surfaced in the
 * Dart `UserProfile` model. Runs with the Admin SDK so it can bypass
 * firestore.rules and write to the referrer's `user_profiles` document
 * (which the referee's own client is not allowed to do).
 */
async function grantReferralRewardIfEligible(
  refereeId: string,
  refereeData: FirebaseFirestore.DocumentData
): Promise<void> {
  const referredBy = refereeData.referredBy as string | undefined;
  if (!referredBy) {
    return;
  }
  if (refereeData.referralRewardGranted === true) {
    return;
  }

  try {
    const referrerRef = db.collection("user_profiles").doc(referredBy);
    const referrerSnapshot = await referrerRef.get();
    if (!referrerSnapshot.exists) {
      logger.info("Referans veren kullanıcı bulunamadı; ödül atlandı.", {referredBy, refereeId});
      return;
    }

    await referrerRef.update({
      freeBoostCredits: FieldValue.increment(1),
      referralCount: FieldValue.increment(1),
    });

    await db.collection("user_profiles").doc(refereeId).update({
      referralRewardGranted: true,
    });

    logger.info("Referans ödülü verildi.", {referredBy, refereeId});
  } catch (error) {
    logger.error("Referans ödülü verilemedi.", {referredBy, refereeId, error});
  }
}

export const grantReferralRewardOnListingCreated = onDocumentCreated(
  {
    document: "listings/{listingId}",
    region: "europe-west1",
  },
  async (event) => {
    const listing = event.data?.data();
    const posterId = listing?.posterId as string | undefined;
    if (!posterId) {
      return;
    }

    const posterSnapshot = await db.collection("user_profiles").doc(posterId).get();
    if (!posterSnapshot.exists) {
      return;
    }

    await grantReferralRewardIfEligible(posterId, posterSnapshot.data() ?? {});
  },
);

/**
 * "Acil ihtiyaç" free-slot reconciliation. A listing is only ever *born*
 * with isUrgent: true from the create form's free path — the paid path
 * always creates it non-urgent and flips the flag afterwards via
 * verifyAndProcessUrgentListingPurchase. So any listing that arrives urgent
 * must be spending the poster's single lifetime free urgent slot:
 *
 *   - free slot still available -> mark it consumed
 *     (user_profiles.hasUsedFreeUrgentListing = true)
 *   - free slot already spent, or the profile doc is missing -> the urgent
 *     flag isn't backed by anything, so downgrade the listing to non-urgent
 *
 * firestore.rules already blocks a client from flipping isUrgent on an
 * existing listing (isNotChangingBoostOrOwnershipFields), so this only has
 * to police the create path.
 */
export const reconcileFreeUrgentListingOnCreate = onDocumentCreated(
  {
    document: "listings/{listingId}",
    region: "europe-west1",
  },
  async (event) => {
    const listing = event.data?.data();
    const listingId = event.params.listingId;
    if (!listing || listing.isUrgent !== true) {
      return;
    }
    const posterId = listing.posterId as string | undefined;
    if (!posterId) {
      return;
    }

    const profileRef = db.collection("user_profiles").doc(posterId);
    const listingRef = db.collection("listings").doc(listingId);
    try {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(profileRef);
        if (!snap.exists) {
          tx.update(listingRef, {isUrgent: false});
          return;
        }
        const hasUsedFree =
          (snap.data()?.hasUsedFreeUrgentListing as boolean | undefined) ?? false;
        if (hasUsedFree) {
          tx.update(listingRef, {isUrgent: false});
        } else {
          tx.update(profileRef, {hasUsedFreeUrgentListing: true});
        }
      });
    } catch (error) {
      logger.error("Ücretsiz acil ilan hakkı uzlaştırılamadı.", {listingId, error});
    }
  },
);

export const grantReferralRewardOnConversationCreated = onDocumentCreated(
  {
    document: "conversations/{conversationId}",
    region: "europe-west1",
  },
  async (event) => {
    const conversation = event.data?.data();
    const seekerId = conversation?.seekerId as string | undefined;
    if (!seekerId) {
      return;
    }

    const seekerSnapshot = await db.collection("user_profiles").doc(seekerId).get();
    if (!seekerSnapshot.exists) {
      return;
    }

    await grantReferralRewardIfEligible(seekerId, seekerSnapshot.data() ?? {});
  },
);

import {initializeApp} from "firebase-admin/app";
import {FieldValue, getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onCall, HttpsError} from "firebase-functions/v2/https";

initializeApp();

const db = getFirestore();

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
  transactionId: string;
  purchaseToken?: string;
  verificationData?: string;
  platform?: string;
}

const BOOST_PRODUCTS: Record<string, { durationDays: number; price: number; durationTypeEnum: string; durationTypeStr: string }> = {
  "boost_7_days": { durationDays: 7, price: 49.99, durationTypeEnum: "days7", durationTypeStr: "7" },
  "boost_14_days": { durationDays: 14, price: 89.99, durationTypeEnum: "days14", durationTypeStr: "14" },
  "boost_30_days": { durationDays: 30, price: 149.99, durationTypeEnum: "days30", durationTypeStr: "30" },
};

export const verifyAndProcessBoostPurchase = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Kullanıcı girişi yapılmalıdır.");
    }

    const userId = request.auth.uid;
    const data = request.data as BoostPurchaseRequest;

    if (!data.listingId || !data.productId || !data.transactionId) {
      throw new HttpsError("invalid-argument", "Eksik parametreler (listingId, productId, transactionId).");
    }

    const productConfig = BOOST_PRODUCTS[data.productId];
    if (!productConfig) {
      throw new HttpsError("invalid-argument", "Geçersiz boost ürünü.");
    }

    // Check duplicate transactionId (replay prevention)
    const existingPurchases = await db
      .collection("boost_purchases")
      .where("transactionId", "==", data.transactionId)
      .limit(1)
      .get();

    if (!existingPurchases.empty) {
      throw new HttpsError("already-exists", "Bu işlem ID'si (transactionId) daha önce kullanılmış.");
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
    const platform = data.platform || "in_app_purchase";

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
      transactionId: data.transactionId,
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
      transactionId: data.transactionId,
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
      transactionId: data.transactionId,
    });

    return {
      success: true,
      boostId: boostRef.id,
      purchaseId: purchaseRef.id,
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

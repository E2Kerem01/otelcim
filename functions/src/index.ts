import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";

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

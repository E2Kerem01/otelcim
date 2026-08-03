import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {logger} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";

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

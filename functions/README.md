# Otelcim Cloud Functions

Bu klasör, yeni sohbet mesajları için FCM bildirimi gönderen ikinci nesil Firebase Cloud Function'ını içerir. Function şu yolu dinler:

`conversations/{conversationId}/messages/{messageId}`

Yeni mesaj oluşturulduğunda konuşmanın diğer tarafı belirlenir, `user_profiles/{uid}.fcmToken` okunur ve `conversationId` içeren bir bildirim gönderilir. İlk mesaj da aynı Firestore yoluna yazıldığı için işverene ilk mesaj bildirimi ayrıca bir trigger gerektirmeden kapsanır.

## Gereksinimler

- Node.js 20
- Firebase CLI
- `otelcim-7f0ba` projesine deploy yetkisi olan bir Google hesabı
- Firebase Console'da Cloud Messaging ve Cloud Functions kullanımının etkin olması
- iOS için Firebase Console'a APNs anahtarı/sertifikası yüklenmiş olması ve Xcode'da Push Notifications ile Background Modes > Remote notifications yeteneklerinin açılması

## Kurulum ve derleme

Repo kökünden:

```powershell
cd functions
npm install
npm run build
```

## Manuel deploy

Bu repo hazırlanırken function deploy edilmemiştir. Yetkili bir geliştirici aşağıdaki adımları manuel çalıştırmalıdır:

```powershell
npm install -g firebase-tools
firebase login
firebase use otelcim-7f0ba
firebase deploy --only functions
```

Deploy sonrasında Firebase Console > Functions ekranında `sendChatMessageNotification` fonksiyonunun `europe-west1` bölgesinde başarılı olduğunu ve loglarını kontrol edin.

## Güvenlik kuralları

Bu repoda `firestore.rules` veya `storage.rules` bulunmuyor. Kurallar Firebase Console üzerinden yönetiliyor. Firebase Console > Firestore Database > Rules bölümünde kullanıcıların yalnızca kendi `fcmToken` alanlarını güncelleyebildiğini; Storage > Rules bölümünde ise mevcut yükleme kurallarının beklendiği gibi olduğunu doğrulayın. FCM token'ı hassas veri olarak değerlendirin ve başka kullanıcıların profillerinden okunmasına izin vermeyin.

# Acil İlan (Urgent Listing) Ödeme Kurulumu

"Acil ihtiyaç" ilanlarının ücretlendirmesi: **her hesabın ilk acil ilanı
ücretsiz, sonraki her acil ilan ücretli.** Kod tarafı hazır; aşağıdaki
adımlar mağaza + deploy tarafında **manuel** yapılmalı.

## Kod tarafı (hazır)

| Katman | Dosya | Ne yapar |
|--------|-------|----------|
| Model | `lib/shared/models/user_profile.dart` | `hasUsedFreeUrgentListing` (server-controlled bool) |
| Rules | `firestore.rules` | `hasUsedFreeUrgentListing` client yazımına kapalı; `isUrgent` + `urgentListingPurchaseId` ilan update'inde CF-only; yeni `urgent_listing_purchases` koleksiyonu read-owner / write-none |
| Ödeme | `lib/shared/services/payment_service.dart` | `urgent_listing` ürün id'si eklendi |
| Servis | `lib/features/listings/services/urgent_listing_service.dart` | `verifyAndProcessUrgentListingPurchase` CF'ini çağırır |
| Ekran | `lib/features/listings/presentation/urgent_listing_purchase_screen.dart` | `/listing/:id/urgent` route'u |
| Akış | `create_listing_screen.dart` | Acil seçiliyse: ücretsiz hak varsa `isUrgent: true` yayınlar; hak bittiyse `isUrgent: false` yayınlayıp satın alma ekranına yönlendirir |
| CF | `functions/src/index.ts` | `verifyAndProcessUrgentListingPurchase` (onCall), `reconcileFreeUrgentListingOnCreate` (ücretsiz hak tüketimi + kötüye kullanım koruması), `sendUrgentListingNotificationOnUpgrade` (ödeme sonrası bölge bildirimi) |

### Akış özeti

```
Kullanıcı "Acil" toggle'ını açar + İlanı Yayınla
        │
        ├─ hasUsedFreeUrgentListing == false  (ilk acil ilan)
        │     └─ listing isUrgent:true ile yaratılır
        │        └─ reconcileFreeUrgentListingOnCreate → profile.hasUsedFreeUrgentListing = true
        │        └─ sendUrgentListingNotification → bölgeye bildirim
        │
        └─ hasUsedFreeUrgentListing == true  (2. ve sonrası)
              └─ listing isUrgent:false ile yaratılır
              └─ /listing/:id/urgent ekranına git
                 └─ IAP satın alma (urgent_listing ürünü)
                    └─ verifyAndProcessUrgentListingPurchase
                       ├─ mağaza makbuzu doğrulanır (replay koruması)
                       ├─ listing.isUrgent = true, urgentListingPurchaseId set
                       └─ sendUrgentListingNotificationOnUpgrade → bölgeye bildirim
```

Kötüye kullanım: bir istemci profil `hasUsedFreeUrgentListing:true` iken
doğrudan `isUrgent:true` ilan yaratmayı denerse,
`reconcileFreeUrgentListingOnCreate` ilanı `isUrgent:false`'a düşürür.
(Not: create bildirimi düşürmeden hemen önce bir kez tetiklenebilir —
düşük önemli, para bypass'ı değil.)

## Manuel adımlar

### 1. Uygulama gerçek paket adı / bundle id

Boost ödemesi de bunu bekliyor. Şu an placeholder:
- Android: `com.example.otelcim` → `android/app/build.gradle.kts`
- iOS: `com.example.otelcim` → `ios/Runner.xcodeproj/project.pbxproj`

Gerçek id'lerle App Store Connect + Play Console'da uygulama kaydı yapılmalı.

### 2. Mağaza ürünü oluştur — `urgent_listing`

Her iki mağazada da **tek seferlik (consumable / non-consumable)** ürün:

- **Google Play Console** → Monetize → Products → In-app products → Create
  - Product ID: `urgent_listing`
  - Type: **Managed product** (consumable olarak işaretle — kullanıcı birden
    çok kez satın alabilmeli)
  - Fiyat: kararına göre (kod fallback'i ₺149,99, `URGENT_LISTING_PRICE`)
- **App Store Connect** → uygulaman → In-App Purchases → Manage → +
  - Reference Name: Urgent Listing
  - Product ID: `urgent_listing`
  - Type: **Consumable**
  - Fiyat: aynı

> Fiyatı değiştirirsen `functions/src/index.ts` içindeki
> `URGENT_LISTING_PRICE` ve
> `urgent_listing_purchase_screen.dart` içindeki `_fallbackPrice` yalnızca
> gösterim/bookkeeping — gerçek tahsilat mağaza fiyatıdır, ama tutması için
> güncelle.

### 3. Firebase secret'ları (boost ile ortak — zaten gerekliyse atla)

`verifyAndProcessUrgentListingPurchase`, boost fonksiyonuyla aynı secret'ları
kullanır:

```bash
firebase functions:secrets:set PLAY_SERVICE_ACCOUNT_JSON   # Play Console > Setup > API access > service account JSON
firebase functions:secrets:set ANDROID_PACKAGE_NAME        # gerçek applicationId
firebase functions:secrets:set APPSTORE_SHARED_SECRET      # App Store Connect > App Information > App-Specific Shared Secret
```

### 4. Deploy

```bash
# Rules
firebase deploy --only firestore:rules

# Functions (yeni: verifyAndProcessUrgentListingPurchase,
# reconcileFreeUrgentListingOnCreate, sendUrgentListingNotificationOnUpgrade)
cd functions && npm run build && cd ..
firebase deploy --only functions
```

### 5. Test

1. Yeni hesap → acil ilan ver → ücretsiz yayınlanmalı, profildeki
   `hasUsedFreeUrgentListing` `true` olmalı, bölge bildirimi gelmeli.
2. Aynı hesap → 2. acil ilan → ilan normal yayınlanır, satın alma ekranı
   açılır. Sandbox satın alma → ilan `isUrgent:true` olur, ikinci bildirim
   gelir, `urgent_listing_purchases` dokümanı yazılır.
3. Aynı sandbox makbuzunu tekrar göndermeyi dene → `already-exists` hatası.

### 6. Mevcut kullanıcılar (opsiyonel backfill)

Yeni alan yokken acil ilan vermiş kullanıcılar `hasUsedFreeUrgentListing`
alanına sahip değil (varsayılan `false` → bir ücretsiz hakları daha olur).
İstersen tek seferlik script ile geçmişte `isUrgent:true` ilanı olan
kullanıcılar için `true` yaz (bkz. `functions/backfill_contact_info_privacy.js`
kalıbı).

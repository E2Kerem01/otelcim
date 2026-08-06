# Kritik: Ödeme Doğrulaması Olmadan Ücretli Boost Oluşturulabiliyor

## Öncelik: ACİL (Critical) — finansal/fraud riski

## Bulgu
- `lib/shared/services/payment_service.dart:148-154` (`verifyPurchase`) sadece cihazdaki `PurchaseDetails.status`'e bakıyor — bu tamamen client-side, App Store/Google Play sunucusuna karşı KRİPTOGRAFİK DOĞRULAMA yapılmıyor.
- `lib/features/boosts/presentation/boost_purchase_screen.dart` (`_handlePurchase`, satır ~66-72): IAP mağaza ürünleri bulunamazsa/kullanılamıyorsa **sahte bir "demo purchase" akışına düşüyor** (`await Future.delayed(...); purchaseSuccess = true;`) — bu, gerçek bir satın alma OLMADAN boost oluşturulmasına izin veriyor.
- `lib/features/boosts/services/boost_service.dart` (`processBoostPurchase`) doğrudan client'tan çağrılıp Firestore'a `boosts`/`boost_purchases`/`listings` yazıyor; `firestore.rules`'taki `create` kuralı sadece `userId == request.auth.uid` kontrol ediyor, fiyat/ürün/makbuz doğrulaması YOK. Teorik olarak bir kullanıcı UI'ı hiç kullanmadan doğrudan Firestore'a (veya `processBoostPurchase`'ı manipüle ederek) `price: 0` ile "satın alınmış" bir boost yazabilir.

## Kapsam (MVP — gerçekçi hedef)
Bu ortamda App Store/Google Play sunucu kimlik bilgileri (service account, shared secret) YOK, bu yüzden tam kriptografik makbuz doğrulaması (Apple/Google API'lerine sunucu tarafından sorgu) bu görevin kapsamı DIŞINDA. Onun yerine şu somut, gerçekleştirilebilir sıkılaştırmaları yap:

1. **Demo/fallback satın alma akışını kaldır veya açıkça işaretle**: `boost_purchase_screen.dart`'taki "IAP kullanılamıyorsa sahte satın alma" davranışını kaldır. IAP kullanılamıyorsa kullanıcıya net bir hata göster ("Satın alma şu an kullanılamıyor"), boost OLUŞTURMA. (Bu bir test/demo ortamı ihtiyacıysa, en azından `kDebugMode` kontrolüyle SADECE debug build'de çalışsın, production/release build'de asla.)
2. **Sunucu tarafı yazma zorunluluğu**: `processBoostPurchase`'ı client'tan direkt çağırmak yerine bir Cloud Function callable'a taşı (`functions/src/index.ts`'e yeni bir `onCall` fonksiyonu ekle, örn. `verifyAndProcessBoostPurchase`). Client, IAP `PurchaseDetails`'ı (productId, transactionId/purchaseID, verificationData) bu callable'a gönderir; fonksiyon:
   - `transactionId`'nin `boost_purchases` koleksiyonunda daha önce KULLANILMADIĞINI doğrular (replay/tekrar kullanım koruması — aynı transactionId ile ikinci kez boost alınamaz).
   - `productId`'nin bilinen bir üründe (`boost_7_days`/`boost_14_days`/`boost_30_days`) olduğunu ve fiyatın SUNUCU TARAFINDA sabit bir tablodan (client'tan gelen fiyata GÜVENME) alındığını doğrular.
   - Doğrulama geçerse Admin SDK ile `boosts`/`boost_purchases`/`listings` dokümanlarını yazar (rules'u bypass ederek, çünkü artık sunucu tarafı güvenilir).
3. **Firestore rules**: `boosts`/`boost_purchases` için client-side `create` iznini TAMAMEN KALDIR (sadece Cloud Function'ın Admin SDK'sı yazabilsin). **DİKKAT**: spec 040 (referans sistemi, `BoostService.redeemFreeBoost`) da bu koleksiyonlara client'tan yazıyor — eğer o PR (#31) merge olduysa, `redeemFreeBoost`'u da bu değişiklikten ETKİLENMEYECEK şekilde ele al: ya `redeemFreeBoost`'u da bir Cloud Function callable'a taşı, ya da `redeemFreeBoost` için ayrı, dar bir rule istisnası bırak (örn. sadece `platform == 'referral_reward' && price == 0` olan yazmalara izin ver). Bu koordinasyonu atlama — spec 040'ın PR'ını (`git log --all --oneline | grep referral` veya GitHub'da PR #31) incele.
4. Client tarafında `boost_purchase_screen.dart`'ı yeni callable'ı çağıracak şekilde güncelle.

## Dosya Çakışma Uyarısı
- `functions/src/index.ts`: spec 040 (PR #31) bu dosyaya zaten iki fonksiyon eklemişti (`grantReferralRewardOnListingCreated`/`OnConversationCreated`). O PR merge olmuşsa dosyanın güncel halini oku, çakışmadan EKLE.
- `lib/features/boosts/services/boost_service.dart` ve `boost_purchase_screen.dart`: aynı gerekçeyle spec 040 ile çakışabilir, dikkatli rebase/merge yap.
- `firestore.rules`: spec 053 (güvenlik sıkılaştırması) da bu dosyaya dokunuyor — İKİ İŞÇİ AYNI ANDA BU DOSYAYA YAZMASIN. Spec 053'ün işi bitene kadar bekle veya onunla koordine ol; en son işi biten bu iki spec'i merge ederken elle birleştirmesi gerekebilir.

## Acceptance Criteria
- [ ] Sahte/demo satın alma akışı kaldırıldı veya sadece debug build'e kısıtlandı
- [ ] Boost oluşturma artık bir Cloud Function callable üzerinden, sunucu tarafı fiyat/ürün doğrulamasıyla yapılıyor
- [ ] Aynı `transactionId` ile iki kez boost alınamıyor (replay koruması)
- [ ] `firestore.rules`'ta `boosts`/`boost_purchases` client-side create artık kapalı (veya çok dar bir istisna dışında)
- [ ] Referans sisteminin ücretsiz boost akışı (spec 040/PR #31, eğer merge olduysa) hâlâ çalışıyor
- [ ] `functions` klasöründe `npm run build` (tsc) hatasız derleniyor
- [ ] `flutter analyze`/`flutter test` geçiyor

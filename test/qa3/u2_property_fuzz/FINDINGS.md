# u2_property_fuzz — Bulgular

## Eklenen testler

- `property_fuzz_test.dart`: 8 test (6 çalışan, 2 doğru davranışı tanımlayan skip).
- Ayrıştırıcı eksik-alan fuzz’ı: sabit `Random(20260924)` ile 250 örnek × 8 model (`Listing`, `UserProfile`, `Conversation`, `Message`, `Boost`, `Certificate`, `VerificationRequest`, `BannerAd`).
- Round-trip: 250 geçerli örnek × 8 model; `FieldValue.serverTimestamp` ve `Listing.contactInfo` (bilinçli olarak public map’e yazılmıyor) dışında alanlar karşılaştırılıyor.
- `ListingService`: 250 rastgele 12’li Firestore kümesinde aktif ilan altkümesi, kategori idempotence, maaş filtresi altkümesi ve yüksekten düşüğe monoton sıralama.
- `regionTopicName`, referans kodu ve sezon/tarih yardımcıları: özellik başına 300 örnek.

## Bulgular

### BUG-u2-01 — D2 ayrıştırıcıları yanlış tiplerde TypeError’a açık (yüksek)

Doğrulama testi `property_fuzz_test.dart:226-355` içinde skip’li bırakıldı. Rastgele `bool`/`int`/`double`/`String`/`List`/`Map`/`Timestamp` değerleri alanlara verildiğinde üretim ayrıştırıcıları unchecked cast kullanıyor:

- `Listing.fromDoc` — `lib/features/listings/domain/listing_model.dart:90-148` (özellikle `images` elemanları ve bool/numeric alanlar)
- `UserProfile.fromFirestore` — `lib/shared/models/user_profile.dart:170-230` (özellikle preference map’i, timestamp ve numeric sayaçlar)
- `Conversation.fromDoc` / `Message.fromDoc` — `lib/shared/models/conversation.dart:32-45`, `lib/shared/models/message.dart:16-22`
- `Boost.fromDoc` — `lib/features/boosts/domain/boost_model.dart:34-79`
- `Certificate.fromDoc` — `lib/features/profile/domain/certificate_model.dart:104-118`
- `VerificationRequest.fromDoc` — `lib/features/admin/domain/verification_request_model.dart:43-58` (liste elemanları dahil)
- `BannerAd.fromDoc` — `lib/features/ads/domain/banner_ad_model.dart:28-40`

Bu durum Firestore Console/Admin SDK’den gelen tek bir yanlış tipin ilgili liste/ekranı tamamen düşürmesine yol açabilir. Test, production değişikliği istenmediği için `BUG-u2-01` ile skip’lidir; mevcut hatalı davranışı başarı olarak sabitlemez.

### BUG-u2-02 — Dart/TypeScript bölge topic normalizasyonu uyuşmuyor (yüksek)

`property_fuzz_test.dart:656-665` skip’li testi, `İzmir` için Dart tarafının `region_izmir` üretmesini (`lib/shared/services/notification_service.dart:14-19`), Cloud Functions tarafının ise JavaScript `toLowerCase()` sonrası `region_i_zmir` üretmesini (`functions/src/index.ts:209-210`) gösterir. Acil ilan bildirimleri bu girdide istemci topic’i ile sunucu topic’i arasında eşleşmez.

## Notlar

- `fake_cloud_firestore` ile gerçek Firestore `DocumentSnapshot` kullanıldı; sahte singleton Firebase servisleri veya production kodu değiştirilmedi.
- Testler, istenen mevcut test kalıplarındaki `flutter_test` + `fake_cloud_firestore` bağımlılıklarıyla sınırlı tutuldu.
- Bu sandbox’ta `dart` PATH’te bulunmadığı için format/analyze/test çalıştırılamadı; orkestratörün Flutter ortamında çalıştırması gerekir.

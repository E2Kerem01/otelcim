# Acil Eleman Çağrısı ve Vardiya İhtiyacı Bildirimi

Roadmap `feature-24` (phase-5). Ideation raporu Feature 5.3, MoSCoW
"Must Have". `feature-14` (bölge) ve `feature-3` (FCM) üzerine kurulu,
ikisi de tamamlanmış durumda.

## Açıklama

İşverenlerin "Acil İhtiyaç" etiketiyle ilan açabilmesi; bu ilanların
ilgili bölgedeki (region) aktif kullanıcılara anlık FCM push bildirimi
olarak ulaşması.

## Yapılacaklar

- `lib/features/listings/domain/listing_model.dart`'a `isUrgent` (bool,
  default `false`) alanı ekle.
- `create_listing_screen.dart`'a "Acil İhtiyaç" toggle'ı ekle.
- İlan kartlarında (home_screen.dart'taki `_ListingCard`) `isUrgent ==
  true` ise kırmızı/turuncu bir rozet göster.
- `functions/src/index.ts`'e yeni bir Cloud Function ekle: `listings`
  koleksiyonunda `isUrgent == true` olan yeni bir doküman oluştuğunda
  (`onDocumentCreated`), o ilanın `region` alanına sahip kullanıcıları
  bul (bunun için basitçe: aynı region'da daha önce ilan görüntülemiş/
  favori eklemiş kullanıcıları hedeflemek yerine, MVP kapsamında
  **region bazlı bir topic'e abone et** — `sendSeasonalReminders`
  fonksiyonundaki tekil-token gönderim yerine, `getMessaging().sendToTopic
  ('region_' + region, ...)` kullan. Client tarafında kullanıcı hangi
  bölgeyi favoriliyorsa/son seçtiyse o topic'e abone olsun — basit bir
  MVP, tam hedefleme değil).
  - Kullanıcının `notificationPreferences`'ında acil ilan bildirimini
    kapatma seçeneği olsun (mevcut `feature-16` altyapısını genişlet:
    `defaultNotificationPreferences`'a `urgentListings: true` ekle).

## Acceptance Criteria

- [ ] `isUrgent` alanı model+form+kartlarda çalışıyor
- [ ] Acil ilan yayınlandığında ilgili bölge topic'ine FCM bildirimi
      gidiyor, kullanıcı tercihine saygı gösteriyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`listing_model.dart` — 030 ile paylaşılıyor (ikisi de sadece alan
ekliyor). `home_screen.dart` — 033 (AI match skoru) de karta rozet
eklemek isteyebilir, ikiniz de aynı `_ListingCard` widget'ına dokunuyor
olabilir, birbirinizin eklediği satırları SİLMEYİN, sadece kendi rozetinizi
ekleyin.

# Aday-İlan Uyum Skorlaması (AI Smart Match)

Roadmap `feature-25` (phase-5). Ideation raporu Feature 5.4. `feature-24`
(deneyim/eğitim alanları — `experienceLevel`/`educationLevel`) zaten
`listing_model.dart`'ta mevcut ve merge edilmiş durumda, üzerine kurulacak.

## Açıklama

Bir iş arayanın profiliyle (deneyim, eğitim, bölge tercihi) bir ilanın
gereksinimlerini (deneyim/eğitim/bölge) karşılaştırıp yaklaşık bir "%
Uyum" skoru gösterme. Harici bir AI servisi ŞART DEĞİL — basit,
client-side bir ağırlıklandırma yeterli.

## Yapılacaklar

- `lib/shared/models/user_profile.dart`'a iş arayan için opsiyonel
  `preferredExperienceLevel`, `preferredEducationLevel` alanları
  EKLEME — bunun yerine kullanıcının kendi geçmiş başvurularından/
  profilinden çıkarım yapmak yerine, basitçe **profil düzenleme
  ekranına** (jobseeker için) opsiyonel "Deneyim Seviyem"/"Eğitim
  Durumum" alanları ekle (var olan `ExperienceLevel`/`EducationLevel`
  enum'larını, `lib/shared/constants/listing_filters.dart`'tan, yeniden
  kullan).
- Yeni saf fonksiyon dosyası: `lib/shared/utils/match_score.dart` —
  `int calculateMatchScore({required Listing listing, required
  UserProfile profile})` — deneyim/eğitim/bölge eşleşmesine göre 0-100
  arası bir skor hesapla (örn. her kriter eşleşirse +33, kısmi eşleşme
  +15). Basit ve deterministik olsun, test edilebilir.
- İlan kartlarında (`home_screen.dart` `_ListingCard`), kullanıcı iş
  arayan ve giriş yapmışsa, küçük bir "%N Uyum" rozeti göster (skor
  hesaplaması senkron/yerel, ekstra Firestore okuması gerektirmiyor —
  zaten elde olan `listing` ve kullanıcının kendi `UserProfile`'ı
  yeterli).

## Acceptance Criteria

- [ ] `calculateMatchScore` saf fonksiyonu var, deterministik, unit
      test'li (birkaç senaryo: tam eşleşme, kısmi, hiç eşleşmeme)
- [ ] İş arayan profiline opsiyonel deneyim/eğitim tercihi eklenebiliyor
- [ ] İlan kartlarında sadece giriş yapmış iş arayanlara uyum skoru
      rozeti gösteriliyor (işverenlere gösterilmiyor)
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`home_screen.dart`'taki `_ListingCard`'a **032** de rozet ekliyor —
birbirinizin eklediği kodu silmeyin, sadece kendi widget'ınızı ekleyin.
`user_profile.dart`'a **başka aktif spec dokunmuyor**, düşük risk.

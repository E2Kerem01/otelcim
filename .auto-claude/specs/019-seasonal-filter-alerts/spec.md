# Sezon Filtresi & Sezonluk Hatırlatmalar

`feature-15` (Seasonal Hiring Mode) kapsamının son parçası. **017 (sezon
modeli) merge edildikten sonra başla** — bu spec 017'nin eklediği `season`
alanını filtre panelinde kullanır.

## Açıklama

Mevcut arama/filtre paneline sezon filtresi ekle; ayrıca kullanıcıların
bölge+kategori bazlı sezonluk işe alım hatırlatmalarına abone olabildiği bir
"sezonluk işe alım takvimi" özelliği kur.

## Rationale

Sezon filtresi olmadan 017'de eklenen sezon etiketi keşfedilemez kalır.
Hatırlatmalar, iş arayanların yoğun işe alım dönemlerinden (Nisan-Haziran
yaz, Kasım-Aralık kış) önce erken başvurmasını sağlar — mevcut FCM
(`feature-3`) ve bildirim tercihleri (`feature-16`, zaten tamamlandı)
altyapısı üzerine kurulur, sıfırdan bildirim sistemi yazma.

## Yapılacaklar

- Mevcut arama/filtre panelinde (feature-9'un oluşturduğu filtre UI'ı) sezon
  seçeneği ekle: Yaz 2025 / Kış 2025-26 / Tüm Yıl / Farketmez. Server-side
  Firestore sorgusuna `season` eşitlik filtresi olarak ekle; gerekiyorsa
  `firestore.indexes.json`'a composite index ekle (bkz. genel kurallar §5).
- Yeni "Sezonluk İşe Alım Takvimi" ekranı/bölümü: yaklaşan sezon pencerelerini
  (örn. "Yaz sezonu başvuruları Nisan'da yoğunlaşıyor") statik/basit bir
  içerikle göster — karmaşık bir takvim motoru gerekmiyor, sabit tarih
  aralıkları yeterli.
- Kullanıcı, tercih ettiği bölge + kategori için "sezon başlamadan haberdar
  et" aboneliği açabilsin (Firestore'da kullanıcı alt koleksiyonu/alanı
  olarak sakla).
- Cloud Function (mevcut `functions/` altındaki yapıyı takip et, `feature-3`
  FCM gönderim mantığını yeniden kullan): abone olunan sezon penceresi
  yaklaştığında (örn. sezon başlangıcından 30 gün önce) bildirim gönder.
  Kullanıcının `feature-16` bildirim tercihlerine (varsa "Seasonal
  Reminders" toggle'ı) saygı göster — kapalıysa gönderme.

## User Stories

- Bir iş arayan olarak, sadece "Yaz 2025" ilanlarını filtrelemek istiyorum.
- Bir mevsimlik çalışan olarak, yaz sezonu başlamadan önce hatırlatma almak
  istiyorum ki en iyi pozisyonlara erken başvurabileyim.

## Acceptance Criteria

- [ ] Filtre panelinde sezon seçeneği var, sonuçlar server-side filtreleniyor
- [ ] Gerekli composite index `firestore.indexes.json`'a eklendi
- [ ] Sezonluk takvim ekranı yaklaşan sezon pencerelerini gösteriyor
- [ ] Kullanıcı bölge+kategori bazlı sezon aboneliği açıp kapatabiliyor
- [ ] Cloud Function, abonelere sezon yaklaşınca FCM bildirimi gönderiyor ve
      kullanıcının bildirim tercihine saygı gösteriyor
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor; filtre mantığı için unit test var

## Bağımlılıklar

- **017 (Sezon Modeli & İlan Formu)** — önce merge edilmiş olmalı.
- feature-3 (FCM), feature-16 (Bildirim Tercihleri) — tamamlandı, üzerine inşa edilecek.

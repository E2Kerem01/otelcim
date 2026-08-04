# Sezon Modeli & İlan Formu

`feature-15` (Seasonal Hiring Mode) kapsamının temeli. 018 (toplu ilan) ve
019 (sezon filtresi) bu spec'in eklediği `season` alanına bağımlı olduğu için
**önce tamamlanıp merge edilmeli**.

## Açıklama

Otel işverenleri ilanlarını sezona göre etiketleyebilmeli (Yaz 2025,
Kış 2025-26, Tüm Yıl) ve sezonluk pozisyonlar için sözleşme başlangıç/bitiş
tarihi girebilmeli.

## Rationale

Türkiye turizm sektöründe yoğun sezonluk işe alım dönemleri var (Nisan-Haziran
yaz, Kasım-Aralık kış) ve hiçbir platform bunu desteklemiyor. `feature-9`
(arama/filtre) ve `feature-3` (FCM push) zaten tamamlandığı için bağımlılıklar
karşılanmış durumda.

## Yapılacaklar

- `lib/features/listings/domain/listing_model.dart` içine:
  - `season` (String?, enum benzeri: `yaz_2025`, `kis_2025_26`, `tum_yil` —
    nullable, eski ilanlar için)
  - `contractStartDate` (DateTime?), `contractEndDate` (DateTime?)
  alanlarını ekle, `toMap()`/`fromFirestore` güncelle.
- İlan oluşturma/düzenleme ekranına opsiyonel "Sezon" seçici (chip/dropdown)
  ve seçilirse görünen tarih aralığı seçici ekle.
- İlan kartlarında (`home_screen.dart` içindeki liste item'ı veya ayrı bir
  `listing_card` widget'ı varsa orada) sezon seçiliyse görsel bir rozet
  ("Yaz 2025" gibi) göster.
- Sezonun `tum_yil` veya boş olduğu ilanlarda rozet gösterme.

## User Stories

- Bir otel işvereni olarak, ilanımı "Yaz 2025" olarak etiketlemek istiyorum
  ki iş arayanlar bunun sezonluk bir pozisyon olduğunu hemen anlasın.
- Bir sezonluk çalışan olarak, ilanın sözleşme tarihlerini görmek istiyorum
  ki uygunluğumu değerlendirebileyim.

## Acceptance Criteria

- [ ] `Listing` modelinde `season`, `contractStartDate`, `contractEndDate`
      alanları var, mevcut ilanlarla geriye dönük uyumlu
- [ ] İlan formunda sezon seçilebiliyor, seçilirse tarih aralığı giriliyor
- [ ] Sezon seçilmemiş/boş ilanlarda form ve kart eskisi gibi çalışıyor
      (regresyon yok)
- [ ] İlan kartında sezon rozeti görünüyor (sezon varsa)
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, yeni model alanları için unit test eklendi

## Bağımlılıklar

- feature-9, feature-3 — tamamlandı.
- Bu spec, 018 ve 019'un önkoşuludur (özellikle 019) — erken merge edilmeli.

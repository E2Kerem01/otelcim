# GPS Tabanlı "Yakınımda" Özelliği

`feature-14` (Tourism Region-Based Job Discovery) kapsamının GPS parçası.
014 ile paralel başlanabilir ama ikisi de `listing_model.dart`'a alan
eklediği için **merge sırası: önce 014, sonra bu spec** — `master`'ı sık sık
senkronize et.

## Açıklama

Kullanıcının anlık GPS konumuna göre yakınındaki otel ilanlarını gösteren
"Yakınımda" (Near Me) özelliği. Yarıçap seçilebilir (25/50/100 km).

## Rationale

Sezonluk çalışanlar genelde bulundukları yere yakın iş arar. GPS bazlı
keşif, bölge bazlı keşfin (014) tamamlayıcısı — kullanıcı bölge adını
bilmese bile yakınındaki ilanları bulabilir.

## Yapılacaklar

- `Listing` modeline `lat`/`lng` (double?, nullable) alanları ekle,
  `toMap()`/`fromFirestore` güncelle. **014 ile aynı dosyayı değiştireceğin
  için, PR açmadan önce 014'ün merge olup olmadığını kontrol et, merge
  olduysa rebase et.**
- İlan oluşturma ekranına opsiyonel "konum ekle" adımı (mevcut adres/şehir
  alanının yanına, zorunlu değil — eski ilanlar konumsuz kalabilir).
- Konum izni akışı: `geolocator` (veya proje uygunsa `location`) paketiyle
  kullanıcının anlık GPS konumunu al. İzin istenirken neden istendiğini
  açıklayan bir dialog göster.
- "Yakınımda" giriş noktası: ana ekranda bir buton/sekme. Yarıçap seçici
  (25/50/100 km) ve mesafeye göre artan sıralama.
- Mesafe hesaplama client-side (Haversine) yeterli; ölçek büyürse
  Firestore geohash sorgusuna geçiş ayrı bir iş olarak not düşülsün (bu
  spec'in kapsamı dışında, kod içine TODO yorumu bırakma — spec.md'ye not
  düş).

## User Stories

- Sezonluk bir çalışan olarak, bulunduğum konuma yakın otel işlerini
  haritada/listede görmek istiyorum.

## Acceptance Criteria

- [ ] `Listing` modelinde `lat`/`lng` alanları var, mevcut ilanlarla uyumlu
- [ ] Konum izni açıklamalı şekilde isteniyor, reddedilirse özellik zarifçe
      devre dışı kalıyor (uygulama çökmüyor)
- [ ] "Yakınımda" ekranı/bölümü 25/50/100 km seçenekleriyle çalışıyor
- [ ] Sonuçlar mesafeye göre artan sırada listeleniyor
- [ ] Konumu olmayan ilanlar "Yakınımda" sonuçlarında görünmüyor ama diğer
      feed'lerde görünmeye devam ediyor
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, mesafe hesaplama fonksiyonu için unit test var

## Bağımlılıklar

- 014 ile aynı model dosyasını paylaşıyor — merge sırasına dikkat (bkz. genel kurallar §8).

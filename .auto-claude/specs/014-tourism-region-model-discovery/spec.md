# Turizm Bölgesi Modeli & Keşif Ekranı

`feature-14` (Tourism Region-Based Job Discovery) kapsamının temel parçası.
İlanlara Türkiye turizm bölgesi ata ve bölgelere göre gezinme ekranı oluştur.
Bu spec, 015 (harita) ve 016 (GPS) işçilerinin üzerine inşa edeceği temel alanı
sağladığı için **önce tamamlanıp merge edilmeli**.

## Açıklama

İş arayanlar, ilanları Türkiye'nin turizm bölgelerine göre (Antalya, Bodrum,
Fethiye, Marmaris, Kuşadası, Kapadokya, İstanbul, İzmir, Trabzon, Çeşme)
tarayabilmeli. Her bölge sayfası o bölgedeki aktif ilan sayısını ve öne çıkan
kategorileri gösterir.

## Rationale

Hiçbir rakip platform turizm-bölgesi bazlı iş keşfi sunmuyor. Türkiye'nin
otelcilik sektörü coğrafi olarak turizm bölgelerinde yoğunlaşmış durumda,
bu yüzden bölge bazlı keşif doğal bir uyum. `feature-9` (gelişmiş arama/filtre)
zaten tamamlandığı için bağımlılık karşılanmış durumda.

## Yapılacaklar

- `lib/features/listings/domain/listing_model.dart` içine `region` (String?,
  nullable — eski ilanlarda olmayabilir) alanı ekle. `toMap()`/`fromFirestore`
  ikisini de güncelle.
- İlan oluşturma/düzenleme ekranlarına (`create_listing_screen.dart`,
  `edit_listing_screen.dart`) bölge seçici (dropdown/chip) ekle.
- Yeni `lib/features/discovery/` (veya benzeri) klasöründe bölge listesi
  taşıyan sabit bir taxonomy dosyası oluştur (10 bölge, TR görünen ad + id).
- Yeni "Bölgeler" ekranı: bölgeleri kart/liste olarak göster, her kartta o
  bölgedeki aktif ilan sayısı (Firestore count query veya cache'lenmiş sayaç).
- Bölge kartına tıklayınca o bölgeye filtrelenmiş ilan feed'i açılsın (mevcut
  arama/filtre altyapısını region filtresiyle genişlet).
- Ana ekrana (`home_screen.dart`) "Bölgeler" ekranına giden bir giriş noktası ekle.

## User Stories

- Bir iş arayan olarak, ilanları tercih ettiğim turizm bölgesine göre
  taramak istiyorum ki hedef bölgedeki fırsatları bulabileyim.
- Taşınmayı düşünen bir iş arayan olarak, farklı turizm bölgeleri arasında
  iş yoğunluğunu karşılaştırmak istiyorum.

## Acceptance Criteria

- [ ] `Listing` modelinde `region` alanı var, mevcut ilanlarla geriye dönük uyumlu (null-safe)
- [ ] İlan oluşturma/düzenleme formunda bölge seçilebiliyor
- [ ] 10 önceden tanımlı turizm bölgesi sabit bir listede tutuluyor
- [ ] "Bölgeler" ekranı her bölge için aktif ilan sayısını gösteriyor
- [ ] Bölgeye tıklayınca o bölgeye filtrelenmiş ilan listesi açılıyor
- [ ] Bölgesi olmayan eski ilanlar hata vermeden, sadece "bölgesiz" olarak davranıyor
- [ ] Ana ekrandan Bölgeler ekranına ulaşılabiliyor
- [ ] Yeni/değişen tüm kullanıcı metinleri `app_tr.arb` ve `app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, yeni model alanı için unit test eklendi

## Bağımlılıklar

- feature-9 (Advanced Search & Filters) — tamamlandı, üzerine inşa edilecek.
- Bu spec, 015 ve 016'nın önkoşuludur — mümkün olduğunca erken merge edilmeli.

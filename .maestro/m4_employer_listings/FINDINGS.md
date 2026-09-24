# m4 employer listings bulguları

## Koddan doğrulanan bulgular

| Önem | Kaynak | Bulgu / beklenen davranış | Yeniden üretme |
|---|---|---|---|
| Yüksek | `lib/features/listings/presentation/edit_listing_screen.dart:180-223`, `lib/shared/services/listing_service.dart:234-242` | Edit formunun oluşturduğu `Listing` içinde `lat`, `lng` ve `isUrgent` alanları yok. Güncelleme mevcut belgeyi bu modelle yazdığı için L1 düzenlemesi koordinatları, L3 düzenlemesi acil niteliğini kaybedebilir veya kural hatası üretebilir. | `bugs/BUG-M4-01_edit_l1_preserves_location.yaml`, `bugs/BUG-M4-02_edit_l3_preserves_urgent.yaml` |
| Yüksek | `lib/features/listings/presentation/edit_listing_screen.dart:79-82`, `lib/features/listings/presentation/widgets/listing_form_fields.dart:142-169`, `.maestro/seed/seed.mjs:105` | L2 düzenleme ekranı Flutter `DropdownButton` assertion'ına düşüyor: seed `region: "Antalya"` yazıyor, edit dropdown `antalya` id'sini bekliyor. Ekran form yerine kırmızı Flutter error görünümüne geliyor. | `bugs/BUG-M4-04_edit_l2_region_assertion.yaml` |
| Yüksek | `lib/app/router.dart:91-109`, `lib/features/listings/presentation/create_listing_screen.dart:102-135` | Korumalı rota kontrolü yalnızca oturum durumunu kontrol ediyor; create ekranı da `userType` kontrol etmiyor. Jobseeker `İlan Ver` ekranını açabiliyor. | `bugs/BUG-M4-03_seeker_cannot_create.yaml` |
| Orta | `lib/features/listings/presentation/widgets/listing_form_fields.dart:435-483` | Lojman oda tipi seçilmeden `Klima` ve `Wi-Fi` switch'leri `onChanged` ile etkin. PLAN beklentisindeki “oda tipi seçilmeden pasif” davranışı kaynakta uygulanmıyor. Fotoğraf satırı görünür ama akış dosya seçmez. | `03_housing_and_urgent_options.yaml` ekranı doğrular; switch disabled durumu UI hiyerarşisiyle güvenilir biçimde ayrıştırılamaz. |
| Orta | `lib/features/listings/presentation/batch_create_listing_screen.dart:152-168` | Toplu ilan modeli şehir ve pozisyon alanlarını yazıyor fakat bölge ve sezon alanlarını formdan almıyor; toplu ilanlar bu alanları varsayılan/null bırakıyor. | `05_batch_two_positions.yaml` iki ilanın oluşmasını doğrular; bölge/sezon kaybı için backend gözlemi gerekir. |
| Düşük | `lib/features/listings/presentation/create_listing_screen.dart:187-222` | Tekli oluşturma sırasında `posterName: user.email` kullanılıyor; profil görünen adı/otel adı yerine e-posta ilan sahibinde görünebilir. | `01_create_listing_happy.yaml` başlık ve sonuç sayısını doğrular; poster metni kaynak davranışına bağlıdır. |

## Kod ve seed tutarsızlıkları

- Seed tüm ilanlarda `season: yaz_2026` veriyor (`.maestro/seed/seed.mjs`), ancak `lib/features/listings/presentation/season_utils.dart:3` yalnızca `yaz_2025`, `kis_2025_26`, `tum_yil` seçeneklerini sunuyor. Oluşturma akışında gerçek kaynak metni olan `Tüm Yıl` seçildi; `yaz_2026` UI’dan seçilemiyor.
- Seed’de L4 `isBoosted: true` olsa da `boost_purchases` belgesi yok. Bu nedenle `09_boost_screen_no_purchase.yaml` paket ekranını ve `Öne Çıkarılan İlanlarım` boş durumunu doğrular; L4 satın alma geçmişi beklenmiyor.

## UX / erişilebilirlik notları

- Edit formundaki başlık alanında `labelText` veya `hintText` yok (`edit_listing_screen.dart:418-423`). Edit akışları mevcut başlık metnini erişilebilir hedef olarak kullanıyor ve bu nedenle `# TAHMİN` ile işaretlendi.
- `İlanlarım` ekranındaki `Düzenle`, `Kapat` ve `Öne Çıkar` hedefleri satır başına tekrarlanıyor (`my_listings_screen.dart:107-119`). Akışlar seed’in `createdAt` sırasına göre `index` kullanıyor; Maestro UI hiyerarşisi farklı bir sırada dönerse bu seçiciler yeniden kalibre edilmeli.
- İlan kartı ve alt sekme etiketleri Flutter tarafından birleştirilebildiği için akışlarda `.*...*` regex biçimi kullanıldı.
- Paket kartları ve form başlıkları da alt öğeleriyle birleşik semantik metin üretebildiğinden 05 ve 09’da `.*...*` kullanıldı; 11’de yıldız ayrı `Text` olduğu için yıldız seçiciye dahil edilmedi.

## Test edilemeyen / bilinçli olarak tetiklenmeyenler

- Boost satın alma, ücretsiz boost kullanma ve Acil İlan satın alma düğmeleri güvenlik yasağı nedeniyle yalnızca ekran/paket/fiyat görünürlüğü seviyesinde bırakıldı.
- Tekli/toplu ilan fotoğrafı ve lojman fotoğrafı seçimi Storage’a gidebileceği için tetiklenmedi.
- Acil ücretli ekranına normal UI’dan ulaşmak için mevcut ilan üzerinde satın alma akışı gerekir; bu nedenle create formundaki `Acil İhtiyaç` seçeneği doğrulandı, ücretli satın alma ekranı açılmadı.
- Maestro/ADB/emülatör çalıştırılmadı; tüm seçiciler kaynak kod ve seed verisine göre yazıldı.

## Düzeltme turu

| FAIL | Karar | Yapılan işlem |
|---|---|---|
| 01_create_listing_happy | (a) test hatası | Hata ekranında uygulamanın ana ekranda olduğu görüldü; create formundaki `hideKeyboard` çağrıları Android geri davranışı nedeniyle uygulamayı kapatıyordu. Akıştan tüm `hideKeyboard` adımları kaldırıldı. |
| 02_create_listing_required_validation | (a) test hatası | Hata metinleri formda mevcut, ancak ekran görüntüsünde yalnızca alt bölüm viewport’ta. Her hata öncesine kaynak metniyle `scrollUntilVisible` eklendi. |
| 03_housing_and_urgent_options | (a) test hatası | `Lojman Bilgileri Ekle` formun başlangıç viewport’unda değil. Satıra önce aşağı kaydırma eklendi; acil alanı için de aşağı kaydırma yönü düzeltildi. |
| 04_batch_listing_required_validation | (a) test hatası | Doğrulamalar ekran görüntüsünde var fakat farklı form bölümlerinde. Kaynakta bulunan yedi hata metninin her biri öncesi viewport’a kaydırılıyor. |
| 05_batch_two_positions | (a) test hatası | `Otel / İşletme Bilgileri` görselde mevcut; birleşik Flutter semantiği için bekleme seçicisi `.*...*` biçimine çevrildi. Formdaki `hideKeyboard` çağrıları da kaldırıldı. |
| 06_edit_l2_title | (b) uygulama bug’ı | Ekran görüntüsünde kırmızı Flutter `DropdownButton` assertion’ı doğrulandı. Kaynak/seed uyumsuzluğu teyit edilerek akış `bugs/BUG-M4-04_edit_l2_region_assertion.yaml` altına taşındı; normal akış listesinde artık yok. |
| 07_close_l2_listing | (a) test hatası | “Ana Sayfa” bu ekranın AppBar’ında yok; ekran görüntüsü hâlâ `İlanlarım`ı gösteriyor. Önce `back` ile Hesabım’a, sonra Ana Sayfa sekmesine dönülecek şekilde düzeltildi. |
| 09_boost_screen_no_purchase | (a) test hatası | Paket ve fiyat metinleri ekran görüntüsünde mevcut; kart semantiği birleşik olduğundan tüm paket/fiyat/assert seçicileri `.*...*` yapıldı. Satın alma düğmesine basılmadı. |
| 10_restart_keeps_employer_session | (a) test hatası | Yeni cihaz kuralı gereği employer profilinde “İşveren” rol etiketi görünmüyor. Yanlış assert kaldırıldı, görünür `İlanlarım` satırıyla oturum doğrulanıyor. |
| 11_back_from_create | (a) test hatası | Kaynakta legend iki ayrı `Text` olarak oluşturuluyor; yıldızı seçiciye dahil etmek semantik boşluk/satır ayrımı nedeniyle eşleşmiyordu. Assert yıldız olmadan gerçek metne daraltıldı. |

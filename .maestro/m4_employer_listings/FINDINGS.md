# m4 employer listings bulguları

## Koddan doğrulanan bulgular

| Önem | Kaynak | Bulgu / beklenen davranış | Yeniden üretme |
|---|---|---|---|
| Yüksek | `lib/features/listings/presentation/edit_listing_screen.dart:180-223`, `lib/shared/services/listing_service.dart:234-242` | Edit formunun oluşturduğu `Listing` içinde `lat`, `lng` ve `isUrgent` alanları yok. Güncelleme mevcut belgeyi bu modelle yazdığı için L1 düzenlemesi koordinatları, L3 düzenlemesi acil niteliğini kaybedebilir veya kural hatası üretebilir. | `bugs/BUG-M4-01_edit_l1_preserves_location.yaml`, `bugs/BUG-M4-02_edit_l3_preserves_urgent.yaml` |
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

## Test edilemeyen / bilinçli olarak tetiklenmeyenler

- Boost satın alma, ücretsiz boost kullanma ve Acil İlan satın alma düğmeleri güvenlik yasağı nedeniyle yalnızca ekran/paket/fiyat görünürlüğü seviyesinde bırakıldı.
- Tekli/toplu ilan fotoğrafı ve lojman fotoğrafı seçimi Storage’a gidebileceği için tetiklenmedi.
- Acil ücretli ekranına normal UI’dan ulaşmak için mevcut ilan üzerinde satın alma akışı gerekir; bu nedenle create formundaki `Acil İhtiyaç` seçeneği doğrulandı, ücretli satın alma ekranı açılmadı.
- Maestro/ADB/emülatör çalıştırılmadı; tüm seçiciler kaynak kod ve seed verisine göre yazıldı.

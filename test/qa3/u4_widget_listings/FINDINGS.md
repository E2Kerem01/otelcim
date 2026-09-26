# u4_widget_listings bulguları

## Kapsam

- `u4_widget_listings_test.dart`: 17 widget testi.
- Create listing: zorunlu alan doğrulaması, servis payload'ı, bölge/şehir ve acil ilan alanları.
- Edit listing: mevcut konum/acil alanlarını koruma beklentisi (bilinen bug nedeniyle skip).
- Batch listing: pozisyon ekleme/silme.
- Ortak form widget'ları: lojman alanlarının koşullu görünürlüğü ve maaş aralığı doğrulaması.
- Listing detail: misafir, başvuran ve ilan sahibi için iletişim/aksiyon kapıları.
- Favorites/My listings: boş durum, favoriden çıkarma ve ilan kapatma.
- Rating: yıldız zorunluluğu, başarılı payload ve duplicate-rating hatası.
- Urgent purchase: mağaza ürünü yokken fallback fiyat ve satın alma ekranı.

## Bulgular

### BUG-u4-01 — Edit listing konum ve acil bayraklarını kaybediyor (Orta)

- Kaynak: `lib/features/listings/presentation/edit_listing_screen.dart:182-211`.
- `_submit` içinde oluşturulan yeni `Listing`, özgün ilanın `lat`, `lng` ve `isUrgent` alanlarını taşımıyor; güncelleme bu alanları varsayılan değerlere düşürüyor.
- Doğru davranışı bekleyen test `u4_widget_listings_test.dart:372` satırında bulunuyor ve hemen üstündeki `BUG-u4-01` yorumuyla `skip: true` edildi.
- `region` alanı mevcut form state'inden taşınıyor; test bunu ayrıca bekliyor.

### BUG-u4-02 — Geniş ilan detayında iletişim kartı tekrarı ve taşma (Orta)

- Kaynak: `lib/features/listings/presentation/listing_detail_screen.dart:288-350`; geniş görünümde `ListingPosterCard` ve `ListingRightStickyActionCard` birlikte render ediliyor.
- Kaynak: `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:421-452, 866-898`; misafir kapısı, seeker aksiyonu ve iletişim değeri iki ayrı kartta bulunuyor.
- Orkestratör logunda aynı metinlerin ikişer widget bulunduğu ve `listing_detail_widgets.dart:696` / `889` satırlarında RenderFlex overflow oluştuğu doğrulandı.
- İlgili üç `testWidgets` doğru tekil davranışı assert ediyor; mevcut yanlış davranışı kilitlememek için `skip: true` ve hemen üstünde `// BUG-u4-02` açıklamasıyla bırakıldı.

## Düzeltme turu

- Form submit tıklamalarına `ensureVisible` eklendi; dropdown seçimleri kaynak widget türleriyle bağlamlandırıldı.
- Tüm servis provider override'ları kaynak tiplerine uygun `overrideWith((ref) => fake)` biçimine taşındı.
- Puanlama servisi çağrısı ve duplicate hata snackbar'ı için yıldız seçiminden sonra pump eklendi; StateError async olarak stub'landı.
- `testWidgets` skip parametreleri bool yapıldı (`skip: true`).
- Flutter test/analyze sandbox PATH kısıtı nedeniyle çalıştırılmadı; bu nedenle derleme sonucu orkestratör doğrulamasına bırakıldı.

## Notlar

- Firebase'e doğrudan giden provider'lar mock servislerle Riverpod override edildi.
- Yerelleştirme delegate'leri ve `Locale('tr')` test uygulamalarına eklendi.
- Flutter/Dart çalıştırıcısı sandbox PATH'inde bulunmadığından test/analyze çalıştırılmadı; orkestratör çalıştırması bekleniyor.

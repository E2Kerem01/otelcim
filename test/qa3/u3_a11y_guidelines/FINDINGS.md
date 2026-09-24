# u3_a11y_guidelines bulguları

## Test kapsamı

`a11y_guidelines_test.dart` 12 ekran/durum için dört Flutter accessibility guideline’ını ayrı testlere ayırır: toplam 48 guideline testi. İkon etiketleri için 6 ek test bulunur. Semantics handle her testte `finally` bloğunda dispose edilir.

Kullanılan seam public widget + semantics ağacıdır. Testler mevcut `ProviderScope` override kalıbını ve Türkçe localization delegate’lerini kullanır.

## Bulgular

- **BUG-u3-01 / D29 — Orta:** `lib/features/listings/presentation/listing_detail_screen.dart:233-235`; paylaş ikonunda semantics label yok. Beklenen `Paylaş` etiketi için test skip’lidir.
- **BUG-u3-02 / D29 — Orta:** `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:349-352`; gönder ikonunda semantics label yok. Beklenen `Gönder` etiketi için test skip’lidir.

Favori, filtre, takvim, bölge/harita ve geri etiketleri için pozitif `find.bySemanticsLabel` kontrolleri eklendi. Guideline ihlallerinin gerçek sonucu orkestratörün Flutter çalıştırmasında görülecektir.

## Çalıştırma notu

Sandbox’ta `dart` ve `flutter` bulunamadığı için format/analyze çalıştırılamadı; dosya dikkatle kaynak imzalarına göre yazıldı.

# Lojman ve Sosyal İmkan Doğrulama Sistemi

Roadmap `feature-22` (`.auto-claude/roadmap/roadmap.json`, phase-5). Sahibinden
karşılaştırmasından ve Phase 5 pazar araştırmasından (`.auto-claude/ideation/
phase5-market-research.md`, Feature 5.1) çıkan MoSCoW "Must Have" madde.

## Açıklama

Otel ilanlarına opsiyonel bir "Lojman Bilgileri" bölümü ekle: oda tipi
(tek/çok kişilik), klima, Wi-Fi, öğün sayısı gibi yapılandırılmış alanlar
+ ayrı bir lojman fotoğrafı yükleme alanı.

## Yapılacaklar

- `lib/features/listings/domain/listing_model.dart`'a nullable alanlar
  ekle: `housingRoomType` (String?, "single"/"shared"), `housingHasAc`
  (bool?), `housingHasWifi` (bool?), `housingMealsIncluded` (int?),
  `housingImages` (List<String>, default boş liste).
- `create_listing_screen.dart`/`edit_listing_screen.dart`'a katlanabilir
  ("Lojman Bilgileri Ekle") bir bölüm ekle — mevcut fotoğraf yükleme
  desenini (`image_picker`+Storage) örnek al, lojman fotoğraflarını ayrı
  bir alanda sakla.
- `listing_detail_screen.dart`'a, lojman bilgisi varsa ayrı bir kart
  ("Lojman & Sosyal İmkanlar") ekle; yoksa bölüm tamamen gizlensin.

## Acceptance Criteria

- [ ] Model alanları eklendi, mevcut ilanlarla geriye dönük uyumlu
- [ ] Form ve detay ekranı roadmap'teki `feature-22` acceptance
      criteria'sını karşılıyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`listing_model.dart` ve `listing_detail_screen.dart`'a **032 (Acil Eleman)**
de dokunuyor — ikisi de sadece yeni alan/bölüm ekliyor, mevcut kodu
değiştirmiyor, çakışma riski düşük ama `master`'ı sık senkronize et.

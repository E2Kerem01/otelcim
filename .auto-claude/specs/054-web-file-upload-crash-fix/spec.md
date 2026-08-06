# Kritik: Web'de Dosya/Fotoğraf Yükleme Çökmesi (dart:io)

## Öncelik: ACİL (Critical) — canlı web sitesinde HER upload akışı çöküyor

## Kök Neden
`dart:io`'nun `File` sınıfı ve `Reference.putFile()` metodu Flutter Web'de desteklenmiyor (`Unsupported operation: _Namespace` hatası). Aşağıdaki dosyalarda `image_picker`/`file_picker`'dan gelen `XFile` doğrudan `File(xFile.path)`'e çevrilip Firebase Storage'a `putFile()` ile yükleniyor:

- `lib/shared/services/storage_service.dart` (7 farklı yerde `putFile` çağrısı: satır ~49, 146, 173, 208, 235, 285, 309)
- `lib/features/profile/presentation/widgets/profile_photo_picker.dart:93` — `File(image.path)`
- `lib/features/listings/presentation/create_listing_screen.dart:84,98` — `File(xFile.path)`
- `lib/features/listings/presentation/edit_listing_screen.dart:120,136` — `File(xFile.path)`
- **Kontrol et**: `lib/features/profile/presentation/widgets/intro_video_picker.dart` ve sertifika yükleme akışı da aynı deseni kullanıyor olabilir, grep ile doğrula (`grep -rn "File(" lib/ | grep -v test`).

## Yapılacaklar
1. `storage_service.dart`'taki tüm public upload metodlarının imzasını `File` yerine `XFile` (veya doğrudan `Uint8List` bytes) alacak şekilde değiştir.
2. Her metodun içinde `kIsWeb` kontrolü yap:
   - Web: `XFile.readAsBytes()` ile bytes al, `ref.putData(bytes, metadata)` kullan.
   - Native (mobil/desktop): mevcut `File`/`putFile()` davranışını koru (performans/bellek avantajı için).
3. Çağıran tüm ekranları (`profile_photo_picker.dart`, `create_listing_screen.dart`, `edit_listing_screen.dart`, `intro_video_picker.dart` varsa) güncelle: artık `File(xFile.path)`'e çevirmek yerine `XFile`'ı doğrudan `storage_service`'e geçirsinler.
4. Video/sertifika yükleme akışları da aynı düzeltmeyi almalı (`uploadCertificateFile`, video upload metodu).

## Dosya Çakışma Uyarısı
Bu spec sadece upload/storage ile ilgili dosyalara dokunuyor — `home_screen.dart`, `router.dart`, `firestore.rules`, `web/index.html` gibi diğer spec'lerin dokunduğu dosyalara DOKUNMA.

## Acceptance Criteria
- [ ] `storage_service.dart`'ta hiçbir metod artık koşulsuz `File`/`putFile` kullanmıyor — hepsi `kIsWeb` dallı
- [ ] Web'de (Chrome, `flutter run -d chrome` veya `-d web-server`) profil fotoğrafı yükleme çalışıyor, hata vermiyor
- [ ] Web'de ilan görseli / lojman fotoğrafı ekleme çalışıyor
- [ ] Mobil/native davranış regresyona uğramadı (aynı `File`/`putFile` yolunu kullanmaya devam ediyor)
- [ ] `flutter analyze` temiz, `flutter test` geçiyor

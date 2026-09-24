# m3_listing_detail bulguları

## Kaynak doğrulaması

- `lib/features/listings/presentation/listing_detail_screen.dart:204-228` detay AppBar'ını, favori tooltip'lerini ve favori yönlendirmesini render ediyor.
- `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:19-84` kategori, ilan tarihi, başlık ve şehir; `:87-120` maaş; `:219-313` lojman kartını render ediyor. Seed L1 için gerçek metinler `Çok kişilik oda`, `Klima`, `Wi-Fi`, `Günlük dahil öğün: 3`.
- `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:353-469` misafir için `İletişim bilgisini görmek için giriş yapın`, giriş yapmış kullanıcı için `İletişim Bilgisini Göster` ve contact bilgisini render ediyor.
- `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:472-522` güvenlik kartı ve ARB'den gelen `İlanı Şikâyet Et` aksiyonunu render ediyor.
- `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:654-939` geniş ekran sahip kartında `İlan Yönetimi`, `İlanı Öne Çıkar`, `QR Poster Oluştur`; sahip olmayan kullanıcı için `Başvur / Mesaj Gönder` aksiyonlarını render ediyor. Mobil dal `listing_detail_screen.dart:420-515` başlık göstermeden sahip için `İlanı Öne Çıkar` ve `QR Poster Oluştur`, sahip olmayan için `Mesaj Gönder` render ediyor.
- `lib/features/listings/presentation/listing_qr_poster_screen.dart:35-164` QR poster başlığı, ilan başlığı, işveren, şehir/maaş rozetleri ve tarama talimatı mevcut.

## Koddan görülen bug'lar

### BUG-m3-01 — Yüksek: mevcut raporun tekrar gönderilmesi

- Kaynak: `lib/shared/widgets/report_dialog.dart:38-84`, `lib/shared/services/report_service.dart:39-64`.
- Tekrar üretme: seeker ile L8 (`Güvenlik Görevlisi`) detayını aç, `İlanı Şikâyet Et` → `Gönder`.
- Beklenen: `Bu bildirimi daha önce gönderdiniz.`
- Önceki tur bilgisi: seed'deki R1 mevcut olmasına rağmen `hasAlreadyReported` sorgusu false dönüp yeni rapor oluşturabiliyor.
- Akış: `bugs/01_duplicate_l8_report.yaml`.

### BUG-m3-02 — Yüksek: detayda sezon, sözleşme tarihleri ve doğrulanmış işveren rozeti yok

- Model alanları mevcut: `lib/features/listings/domain/listing_model.dart:11,27-29`.
- L1 seed'inde `season: yaz_2026`, sözleşme başlangıç/bitiş tarihleri ve `posterVerified: true` var.
- `listing_detail_widgets.dart` içinde bu alanları okuyan/render eden bir bölüm yok; mevcut detay yalnızca başlık/şehir/maaş/lojman ve işveren adını gösteriyor.
- Beklenen: `Yaz 2026`, `Sözleşme başlangıcı`, `Sözleşme bitişi` ve doğrulanmış rozet.
- Akış: `bugs/02_l1_detail_metadata.yaml`.

### BUG-m3-03 — Orta: sahip detayında düzenleme aksiyonu yok

- Kaynak: `lib/features/listings/presentation/widgets/listing_detail_widgets.dart:745-773` yalnızca boost ve QR butonlarını oluşturuyor.
- Beklenen: kendi ilanında `Düzenle` ile birlikte boost/QR aksiyonları.
- Akış: `bugs/03_owner_edit_action.yaml`.

### Kod riski — Orta: rapor hedef tipi duplicate sorgusunda yok sayılıyor

- `ReportService.hasUserReportedTarget` (`lib/shared/services/report_service.dart:57-64`) aldığı `targetType` parametresini `hasAlreadyReported` çağrısına aktarmıyor; sorgu yalnızca `reporterId` ve `targetId` ile yapılıyor.
- Aynı kimlik farklı hedef türlerinde kullanılırsa yanlış duplicate sonucu üretilebilir.

## UX / erişilebilirlik bulguları

- Detay AppBar'ındaki paylaşım ve rapor `IconButton`/`PopupMenuButton`'larında tooltip yok (`listing_detail_screen.dart:230-263`). Maestro akışları bu ikonları hedeflemek yerine metinli güvenlik aksiyonunu kullanıyor; ikon-only yol için erişilebilirlik etiketi eklenmesi gerekir.
- Favori ikonu tooltip ile erişilebilir (`listing_detail_screen.dart:211-213`), bu nedenle `Favorilere ekle` / `Favorilerden çıkar` seçicileri kaynak doğruludur.
- İlan detayında `posterVerified` bilgisi modele alınmasına rağmen görsel doğrulama rozeti yok.

## Test edilemeyen veya bilerek tetiklenmeyen yollar

- WhatsApp butonuna basılmadı; dış uygulama açar.
- QR poster `Paylaş` / sistem paylaşım diyaloğu ve ilan paylaşımı tetiklenmedi.
- Boost satın alma/ücretsiz boost kullanma akışları tetiklenmedi.
- Fotoğraf/dosya yükleme ve örnek ilan seed butonu kullanılmadı.
- Seed tarihleri dinamik olduğu için kesin sözleşme tarihleri normal akışlarda assert edilmedi; eksik metadata için beklenen değerler ayrı bug akışına kondu.
- Cihaz, emulator, Maestro ve adb çalıştırılmadı; bu teslimat kaynak okuma ve YAML yazımıyla sınırlıdır.

## Düzeltme turu gözlemi

- Mobil detaydaki eylem seçicileri responsive dala göre ayrıldı: mobilde `Mesaj Gönder` ve sahipte `İlanı Öne Çıkar` / `QR Poster Oluştur`; geniş ekran başlığı `İlan Yönetimi` mobilde beklenmiyor.
- L2 ve L6 açılışları liste sırasına ve görünür viewport'a bağlı kalmaması için L2'de görünür olana kadar kaydırma, L6'da deep link kullanıyor.
- Geniş regex'in yanlış/örtüşen öğeye dokunma riskini azaltmak için misafir iletişim CTA'sı tam metin + `index: 0` ile hedeflendi.

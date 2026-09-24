# m10_gaps_misc bulguları

## Kod bulguları

### BUG-m10-01 — Yüksek

- Konum: `lib/features/onboarding/presentation/role_selection_screen.dart:55-57`
- Yeniden üretme: Oturum açmış `seeker@e2e.test` ile `/onboarding/role` aç, `Personel Arıyorum` ve `Devam Et` seç, Hesabım ekranına dön.
- Beklenen: Seçilen rol kullanıcı profilinde kalıcı olmalı; işveren menüsündeki `Yetenek Havuzum` görünmeli.
- Gerçek: Ekran yalnızca `onboardingProvider.notifier.selectRole(...)` çağırıp `/` rotasına gider. Kullanıcı profilini güncelleyen servis çağrısı yok; mevcut jobseeker profili değişmiyor.
- Akış: `bugs/01_role_selection_not_persisted.yaml`

### BUG-m10-02 — Yüksek

- Konum: `lib/features/listings/presentation/urgent_listing_purchase_screen.dart:58-63,153-160,269-297`
- Yeniden üretme: `seeker@e2e.test` ile `/listing/L6/urgent` deep link’ini aç.
- Beklenen: İlan sahibi olmayan/iş arayan kullanıcıya yetki reddi veya ana sayfaya dönüş gösterilmeli.
- Gerçek: Kod yalnızca Firebase kullanıcısının varlığını kontrol ediyor; sahiplik ve `userType` kontrolü olmadan fiyat ve `Satın Al ve Acil Yap` düğmesini render ediyor.
- Akış: `bugs/02_urgent_wrong_owner.yaml`

### BUG-m10-03 — Orta

- Konum: `lib/features/listings/presentation/urgent_listing_purchase_screen.dart:153-160,233-297`
- Yeniden üretme: `employer@e2e.test` ile zaten `isUrgent: true` olan L3 için `/listing/L3/urgent` aç.
- Beklenen: İlanın zaten acil olduğu belirtilmeli ve tekrar ücretlendirme aksiyonu gösterilmemeli.
- Gerçek: `listing.isUrgent` için görünürlük/guard yok; ücret kartı ve satın alma düğmesi oluşturuluyor.
- Akış: `bugs/03_urgent_already_active.yaml`

### BUG-m10-04 — Orta

- Konum: `lib/features/profile/presentation/profile_screen.dart:37-42,231-238`
- Yeniden üretme: Seeker ile Hesabım ekranında aşağıdaki `Çıkış Yap` düğmesine bas.
- Beklenen: Yanlışlıkla çıkışı önleyen onay diyaloğu açılmalı.
- Gerçek: `_handleLogout` doğrudan `signOut()` çağırıp `/login` rotasına gider; onay diyaloğu yok.
- Akış: `bugs/04_logout_confirmation_missing.yaml`

### BUG-m10-05 — Yüksek

- Konum: `lib/features/discovery/domain/tourism_region.dart:17-88`, `lib/shared/services/listing_service.dart:358-363`, `.maestro/seed/seed.mjs:109-111`
- Yeniden üretme: `/regions` ekranından Bodrum’u veya `/regions/bodrum` deep link’ini aç.
- Beklenen: Seed’de şehir `Bodrum`, bölge `Muğla` olan L6 (`Animatör`) ilgili bölge detayında görünmeli.
- Gerçek: Bölge kataloğunda `bodrum` var fakat L6’nın `region` değeri `Muğla`; detay filtresi `listing.region == initialRegion` ile ID karşılaştırıyor. Ayrıca `Muğla` ve `Nevşehir` katalogda bulunmuyor.
- Akış: `bugs/05_region_detail_id_mismatch.yaml`

## UX / erişilebilirlik bulguları

- Mobil profil menüsündeki satır başlıkları (ör. `Gizlilik ve Veri Ayarları`, `Belgelerim / Sertifika Cüzdanı`) gerçek widget metinleriyle seçilebilir; ancak rol etiketi mobil yerleşimde görünür bir metin olarak sunulmuyor. Rol doğrulaması bu nedenle menü farkı (`Yetenek Havuzum`) üzerinden yapılmalıdır.
- `profile_screen.dart` içindeki mobil profil menü başlıklarının çoğu hardcoded Türkçe; çeviri kapsamı genişletilecekse bu metinler ARB’ye taşınmalı.
- `urgent_listing_purchase_screen.dart` içindeki ödeme düğmesi görünür metinle erişilebilir. Testlerde düğmeye basılmadı; IAP/callable tetiklenmemesi için yalnızca ekran ve fiyat assert edildi.
- KVKK veri dışa aktarma `share_plus` ile sistem paylaşım UI’ına geçiyor (`lib/features/profile/presentation/privacy_settings_screen.dart:65-72`). Uygulama içi assert, sistem paylaşım sağlayıcısına göre değişebileceği için bu turda yalnızca ekran ve silme diyaloğu güvenlik kontrolleri test edildi.

## Test edilemeyen / uygulanmayan akışlar

- Şifremi unuttum: `lib/app/router.dart` ve `lib/features/auth/presentation/login_screen.dart` içinde parola sıfırlama rotası/bağlantısı bulunamadı; bu nedenle akış yazılmadı.
- Dosya, profil fotoğrafı, sertifika veya ilan görseli yükleme: PLAN güvenlik yasağı nedeniyle yalnızca boş sertifika durumu açıldı, `Belge Yükle` tetiklenmedi.
- Acil ilan satın alma / ücretsiz boost / redeem: PLAN güvenlik yasağı nedeniyle paket/fiyat ekranı açıldı, satın alma düğmesine basılmadı.
- SMS akışları TUR 2 kuralına göre emülatör destekli hale geldiği için `Kod Gönder` yalnızca `05_sms_wrong_code.yaml` ve `06_sms_happy.yaml` içinde kullanıldı; doğrulama kodu `sms_code.js` ile alındı.

## Seçici notları

- Seçiciler kaynak kodundaki ARB veya hardcoded Türkçe metinlerden türetildi.
- Bir tahmin edilen seçici var: `bugs/04_logout_confirmation_missing.yaml` içindeki beklenen onay metni kaynakta bulunmadığı için `# TAHMİN:` ile işaretlendi.
- Form alanlarında regex yerine tam etiket kullanıldı (`E-posta`, `Şifre`, `Telefon Numarası`, `SMS Doğrulama Kodu`).

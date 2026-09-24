# m9_admin_content bulguları

## Kod bulguları

- **Yüksek — BUG-m9-01 / D9:** `lib/features/admin/services/verification_service.dart:48-66` içindeki `approveVerification` yalnızca `verification_requests/{id}` belgesini `approved` yapıyor; ilgili `user_profiles/{employer3}` belgesindeki `isVerified`, `verificationStatus` ve `verifiedAt` alanları güncellenmiyor. Ayrıca `lib/features/profile/presentation/profile_screen.dart:292-301` mobil işveren kartında `isVerified` için bir rozet/metin render etmiyor. Yeniden üretme: `bugs/BUG-m9-01_verification_profile_not_reflected.yaml`; beklenen: onay sonrası employer3 Hesabım ekranında doğrulanmış durum; gerçek: beklenen metin/rozet yok.
- **Orta:** `lib/features/admin/presentation/verification_review_screen.dart:117` doğrulama kartında başvuru sahibinin adı yerine yalnızca `employerId` gösteriliyor (`İşveren: <uid>`). Seed’deki “Can Başvuran” adı admin kuyruğunda görünmüyor; akış bu nedenle `Yeni Otel` ve talep içeriğiyle doğrulama yapıyor.
- **Orta:** `lib/features/ads/presentation/admin_banner_ads_screen.dart:174-185` banner kartındaki `Switch` için label, `tooltip` veya `Key` verilmemiş. Banner aktif/pasif testinde kaynakta etiketli olan düzenleme formundaki `SwitchListTile` (`Aktif Yayın Lansmanı`) kullanıldı; karttaki doğrudan switch erişilebilirlik açısından ayrıca doğrulanmalıdır.
- **Düşük:** Banner yönetim ekranı harici hedef URL’yi ve görsel URL’sini gösteriyor; seed URL’leri `example.invalid` olduğu için akışlar belge/görsel/URL açma aksiyonlarına basmıyor.

## Akış kapsamı

- 01–03: tüm durumları içeren ilan listesi, kapalı ilan görünürlüğü, kaldırma/geri yükleme, boş arama ve yeniden başlatma.
- 04–05: bekleyen işveren doğrulaması, onay, zorunlu red sebebi ve red.
- 06–07: bekleyen sertifika, onay/red ve seeker profilindeki kalıcı durum.
- 08–10: pasif banner listesi, form üzerinden aktif/pasif geçişi, ana sayfa görünürlüğü, zorunlu alan doğrulaması ve yeniden başlatma.
- 11–12: seeker ve normal employer için admin route guard’ları.

## Test edilemeyen / bilerek dokunulmayanlar

- Doğrulama ve sertifika `Belge 1` / `Belge / Sertifika Dosyası` bağlantıları `https://example.invalid/...` olduğundan açılmadı.
- Banner formundaki `Görsel Yükle` ve görsel seçici/Storage yüklemesi güvenlik yasağı nedeniyle çalıştırılmadı. Form yalnızca boş/hatalı alan doğrulamasıyla test edildi; mevcut A1 düzenlemesinde seed görsel URL’si zaten dolu olduğu için kaydetme yapılabildi.
- Banner hedef bağlantısı, silme işlemi ve görsel yükleme tetiklenmedi; harici sistem/Storage etkisi yaratmamak için yalnızca metinler ve yönetim durum geçişi doğrulandı.

# m1_auth bulguları

## Bug'lar

### BUG-M1-01 — Orta

- Kaynak: `lib/features/auth/presentation/register_screen.dart:67-81`, `lib/app/router.dart:148-149`, `lib/shared/services/auth_service.dart:62-70,182-197`.
- Tekrar: `bugs/BUG-M1-01_register_onboarding_expected.yaml` akışını çalıştır.
- Beklenen: Yeni e-posta kaydı, plan gereği onboarding/rol ekranına (`Otelcim'e Hoş Geldiniz!`, `Devam Et`) gider.
- Gerçek: `RegisterScreen` rolü zaten kayıt formunda alıyor; kayıt sonrası oturum açılmış `/register` konumu router tarafından `/` konumuna yönlendiriliyor. `consumeJustRegistered()` tanımlı olsa da router tarafından kullanılmıyor.

### BUG-M1-02 — Yüksek

- Kaynak: `lib/app/router.dart:111-114` korumalı rota için oturum kapalıyken `/login` yönlendirmesi; cihaz sonucu ile birlikte login ekranından Android `back` sonrası navigator yığını boş kalıyor.
- Tekrar: `bugs/BUG-M1-02_protected_tab_back_exits_app.yaml` akışını çalıştır.
- Beklenen: Korumalı sekmeden login'e yönlenen kullanıcı geri ile ana sayfaya döner.
- Gerçek: Login ekranından `back` uygulamayı kapatıp Android ana ekranına düşürüyor; akış ana sayfa assert'inde kırılıyor.

### BUG-M1-03 — Yüksek

- Kaynak: `lib/features/profile/presentation/profile_screen.dart:37-42` `_handleLogout` açıkça `context.go('/login')` çağırıyor; `lib/app/router.dart:119-125` auth değişiminde korumalı rotayı login'e yönlendirmeyi amaçlıyor.
- Tekrar: `bugs/BUG-M1-03_logout_stays_home.yaml` akışını çalıştır.
- Beklenen: Hesabım'dan `Çıkış Yap` sonrası login ekranı görünür.
- Gerçek: Cihaz görüntüsünde doğru çıkış düğmesine tıklama sonrası ana sayfa görünür; `Giriş Yap` bulunamaz.

### BUG-M1-04 / BUG-M1-05 — Yüksek

- Kaynak: `lib/features/auth/presentation/account_suspended_screen.dart:18-24` her `build` çağrısında yeni bir inline `FutureProvider` oluşturuyor. Cihaz görüntüsünde destek açıklaması ve `Çıkış Yap` görünürken profil sorgusu spinner'da kalıyor; `Hesabınız Yasaklandı` / `Hesabınız Askıya Alındı` başlıkları ve askı bitişi yüklenmiyor.
- Tekrar: `bugs/BUG-M1-04_banned_account_title_spinner.yaml` ve `bugs/BUG-M1-05_suspended_account_title_spinner.yaml` akışlarını çalıştır.
- Beklenen: Banlı kullanıcıda `Hesabınız Yasaklandı`; askıdaki kullanıcıda `Hesabınız Askıya Alındı` ve `Askı bitiş: ...` görünür.
- Gerçek: Başlık bölgesinde yükleme spinner'ı kalıyor.

## UX / erişilebilirlik

- `lib/features/auth/presentation/register_screen.dart:375-390` rol kartları `InkWell` ile oluşturuluyor, ayrı `Semantics` veya key yok. Maestro seçicisi görünür başlık metninin Flutter erişilebilirlik etiketine birleşmesini varsayar; akışlarda bu nedenle ilgili satırlarda `# TAHMİN:` notu vardır.
- `lib/features/auth/presentation/login_screen.dart:201-206,451-458` telefon sekmesi ve `Kod Gönder` canlı SMS doğrulama yoluna bağlıdır. Güvenlik kuralı gereği bu akış SMS gönderimini tetiklemez; yalnızca alan/hint görünürlüğünü kontrol eder.
- `lib/features/auth/presentation/login_screen.dart:262-275` Checkbox ve `Beni Hatırla` metni ayrı widget'lardır fakat Flutter semantiği üst düğümde birleşir; metin seçicisi görsel kutunun kendisini güvenilir biçimde hedeflemez. `12_remember_me_off_restart.yaml` bu nedenle koordinat seçicisi kullanır ve `# TAHMİN:` ile işaretlenmiştir.
- `lib/features/auth/presentation/register_screen.dart:228-249` `Ad Soyad` ve `Otel / İşletme Adı` hardcoded Türkçedir; diğer auth metinlerinin bir kısmı `app_tr.arb` üzerinden gelir.

## Test edilemeyen / kapsam notları

- Login ekranında `Şifremi unuttum` bağlantısı yok; bu nedenle şifre sıfırlama akışı yazılmadı.
- SMS doğrulama kodu gönderimi güvenlik yasağı nedeniyle tetiklenmedi; `05_login_phone_validation_only.yaml` bu sınırı açıkça korur.
- Fotoğraf/dosya yükleme, satın alma/boost/redeem, Firebase dışı canlı entegrasyonlar ve Maestro/ADB cihaz çalıştırması yapılmadı.
- `account-suspended` ekranında geri tuşu testleri, router'ın her hedefte askıya alınmış profili tekrar `/account-suspended` konumuna yönlendirmesi beklentisiyle bug akışlarında tutuldu; başlık yükleme problemi nedeniyle varsayılan koşuda çalıştırılmamalıdır.

## Düzeltme turu notları

- Cihaz görüntüsünde mobil Hesabım ekranı rol etiketini göstermiyor; `01_login_seeker.yaml` artık `Hemen Başlayabilir` kartını doğruluyor.
- Kırılan login/kayıt alanlarında birleşik sekme etiketiyle çakışan regex seçiciler kaldırıldı; `E-posta` ve `Şifre` tam metinle seçiliyor. Düzeltilen auth akışlarında `hideKeyboard` kullanılmıyor.
- `09_register_duplicate_email.yaml` içinde klavye açıkken kayıt düğmesinin görünür alana alınması için `scrollUntilVisible` eklendi; kayıt ekranında `hideKeyboard` kullanılmıyor.
- `12_remember_me_off_restart.yaml` içinde metin yerine Checkbox'ın kaynak yerleşiminden türetilmiş `%13,%69` nokta seçicisi kullanıldı; bu seçici `# TAHMİN:` olarak işaretlidir.
- `phoneHint` (`5XX XXX XX XX`) kaynak ARB'de olsa da cihaz etiketinde görünmedi; telefon akışı gerçek `Telefon Numarası` label'ına indirgenerek SMS tetiklemeden formu doğruluyor.
- D7 geri tuşu davranışı gerçek uygulama bug'ı olarak `bugs/BUG-M1-02_protected_tab_back_exits_app.yaml` dosyasına taşındı: login'den `back` uygulamayı ana ekrana kapatıyor.
- Çıkış sonrası login yönlendirmesi `BUG-M1-03` olarak; ban/askı profil başlığının spinner'da kalması `BUG-M1-04` ve `BUG-M1-05` olarak varsayılan koşudan çıkarıldı.

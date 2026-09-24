# m1_auth bulguları

## Bug'lar

### BUG-M1-01 — Orta

- Kaynak: `lib/features/auth/presentation/register_screen.dart:67-81`, `lib/app/router.dart:148-149`, `lib/shared/services/auth_service.dart:62-70,182-197`.
- Tekrar: `bugs/BUG-M1-01_register_onboarding_expected.yaml` akışını çalıştır.
- Beklenen: Yeni e-posta kaydı, plan gereği onboarding/rol ekranına (`Otelcim'e Hoş Geldiniz!`, `Devam Et`) gider.
- Gerçek: `RegisterScreen` rolü zaten kayıt formunda alıyor; kayıt sonrası oturum açılmış `/register` konumu router tarafından `/` konumuna yönlendiriliyor. `consumeJustRegistered()` tanımlı olsa da router tarafından kullanılmıyor.

## UX / erişilebilirlik

- `lib/features/auth/presentation/register_screen.dart:375-390` rol kartları `InkWell` ile oluşturuluyor, ayrı `Semantics` veya key yok. Maestro seçicisi görünür başlık metninin Flutter erişilebilirlik etiketine birleşmesini varsayar; akışlarda bu nedenle ilgili satırlarda `# TAHMİN:` notu vardır.
- `lib/features/auth/presentation/login_screen.dart:201-206,451-458` telefon sekmesi ve `Kod Gönder` canlı SMS doğrulama yoluna bağlıdır. Güvenlik kuralı gereği bu akış SMS gönderimini tetiklemez; yalnızca alan/hint görünürlüğünü kontrol eder.
- `lib/features/auth/presentation/register_screen.dart:228-249` `Ad Soyad` ve `Otel / İşletme Adı` hardcoded Türkçedir; diğer auth metinlerinin bir kısmı `app_tr.arb` üzerinden gelir.

## Test edilemeyen / kapsam notları

- Login ekranında `Şifremi unuttum` bağlantısı yok; bu nedenle şifre sıfırlama akışı yazılmadı.
- SMS doğrulama kodu gönderimi güvenlik yasağı nedeniyle tetiklenmedi; `05_login_phone_validation_only.yaml` bu sınırı açıkça korur.
- Fotoğraf/dosya yükleme, satın alma/boost/redeem, Firebase dışı canlı entegrasyonlar ve Maestro/ADB cihaz çalıştırması yapılmadı.
- `account-suspended` ekranında geri tuşu testleri, router'ın her hedefte askıya alınmış profili tekrar `/account-suspended` konumuna yönlendirmesi beklentisiyle yazıldı.


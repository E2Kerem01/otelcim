# m8_admin_core bulguları

## Kod bulguları

| Önem | Konum | Bulgu | Tekrar üretme | Beklenen / gerçek |
|---|---|---|---|---|
| Kritik | lib/features/admin/presentation/reports_moderation_screen.dart:60-102 | Rapor reddetme tamamlanırken Flutter framework assertion ile uygulama kırmızı hata ekranına düşüyor. | bugs/BUG-M8-02_report_dismiss_crash.yaml | Beklenen: Şikayeti Reddet işlemi tamamlandı. ve boş bekleyen liste. Gerçek: _dependents.isEmpty assertion ekranı. |
| Kritik | lib/features/admin/presentation/reports_moderation_screen.dart:62-102 | Raporlanan ilanı kaldırma tamamlanırken Flutter framework assertion ile uygulama kırmızı hata ekranına düşüyor. | bugs/BUG-M8-03_report_remove_crash.yaml | Beklenen: İlanı Kaldır işlemi tamamlandı. ve L8'in feed'den kalkması. Gerçek: kırmızı Flutter assertion ekranı. |
| Yüksek | lib/features/profile/presentation/profile_screen.dart:37-43 | Kaynakta çıkış sonrası /login çağrılmasına rağmen cihazda çıkış sonrası ana sayfa kaldı; login bekleyen akış ilerleyemedi. | bugs/BUG-M8-04_logout_returns_home.yaml | Beklenen: Giriş Yap ekranı. Gerçek: Ana Sayfa. |
| Orta | lib/features/admin/presentation/user_management_screen.dart:197-203,236-347 | Arama sonuçları işlem sonrası yeniden sorgulanmadığı için kartta eski ban/askı durumu gösteriliyor; backend işlemi ve SnackBar tamamlanıyor. | 08_suspend_user_and_audit.yaml, 10_unban_seed_user.yaml | Beklenen: işlem sonrası güncel durum. Gerçek: yeniden arama yapılana kadar eski kart. |
| Yüksek | `lib/features/admin/presentation/user_management_screen.dart:277-347` | Yönetici kendi profilinde de `Yasakla` ve `Askıya Al (7 gün)` aksiyonlarını görüyor; `currentUser.uid` ile kart kullanıcısı arasında koruma yok. | `bugs/BUG-M8-01_admin_self_ban_available.yaml` | Beklenen: self-ban/self-suspend aksiyonları gizli veya pasif. Gerçek: aksiyonlar görünür. |

## UX ve erişilebilirlik

- Admin kartları ve eylemler çoğunlukla metin taşıyor; ayrı `Key`/`Semantics` kullanılmadığı için akışlar birleşik Flutter metin etiketlerine ve regex'e dayanıyor.
- `ReportsModerationScreen` ve `UserManagementScreen` içindeki form alanları yalnızca `labelText` ile tanımlı. Bu nedenle akışlarda form alanları için tam metin seçicileri kullanıldı; `.*E-posta.*` gibi geniş regex kullanılmadı.
- `AuditLogScreen` yönetici filtresindeki ikon butonu tooltip ile (`Yönetici filtresi`) etiketlenmiş; filtre akışında seçici gerektiğinde bu erişilebilirlik etiketi kullanılabilir.

## Test edilemeyen / kapsam dışı

- Admin dashboard’un doğrulama, ilan, sertifika ve banner kartları bu dilimin kapsamındaki ekranların dışına yönlendiği için kartların varlığı assert edildi; hedef ekranların içerik/aksiyon doğrulaması m9 kapsamındadır.
- Belge linkleri ve dosya yükleme yoklandı/çalıştırılmadı; PLAN güvenlik yasağı gereği dış URL veya Storage tetiklenmedi.
- Rapor kartında kullanıcı hedefi bulunmadığı için `Uyar`, `Askıya al`, `Yasakla` rapor aksiyonlarının tamamı bu seed ile çalıştırılamadı; kullanıcı askıya alma/ban akışları doğrudan `/admin/users` üzerinden test edildi.
- Maestro/ADB/emülatör çalıştırılmadı; seçiciler kaynak kodundan türetildi.

## Seçici notları

- Gerçek kaynak metinleri: `Yönetim Paneli`, `Şikâyetler`, `Kullanıcı Yönetimi`, `İlan Yönetimi`, `Belge Onay Kuyruğu`, `Banner Reklamlar`, `İşlem Geçmişi`, `E-posta veya isimle ara`, `Sonuç bulunamadı.`, `Sebep (zorunlu)`, `Sebep (isteğe bağlı)`, `Uygula`, `Onayla`, `Vazgeç`.
- Rapor hedefi seed verisinden `Hedef: İlan • L8`, rapor açıklaması `Şüpheli ilan`; kullanıcı isim/e-posta değerleri seed.mjs'den alındı.
- Dinamik tarihli askı etiketi için `.*Askıda \(.* kadar\).*` kullanıldı.
- Admin guard davranışı `router.dart` içindeki `/admin` profil kontrolünden türetildi: admin olmayan oturum `/` rotasına döner.

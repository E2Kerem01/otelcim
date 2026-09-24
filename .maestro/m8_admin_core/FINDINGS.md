# m8_admin_core bulguları

## Kod bulguları

| Önem | Konum | Bulgu | Tekrar üretme | Beklenen / gerçek |
|---|---|---|---|---|
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


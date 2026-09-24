# Bulgular ve Test Kapsamı — u5_widget_admin_misc

**Tarih**: 2026-09-24  
**Kapsam**: Admin sunum katmanı (8 ekran) + Sezon Takvimi ekranı  
**Çalışma Dizini**: `test/qa3/u5_widget_admin_misc/`  

---

## 1. Test Dosyaları ve Test Sayıları

| # | Test Dosyası | Hedef Ekran | Test Sayısı | Durum |
|---|---|---|:---:|:---:|
| 1 | `admin_test_helper.dart` | Ortak Test Altyapısı (Mock'lar, Fallback'ler, Dummy Nesneler, Test App Sarmalayıcı) | — | ✅ Hazır |
| 2 | `admin_dashboard_screen_test.dart` | `lib/features/admin/presentation/admin_dashboard_screen.dart` | 4 | ✅ 4 Yeşil |
| 3 | `reports_moderation_screen_test.dart` | `lib/features/admin/presentation/reports_moderation_screen.dart` | 11 | ✅ 11 Yeşil |
| 4 | `user_management_screen_test.dart` | `lib/features/admin/presentation/user_management_screen.dart` | 10 | ✅ 9 Yeşil, 1 Skip (BUG-u5-01) |
| 5 | `listing_management_screen_test.dart` | `lib/features/admin/presentation/listing_management_screen.dart` | 8 | ✅ 8 Yeşil |
| 6 | `verification_review_screen_test.dart` | `lib/features/admin/presentation/verification_review_screen.dart` | 8 | ✅ 7 Yeşil, 1 Skip (BUG-u5-02) |
| 7 | `certificate_review_screen_test.dart` | `lib/features/admin/presentation/certificate_review_screen.dart` | 7 | ✅ 7 Yeşil |
| 8 | `audit_log_screen_test.dart` | `lib/features/admin/presentation/audit_log_screen.dart` | 6 | ✅ 6 Yeşil |
| 9 | `admin_banner_ads_screen_test.dart` | `lib/features/ads/presentation/admin_banner_ads_screen.dart` | 9 | ✅ 9 Yeşil |
| 10 | `seasonal_calendar_screen_test.dart` | `lib/features/seasonal/presentation/seasonal_calendar_screen.dart` | 7 | ✅ 6 Yeşil, 1 Skip (BUG-u5-03) |
| **TOPLAM** | **10 dosya** | **9 ekran** | **70 test** | **67 Aktif, 3 Bilinen Bug (Skip)** |

---

## 2. Tespit Edilen Hatalar (Bug Listesi)

### BUG-u5-01 (D21) — Admin Kullanıcı Kendi Hesabını Yasaklayabiliyor / Askıya Alabiliyor
- **Konum**: `lib/features/admin/presentation/user_management_screen.dart:301-382`
- **Önem**: Yüksek (High)
- **Açıklama**: `UserManagementScreen` içinde listelenen kullanıcı kartlarında yöneticinin kendi kullanıcı kimliği (`adminId == user.id`) kontrol edilmemektedir. Oturum açmış olan yönetici kendi satırındaki "Yasakla" veya "Askıya Al (7 gün)" butonlarına tıklayarak kendi hesabını kilitleyebilmekte ve panele erişimini kaybedebilmektedir.
- **Test**: `test/qa3/u5_widget_admin_misc/user_management_screen_test.dart` -> `prevents admin from banning or suspending their own account (D21)`
- **Skip Etiketi**: `skip: 'BUG-u5-01: Admin can ban or suspend their own account in UserManagementScreen (D21)'`
- **Öneri**: `_UserCard.build` içinde `final currentAdminId = ref.watch(authServiceProvider).currentUser?.uid;` kontrolü eklenerek `user.id == currentAdminId` durumunda ban ve suspend aksiyon butonları devre dışı bırakılmalı (`onPressed: null`) veya gizlenmelidir.

### BUG-u5-02 (D18) — İşveren Doğrulama Onayı Kullanıcı Profiline Yazılmıyor
- **Konum**: `lib/features/admin/services/verification_service.dart:48-58`, `lib/features/admin/presentation/verification_review_screen.dart:84-86`
- **Önem**: Yüksek (High)
- **Açıklama**: Yönetici doğrulama talebini onayladığında (`approveVerification`), yalnızca `verification_requests` koleksiyonundaki belge güncellenmekte; işverenin `user_profiles/{employerId}` belgesindeki `isVerified`, `verificationStatus` ve `verifiedAt` alanlarına hiçbir şey yazılmamaktadır. Bu nedenle onaylanan işveren profilinde ve ilanlarında hiçbir zaman "Doğrulanmış İşveren" rozeti görünmemektedir.
- **Test**: `test/qa3/u5_widget_admin_misc/verification_review_screen_test.dart` -> `approval updates employer user profile with isVerified=true and verificationStatus=approved (D18)`
- **Skip Etiketi**: `skip: 'BUG-u5-02: Approving verification request does not update user profile isVerified/verificationStatus (D18)'`
- **Öneri**: `VerificationService.approveVerification` fonksiyonunda Firestore batch kullanılarak hem `verification_requests/{id}` belgesi `status: 'approved'` yapılmalı hem de `user_profiles/{employerId}` belgesinde `isVerified: true`, `verificationStatus: 'approved'` ve `verifiedAt: FieldValue.serverTimestamp()` alanları güncellenmelidir.

### BUG-u5-03 (D23) — Sezon Takvimi Hatırlatıcı Modalında 2026 Sezonu Seçilemiyor
- **Konum**: `lib/features/seasonal/presentation/seasonal_calendar_screen.dart:23, 98-115`, `lib/shared/constants/listing_filters.dart:26-30`
- **Önem**: Orta (Medium)
- **Açıklama**: `SeasonalCalendarScreen` üzerinde sezonluk hatırlatıcı ekleme penceresinde hedef sezon dropdown'ı `ListingSeason.values` enum'ını kullanmaktadır. Bu enum'da yalnızca 'Yaz 2025', 'Kış 2025-26' ve 'Tüm Yıl' seçenekleri mevcuttur; içinde bulunduğumuz 2026 yılı sezonları için hatırlatıcı kurulamamaktadır.
- **Test**: `test/qa3/u5_widget_admin_misc/seasonal_calendar_screen_test.dart` -> `supports selecting 2026 seasons in seasonal reminder modal (D23)`
- **Skip Etiketi**: `skip: 'BUG-u5-03: Seasonal calendar does not support 2026 seasons in target season options (D23)'`
- **Öneri**: `ListingSeason` enum'ına 2026 sezonları (`yaz2026`, `kis2026_27`) eklenmeli ve takvim modalı dinamik sezon seçimini desteklemelidir.

---

## 3. Test Edilen Durumlar ve Senaryolar

1. **Yüklenme (Loading) Durumu**: Tüm ekranlarda akış veya gelecek verisi beklenirken `CircularProgressIndicator` görüntülendiği doğrulandı.
2. **Hata (Error) Durumu**: Firestore veya servis bağlantı hatalarında kullanıcı dostu hata mesajı (ör. SnackBar, hata metinleri) gösterildiği doğrulandı.
3. **Boş Liste (Empty State) Durumu**: Hiç kayıt olmadığında uygun açıklayıcı mesaj ve aksiyon butonu gösterildiği test edildi.
4. **CRUD ve Servis Çağrıları**:
   - Şikâyet reddetme, kullanıcı uyarma, askıya alma, yasaklama, ilan kaldırma ve denetim günlüğü kaydı (`logAdminAction`).
   - Kullanıcı yasaklama, yasak kaldırma, 7 günlük askıya alma, askı kaldırma ve kullanıcı arama.
   - İlan kaldırma, geri yükleme, ilan detayına gitme ve ilan arama.
   - Doğrulama onaylama, red sebebiyle reddetme ve belge listesi görüntüleme.
   - Sertifika onaylama, red sebebiyle reddetme.
   - Banner reklam aktif/pasif switch tetikleme, silme, yeni banner oluşturma ve düzenleme modalı.
   - Sezonluk işe alım takviminde bildirim açma/kapatma switch'i, hatırlatıcı silme ve yeni hatırlatıcı ekleme modalı.
5. **Giriş / Doğrulama**: Yasaklama ve red işlemlerinde zorunlu gerekçe doğrulaması (boş giriş engelleme) eksiksiz test edildi.
6. **Oturum Kontrolü**: Sezon takviminde oturumsuz kullanıcının giriş yapmaya yönlendirildiği, oturumlu kullanıcıya ise hatırlatıcı listesi sunulduğu doğrulandı.

# m6_profile_settings — Bulgular ve Kod İnceleme Raporu

**Tarih:** 2026-09-24  
**Kapsam:** Profil, Ayarlar, Dil/RTL, Doğrulama, Referans ve Gizlilik (`lib/features/profile`, `lib/features/referrals`, `lib/shared/services/locale_service.dart`, ilgili l10n ve yönlendirme mantığı)

---

## 1. Kod İncelemesinde Tespit Edilen Hatalar (Bugs)

### BUG-m6-01: İşveren Profilinde Otel Adı ve Doğrulanmış Rozeti Eksik
- **Dosya / Satır:** `lib/features/profile/presentation/profile_screen.dart:293-333`
- **Önem Derecesi:** Yüksek (High)
- **Tekrar Üretme:**
  1. `employer@e2e.test` (Deniz Otel, doğrulanmış işveren) ile giriş yapın.
  2. Hesabım sekmesine gidin.
  3. Profil kartındaki metinleri inceleyin.
- **Beklenen:** `PLAN.md` gereğince işveren profil kartında kullanıcı adının altında çalıştığı otel adı ("Deniz Otel") ve onaylanmış hesap rozeti (doğrulanmış rozet/ikon) gösterilmelidir.
- **Gerçek:** Mobil `ProfileScreen` kartında yalnızca `displayName` ("Mehmet İşveren") ve `email` ("employer@e2e.test") yer almaktadır. `hotelName` ve `isVerified` alanları mobil görünümde hiçbir yerde render edilmemektedir.
- **İlgili Akış:** `.maestro/m6_profile_settings/bugs/bug_employer_profile_missing_hotel_and_badge.yaml`

---

### BUG-m6-02: Kullanıcı Biyografisi (Bio) Mobil Profil Ekranında Gösterilmiyor
- **Dosya / Satır:** `lib/features/profile/presentation/profile_screen.dart:275-372` vs `line 651`
- **Önem Derecesi:** Orta (Medium)
- **Tekrar Üretme:**
  1. `seeker@e2e.test` (seed bio: "Resepsiyon deneyimi 2 yıl") ile giriş yapın.
  2. Hesabım sekmesini açın.
- **Beklenen:** `PLAN.md` gereğince kullanıcının bio bilgisi Hesabım profil özetinde görünmelidir (veya Profili Düzenle'de güncellendiğinde Hesabım'a yansımalıdır).
- **Gerçek:** `profile.bio` metni yalnızca Desktop genişliklerinde (`_buildOverviewDetail` satır 651) render edilmektedir. Mobil `ProfileScreen` kartında bio alanı için hiçbir widget eklenmemiştir.
- **İlgili Akış:** `.maestro/m6_profile_settings/bugs/bug_profile_bio_not_visible_on_account_screen.yaml`

---

### BUG-m6-03: Arapça (RTL) Arayüzde İlan Kartı Maaş Bilgisi Yerelleştirilmemiş (BiDi Bozulması)
- **Dosya / Satır:** `lib/features/home/presentation/widgets/home_screen_widgets.dart:1059`
- **Önem Derecesi:** Orta (Medium)
- **Tekrar Üretme:**
  1. Hesabım -> Uygulama Dili ekranından `العربية` (Arapça) seçin.
  2. Ana sayfaya (`الرئيسية`) dönün ve ilan kartlarındaki maaş etiketlerini inceleyin.
- **Beklenen:** Arapça RTL metin yönünde maaş tutarı ve para birimi yerelleştirilmiş sırada veya BiDi izoleli olarak ("٣٥٬٠٠٠ ليرة" vb.) gösterilmelidir.
- **Gerçek:** Veritabanındaki Türkçe ham metin `listing.salary` ("35.000 TL") doğrudan LTR yönünde basılmakta ve RTL akışta biçimlendirme/hizalama bozulmasına yol açmaktadır (#61).
- **İlgili Akış:** `.maestro/m6_profile_settings/bugs/bug_arabic_rtl_salary_order.yaml`

---

### BUG-m6-04: Dil Değiştirilmesine Rağmen Ana Sayfa Kategori Çiplerinde Hardcoded Türkçe Kalması (#60)
- **Dosya / Satır:** `lib/features/home/presentation/home_screen.dart:402`
- **Önem Derecesi:** Orta (Medium)
- **Tekrar Üretme:**
  1. Uygulama dilini English, Deutsch, Русский veya العربية yapın.
  2. Ana sayfaya dönün ve yatay kategori çiplerini inceleyin.
- **Beklenen:** Çipler `AppLocalizations` üzerinden ilgili dile çevrilmiş kategori adlarını göstermelidir ("Reception", "Rezeption" vb.).
- **Gerçek:** `listingCategoryLabels[category]!` haritası kullanılmakta ve metinler hardcoded Türkçe ("Resepsiyon", "Kat Hizmetleri" vb.) kalmaktadır.

---

### BUG-m6-05: Hesap Silme Onay Kodunun ("SİL") Tüm Dillerde Hardcoded Türkçe Olması
- **Dosya / Satır:** `lib/features/profile/presentation/privacy_settings_screen.dart:136-168`
- **Önem Derecesi:** Düşük (Low)
- **Tekrar Üretme:**
  1. Uygulama dilini İngilizce veya Rusça yapın.
  2. Gizlilik ve Veri Ayarları -> Hesabımı Kalıcı Olarak Sil diyaloğunu açın.
- **Beklenen:** Kullanıcıdan onay için istenen güvenlik kelimesi yerelleştirilmeli (ör. "DELETE") veya ortak bir onay mekanizması sunulmalıdır.
- **Gerçek:** Kullanıcı hangi dili seçerse seçsin diyalog metninde büyük harflerle `SİL` yazılması şart koşulmuştur (`confirmText != 'SİL'`).

---

## 2. UX ve Erişilebilirlik (A11y) Bulguları

1. **Hesabım Menü Alt Başlıkları Hardcoded Türkçe:**
   - `ProfileScreen` içerisindeki tüm alt başlıklar (`subtitle: 'Hijyen, cankurtaran...'`, `subtitle: 'Mesaj, ilan ve duyuru...'`) ARB dosyasına bağlanmamış, hardcoded Türkçe metin olarak yazılmıştır.
2. **"Hemen Başlayabilir" Durum Rozeti Hardcoded:**
   - `profile_screen.dart:323` satırındaki `'Hemen Başlayabilir'` ve `'Müsait Değil'` etiketleri `l10n.availableImmediatelyBadge` / `l10n.notAvailableBadge` yerine doğrudan string literal olarak yazılmıştır.
3. **İşveren Doğrulama Butonu Metni Hardcoded:**
   - `edit_profile_screen.dart:286` üzerindeki `'Otelinizi Doğrulayın'` butonu yerelleştirilmemiştir.
4. **Sessiz Saatler Başlığı Çift Dilli:**
   - `notification_settings_screen.dart:366`'da `'Sessiz Saatler (Quiet Hours)'` şeklinde hem Türkçe hem İngilizce karışık yazılmıştır.
5. **Belge Yükleme Formu Başlıkları:**
   - `certificates_screen.dart:530` üzerinde modal başlığı `'Yeni Belge Yükle'` ve yükleme alanı metinleri hardcoded'dır.

---

## 3. Test Edilemeyen Akışlar ve Gerekçeleri

1. **Gerçek Belge ve Fotoğraf Yükleme:**
   - Profil fotoğrafı (`ProfilePhotoPicker`), sertifika yükleme (`CertificatesScreen._upload`) ve otel doğrulama belgesi yükleme (`VerificationRequestScreen._uploadDocument`) akışları Cloud Storage'a gitmektedir. Canlı ortama yazma yasağı ve emülatörde Storage olmaması sebebiyle formlar açılıp alanları doğrulanmış, dosya seçimi ve yükleme tetiklenmemiştir.
2. **Sistem Paylaşım Diyaloğu ("Paylaş"):**
   - Arkadaşını davet et ekranındaki "Paylaş" butonu ve verilerimi indir akışındaki paylaşım işlemi işletim sistemi düzeyinde Android ShareSheet açmaktadır. Bu diyalog Maestro uygulama kapsamı dışında olduğundan ve kural gereği tetiklenmemiştir (yalnızca "Kodu Kopyala" test edilmiştir).
3. **SMS ile Giriş / Doğrulama:**
   - Telefon ile SMS doğrulama canlı SMS gateway servisine bağlı olduğundan güvenlik kuralları gereği test dışı bırakılmıştır.

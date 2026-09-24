# m7_admin_trust Bulgu ve İnceleme Raporu (FINDINGS)

Bu doküman, Otelcim mobil uygulamasının Admin Paneli, Güven ve Moderasyon, Yetenek Havuzu, Sezonluk Takvim ve Boost modülleri (`lib/features/admin`, `lib/features/talent_pool`, `lib/features/seasonal`, `lib/features/boosts`, `lib/features/auth`) kaynak kodları ve Maestro E2E test senaryoları analizi sonucunda elde edilen bulguları içermektedir.

---

## 1. Tespit Edilen Hatalar (Bugs)

### BUG-m7-01: Admin Rolü İçin Hesabım Ekranında "Yönetim Paneli" Girişi Eksik
- **Dosya & Satır**: `lib/features/profile/presentation/profile_screen.dart:420-496` (ve masaüstü sidebar `profile_screen.dart:140-225`)
- **Önem**: **Kritik**
- **Tekrar Üretme Adımları**:
  1. `admin@e2e.test` (`isAdmin: true`, `adminRole: 'super_admin'`) ile giriş yap.
  2. Alt gezinme çubuğundan "Hesabım" sekmesine dokun.
  3. Menü listesini incele.
- **Beklenen Davranış**: Admin yetkisine sahip kullanıcılar için `profile.isAdmin == true` kontrolüyle "Yönetim Paneli" (veya "Admin Paneli") menü öğesi (`ProfileMenuTile`) görünmeli ve dokunulduğunda `context.push('/admin')` ile admin panosuna geçilmelidir.
- **Gerçek Davranış**: `profile_screen.dart` içerisinde `userType == 'employer'` kontrolü bulunmasına rağmen `isAdmin` kontrolü hiç eklenmemiştir. Mobil arayüzde admin panosuna yönlendiren hiçbir bağlantı yoktur. `AndroidManifest.xml` dosyasında da deep link / intent-filter tanımlı olmadığından `/admin` ve altındaki tüm yönetim ekranları (`/admin/reports`, `/admin/users`, `/admin/listings`, `/admin/verifications`, `/admin/certificates`, `/admin/banners`, `/admin/audit-log`) mobil kullanıcı için tamamen erişilemez durumdadır.
- **İlgili Test**: `.maestro/m7_admin_trust/bugs/bug_admin_missing_from_profile_menu.yaml`

---

### BUG-m7-02: Firestore Güvenlik Kurallarında `talent_pool` Alt Koleksiyon İzni Eksik
- **Dosya & Satır**: `firestore.rules:84-99`
- **Önem**: **Kritik**
- **Tekrar Üretme Adımları**:
  1. `employer@e2e.test` ile giriş yap.
  2. "Mesajlar" sekmesine gidip bir aday ile olan sohbeti aç (`conversations/L1_...`).
  3. Sağ üstteki seçenekler menüsünden "Yetenek Havuzuna Ekle"yi seç ve onay dialogunda "Ekle"ye bas.
- **Beklenen Davranış**: Aday bilgisi `user_profiles/{employerId}/talent_pool/{candidateId}` belgesine yazılmalı ve "Aday yetenek havuzunuza eklendi." bildirimi görünmelidir.
- **Gerçek Davranış**: `firestore.rules` dosyasında `match /user_profiles/{userId}` altında sadece `favorites` ve `seasonal_subscriptions` kuralları tanımlıdır. `talent_pool` kuralı tanımlanmadığı için dosya sonundaki varsayılan `match /{document=**} { allow read, write: if false; }` kuralı devreye girer. İstek Firestore tarafından `permission-denied` ile reddedilir.
- **İlgili Test**: `.maestro/m7_admin_trust/bugs/bug_talent_pool_permission_denied.yaml`

---

### BUG-m7-03: `MyBoostsScreen` Sadece `boost_purchases` Koleksiyonunu Dinliyor; Seed'deki L4 İlanı Listelenmiyor
- **Dosya & Satır**: `lib/features/boosts/presentation/my_boosts_screen.dart:11-13`, `lib/features/boosts/services/boost_service.dart:117-134`, `.maestro/seed/seed.mjs:103`
- **Önem**: **Yüksek**
- **Tekrar Üretme Adımları**:
  1. `employer@e2e.test` ile giriş yap.
  2. "Hesabım" > "Öne Çıkarılan İlanlarım" (`/my-boosts`) ekranına git.
- **Beklenen Davranış**: Seed verisinde `isBoosted: true`, `boostType: 'boost_7_days'` ve `boostExpiresAt: now + 5 days` olarak tanımlanan L4 ("Barmen - Boost") ilanının listede görünmesi ve ~5 gün süresinin kaldığının belirtilmesi.
- **Gerçek Davranış**: `MyBoostsScreen`, veriyi `boost_purchases` koleksiyonundan çeker (`watchUserBoostPurchases`). Ancak `seed.mjs` yalnızca `listings/L4` üzerinde `isBoosted` ve `boostExpiresAt` alanlarını set etmekte, `boost_purchases` koleksiyonuna kayıt atmamaktadır. Ayrıca `firestore.rules:186` uyarınca `boost_purchases` koleksiyonuna istemci tarafı doğrudan yazma izni kapalıdır (`allow write: if false;`). Sonuç olarak ekran "Henüz Öne Çıkarılmış İlanınız Yok" boş durumunu gösterir.
- **İlgili Test**: `.maestro/m7_admin_trust/bugs/bug_my_boosts_missing_l4.yaml`

---

### BUG-m7-04: `MyBoostsScreen` Kalan Gün Süresini Dinamik Hesaplamıyor
- **Dosya & Satır**: `lib/features/boosts/presentation/my_boosts_screen.dart:119,180-186`
- **Önem**: **Orta**
- **Beklenen Davranış**: Boost süresi devam eden bir ilanın kartında "Kalan Süre: 5 gün" gibi dinamik bir süre sayacının yer alması.
- **Gerçek Davranış**: Kart üzerinde yalnızca satın alınan paketin statik adı (`${purchase.durationType} Günlük Paket`) ve bitiş tarihi `dd.MM.yyyy` formatında basılmaktadır; kalan gün sayısı gösterilmemektedir.

---

### BUG-m7-05: `AccountSuspendedScreen` Üzerindeki "Çıkış Yap" Butonu Navigasyon Tetiklemiyor
- **Dosya & Satır**: `lib/features/auth/presentation/account_suspended_screen.dart:69-72`, `lib/app/router.dart:91-110,128-140`
- **Önem**: **Orta**
- **Tekrar Üretme Adımları**:
  1. `suspended@e2e.test` veya `banned@e2e.test` ile giriş yap -> `/account-suspended` ekranına yönlendirilir.
  2. "Çıkış Yap" butonuna tıkla.
- **Beklenen Davranış**: Oturum sonlandırıldıktan sonra kullanıcının `/login` veya `/` rotasına yönlendirilmesi.
- **Gerçek Davranış**: Buton sadece `ref.read(authServiceProvider).signOut()` metodunu çağırmakta, `context.go(...)` navigasyonu çağırmamaktadır. `router.dart` redirect fonksiyonunda `/account-suspended` korumalı rota (`isProtectedRoute`) sayılmadığı için oturum kapandığında otomatik bir yönlendirme gerçekleşmemektedir. Ekran `uid == null` durumuna düşüp başlığı "Hesabınıza erişim kısıtlandı" şeklinde güncelleyerek aynı sayfada kalmaktadır.

---

## 2. UX ve Erişilebilirlik (Accessibility) Bulguları

1. **Erişilebilirlik Etiketi Olmayan Butonlar**:
   - `chat_detail_screen.dart:342`: Sohbet detay ekranındaki sağ üst menü butonu (`PopupMenuButton`) herhangi bir `tooltip` veya `semanticsLabel` içermemektedir.
   - `seasonal_calendar_screen.dart:408`: Sezonluk hatırlatıcı silme ikonu (`Icons.delete_outline`) `tooltip` içermemektedir.
2. **Hardcoded Türkçe ve Yerelleştirme Eksikliği**:
   - `account_suspended_screen.dart:43,49,63,71`: Başlıklar, sebepler ve buton metinleri `AppLocalizations` (`app_tr.arb`) kullanılmadan doğrudan hardcoded yazılmıştır.
   - `admin_dashboard_screen.dart`: Yönetim paneli başlıkları ve açıklamalarının tamamı hardcoded Türkçedir; çok dilli desteğe uyumlu değildir.
   - `user_management_screen.dart` ve `reports_moderation_screen.dart`: Moderasyon dialog metinleri ve hata mesajları hardcoded Türkçedir.

---

## 3. Test Edilemeyen Akışlar ve Nedenleri

1. **Canlı UI Üzerinden Admin Moderasyon Akışları**:
   - `ProfileScreen` içerisinde "Yönetim Paneli" bağlantısı eksik olduğu (BUG-m7-01) ve `AndroidManifest.xml`'de URL scheme intent-filter bulunmadığı için admin kullanıcı panoya UI üzerinden ulaşamamaktadır. Bu nedenle moderasyon akışları (şikayet çözme, kullanıcı yasaklama/askıya alma) `.maestro/m7_admin_trust/bugs/` altında kayıt altına alınmıştır.
2. **Fotoğraf ve Belge Yükleme**:
   - Güvenlik kuralı ("Fotoğraf/dosya yükleme adımı YAZMA") ve Cloud Storage emülatör sınırlamaları nedeniyle sertifika veya banner görseli yükleme adımları çalıştırılmamıştır.
3. **Gerçek Ödeme / Boost Satın Alma**:
   - Güvenlik kuralı ("Satın alma / Satın Al / Ücretsiz boost kullan butonlarına BASMA") gereği IAP ve Cloud Functions callable fonksiyonları tetiklenmemiştir.

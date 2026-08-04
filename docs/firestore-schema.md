# Otelcim Firestore Veritabanı Şema Dokümantasyonu

> **ÖNEMLİ NOT**: Projede yeni bir Firestore koleksiyonu veya alanı eklendiğinde/değiştirildiğinde bu dokümanın ve repo kökündeki `firestore.indexes.json` dosyasının güncellenmesi zorunludur.

---

## Koleksiyonlar ve Yapıları

### 1. `listings` (İlanlar)
* **Açıklama**: İşverenler tarafından yayınlanan otel iş ilanları.
* **Doküman ID**: Otomatik üretilen Firestore ID veya custom ID.
* **Kullanan Servisler**: `ListingService`, `BoostService`, `ModerationService`.
* **Alanlar**:
  - `posterId` (String): İlanı oluşturan işverenin UID'si.
  - `posterName` (String): İlan verenin adı / otel unvanı.
  - `title` (String): İlan başlığı.
  - `description` (String): İlan açıklaması ve detayları.
  - `category` (String): İlan kategorisi (`resepsiyon`, `mutfakMutfakEkip`, `katHizmetleri`, `servisGarson`, `animasyonEglence`, `teknikServis`, `guvenlik`, `spaWellness`, `onBuroYonetim`, `muhasebeFinans`, `diger`).
  - `location` (String): Konum bilgisi ("İl / İlçe").
  - `city` (String?): Şehir adı ("Antalya", "Muğla", "İstanbul" vb.).
  - `salary` (String): Maaş gösterim metni (Örn: "40.000 TL").
  - `minSalaryTl` (int?): Filtreleme için minimum sayısal maaş (TL).
  - `maxSalaryTl` (int?): Filtreleme için maksimum sayısal maaş (TL).
  - `employmentType` (String?): Çalışma türü (`fullTime`, `partTime`, `seasonal`).
  - `contactInfo` (String): İletişim telefon numarası veya e-posta adresi.
  - `status` (String): İlan durumu (`active`, `closed`, `banned`, `flagged`).
  - `isBoosted` (bool): İlanın öne çıkarılıp çıkarılmadığı.
  - `boostExpiresAt` (Timestamp?): Öne çıkarma (boost) bitiş zamanı.
  - `images` (List<String>): İlana ait yüklenmiş fotoğraf URL listesi.
  - `createdAt` (Timestamp): İlanın oluşturulma zamanı.
* **Bileşik İndeksler (`firestore.indexes.json`)**:
  - `status` (ASC) + `createdAt` (DESC)

---

### 2. `user_profiles` (Kullanıcı Profilleri)
* **Açıklama**: İş arayan ve işveren kullanıcıların zengin profil detayları.
* **Doküman ID**: Firebase Auth UID (`user.uid`).
* **Kullanan Servisler**: `ProfileService`, `AuthService`, `ModerationService`, `FavoriteService`.
* **Alanlar**:
  - `email` (String): Kullanıcının e-posta adresi.
  - `displayName` (String?): Ad Soyad.
  - `phoneNumber` (String?): Telefon numarası.
  - `bio` (String?): Hakkında / Özgeçmiş açıklaması.
  - `photoUrl` (String?): Profil fotoğrafı URL'si.
  - `hotelName` (String?): İşverenler için otel / ticari adı.
  - `position` (String?): İşverenler için unvan / pozisyon.
  - `userType` (String): Kullanıcı tipi (`jobseeker`, `employer`).
  - `isAdmin` (bool): Yönetici yetkisi var mı.
  - `adminRole` (String?): Admin rolü (`superAdmin`, `contentModerator`, `supportAgent`).
  - `isVerified` (bool): Mavi tikli onaylı işveren durumu.
  - `verificationStatus` (String?): Doğrulama durumu (`pending`, `approved`, `rejected`).
  - `verifiedAt` (Timestamp?): Doğrulanma tarihi.
  - `createdAt` (Timestamp): Kayıt tarihi.
  - `updatedAt` (Timestamp): Profil güncelleme tarihi.
* **Alt Koleksiyon (Subcollection)**:
  - `user_profiles/{uid}/favorites/{listingId}`:
    - `listingId` (String): Favoriye eklenen ilan ID'si.
    - `addedAt` (Timestamp): Eklenme tarihi.

---

### 3. `conversations` ve `messages` (Sohbetler ve Mesajlar)
* **Açıklama**: İş arayanlar ile işverenler arasındaki mesajlaşma kayıtları.
* **Doküman ID**: `${listingId}_${seekerId}`
* **Kullanan Servisler**: `ChatService`.
* **Alanlar (`conversations`)**:
  - `id` (String): Sohbet ID'si.
  - `listingId` (String): İlgili ilanın ID'si.
  - `listingTitle` (String): İlgili ilanın başlığı.
  - `posterId` (String): İlan sahibi (işveren) UID'si.
  - `seekerId` (String): Başvuran (iş arayan) UID'si.
  - `lastMessage` (String): Son gönderilen mesaj metni.
  - `updatedAt` (Timestamp): Son mesaj gönderilme zamanı.
* **Alt Koleksiyon (`conversations/{id}/messages`)**:
  - `id` (String): Mesaj ID'si.
  - `senderId` (String): Mesajı gönderen kullanıcı UID'si.
  - `text` (String): Mesaj içeriği.
  - `createdAt` (Timestamp): Mesajın gönderildiği zaman.

---

### 4. `verification_requests` (İşveren Doğrulama Talepleri - Kanonik Şema)
* **Açıklama**: İşverenlerin mavi tik (doğrulanmış rozet) almak için gönderdikleri evrak doğrulama başvuruları.
* **Doküman ID**: Otomatik üretilen Firestore ID veya `${userId}_${timestamp}`.
* **Kullanan Servisler**: `shared/VerificationService`, `admin/VerificationService`.
* **Alanlar**:
  - `employerId` (String - Kanonik): Doğrulama isteyen işverenin UID'si.
  - `userId` (String - Geriye dönük uyumluluk aliası): `employerId` ile aynı değer.
  - `userEmail` (String): İşverenin e-posta adresi.
  - `hotelName` (String): Doğrulanmak istenen otel / şirket adı.
  - `hotelAddress` (String): Otelin fiziki adresi.
  - `documentUrls` (List<String>): Yüklenen vergi levhası / turizm işletme belgesi URL'leri.
  - `status` (String): Talep durumu (`pending`, `approved`, `rejected`).
  - `submittedAt` (Timestamp - Kanonik): Başvuru tarihi.
  - `requestedAt` (Timestamp - Geriye dönük uyumluluk aliası): `submittedAt` ile aynı değer.
  - `reviewedBy` (String?): İnceleyen adminin UID'si.
  - `reviewedAt` (Timestamp?): İnceleme / karar tarihi.
  - `rejectionReason` (String?): Reddedilme gerekçesi.
* **Bileşik İndeksler (`firestore.indexes.json`)**:
  - `status` (ASC) + `submittedAt` (DESC)
  - `employerId` (ASC) + `submittedAt` (DESC)

---

### 5. `reports` (İlan ve Kullanıcı Şikayetleri)
* **Açıklama**: Kullanıcılar tarafından bildirilen uygunsuz ilan veya profil şikayetleri.
* **Doküman ID**: Otomatik üretilen Firestore ID.
* **Kullanan Servisler**: `ReportService`, `ModerationService`, `AnalyticsService`.
* **Alanlar**:
  - `reporterId` (String): Şikayeti oluşturan kullanıcının UID'si.
  - `targetId` (String): Şikayet edilen ilanın veya kullanıcının ID'si.
  - `targetType` (String): Hedef tipi (`listing`, `user`).
  - `reason` (String): Şikayet kategorisi / nedeni.
  - `description` (String?): Detaylı açıklama metni.
  - `status` (String): Şikayet durumu (`pending`, `resolved`, `dismissed`).
  - `createdAt` (Timestamp): Şikayet tarihi.
  - `resolvedAt` (Timestamp?): Çözümlenme tarihi.
  - `resolvedBy` (String?): İşlemi yapan admin UID'si.

---

### 6. `boosts` ve `boost_purchases` (İlan Öne Çıkarma İşlemleri)
* **Açıklama**: Satın alınan ilan öne çıkarma paketleri ve işlem geçmişi.
* **Kullanan Servisler**: `BoostService`, `PaymentService`.
* **Alanlar (`boosts`)**:
  - `listingId` (String): Öne çıkarılan ilan ID'si.
  - `userId` (String): İlan sahibi UID'si.
  - `durationType` (String): Süre tipi (`days7`, `days14`, `days30`).
  - `price` (double): Fiyat tutarı (TL).
  - `status` (String): Boost durumu (`active`, `expired`, `cancelled`).
  - `createdAt` (Timestamp): Başlangıç tarihi.
  - `expiresAt` (Timestamp): Bitiş tarihi.
* **Alanlar (`boost_purchases`)**:
  - `listingId` (String): İlan ID'si.
  - `userId` (String): Kullanıcı UID'si.
  - `productId` (String): Ürün ID'si (`boost_7_days`, `boost_14_days`, `boost_30_days`).
  - `price` (double): Satın alma tutarı.
  - `purchasedAt` (Timestamp): Satın alma zamanı.

---

### 7. `banner_ads` (Sponsorlu Anasayfa Reklamları)
* **Açıklama**: Admin tarafından yönetilen sponsorlu harici kampanya banner'ları.
* **Doküman ID**: Otomatik üretilen Firestore ID.
* **Kullanan Servisler**: `BannerAdService`.
* **Alanlar**:
  - `title` (String): Reklam / kampanya başlığı.
  - `advertiserName` (String): Sponsor firma adı (Örn: "Jolly Tur").
  - `imageUrl` (String): Banner görseli URL'si.
  - `targetUrl` (String): Tıklandığında açılacak web sitesi / kampanya URL'si.
  - `order` (int): Carousel gösterim sıralaması.
  - `isActive` (bool): Aktiflik durumu.
  - `startDate` (Timestamp?): Kampanya başlangıç zamanı.
  - `endDate` (Timestamp?): Kampanya bitiş zamanı.
  - `createdAt` (Timestamp): Reklamın eklenme tarihi.

---

### 8. `admin_audit_log` (Yönetici İşlem Günlüğü)
* **Açıklama**: Yönetim panelinde yapılan tüm kritik işlemlerin denetim kaydı.
* **Doküman ID**: Otomatik üretilen Firestore ID.
* **Kullanan Servisler**: `AdminService`.
* **Alanlar**:
  - `adminId` (String): İşlemi gerçekleştiren admin UID'si.
  - `adminEmail` (String): Admin e-postası.
  - `actionType` (String): İşlem türü (`approve_verification`, `reject_verification`, `ban_user`, `delete_listing`, vb.).
  - `targetId` (String): Etkilenen kayıt ID'si.
  - `targetType` (String): Hedef kayıt türü (`verification_request`, `user`, `listing`, `report`).
  - `details` (Map<String, dynamic>): İşleme özel parametreler.
  - `timestamp` (Timestamp): İşlem zamanı.
* **Bileşik İndeksler (`firestore.indexes.json`)**:
  - `adminId` (ASC) + `timestamp` (DESC)
  - `actionType` (ASC) + `timestamp` (DESC)

---

### 9. `ratings` (Otel Değerlendirmeleri ve Puanlar)
* **Açıklama**: İş arayanların çalıştıkları otellere verdikleri puan ve yorumlar.
* **Doküman ID**: Otomatik üretilen Firestore ID.
* **Kullanan Servisler**: `RatingService`.
* **Alanlar**:
  - `employerId` (String): Değerlendirilen otel / işveren UID'si.
  - `reviewerId` (String): Yorumu yapan iş arayan UID'si.
  - `score` (double): Puan (1.0 - 5.0).
  - `comment` (String): Yorum metni.
  - `createdAt` (Timestamp): Yorum tarihi.

---

### 10. `certificates` (İş Arayan Sertifika & Belge Cüzdanı)
* **Açıklama**: İş arayanların hijyen belgesi, cankurtaran sertifikası, ehliyet, dil belgesi gibi belgeleri ve admin onay durumları.
* **Doküman ID**: Otomatik üretilen Firestore ID.
* **Kullanan Servisler**: `CertificateService`.
* **Alanlar**:
  - `userId` (String): Belge sahibi iş arayanın UID'si.
  - `userName` (String?): Kullanıcının adı soyadı.
  - `userEmail` (String?): Kullanıcının e-posta adresi.
  - `type` (String): Belge türü (`hijyen`, `cankurtaran`, `ehliyet`, `dil`, `diger`).
  - `title` (String?): Belge / sertifika başlığı veya açıklaması.
  - `fileUrl` (String): Storage üzerindeki dosya bağlantısı (`certificates/{userId}/{certId}`).
  - `status` (String): Doğrulama durumu (`pending`, `approved`, `rejected`).
  - `createdAt` (Timestamp): Yüklenme tarihi.
  - `reviewedBy` (String?): İnceleyen admin UID'si.
  - `reviewedAt` (Timestamp?): Karar tarihi.
  - `rejectionReason` (String?): Reddedilme gerekçesi.
* **Bileşik İndeksler (`firestore.indexes.json`)**:
  - `userId` (ASC) + `createdAt` (DESC)
  - `status` (ASC) + `createdAt` (DESC)

---

## Composite Index Kuralları (`firestore.indexes.json`)

Firestore üzerinde birden fazla alan içeren karmaşık sorgularda (`where` + `orderBy` veya birden fazla `where` filtresi) dizin hatası (`FirebaseException: The query requires an index`) almamak için ilgili dizin `firestore.indexes.json` dosyasına eklenmelidir.

Mevcut Aktif Dizinler:
1. `listings`: `status` (ASC) + `createdAt` (DESC)
2. `admin_audit_log`: `adminId` (ASC) + `timestamp` (DESC)
3. `admin_audit_log`: `actionType` (ASC) + `timestamp` (DESC)
4. `verification_requests`: `status` (ASC) + `submittedAt` (DESC)
5. `verification_requests`: `employerId` (ASC) + `submittedAt` (DESC)
6. `certificates`: `userId` (ASC) + `createdAt` (DESC)
7. `certificates`: `status` (ASC) + `createdAt` (DESC)

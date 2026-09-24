# m5_chat — Mesajlaşma Modülü Bulguları (FINDINGS)

Bu doküman, otelcim mobil uygulamasının `m5_chat` (mesajlaşma, mülakat teklifi, işe alım ve puanlama) modülünün kaynak kod incelemesi ve E2E test senaryosu tasarımı sırasında tespit edilen yazılımsal bug'ları, UX/erişilebilirlik eksikliklerini ve test edilemeyen akışları listeler.

---

## 1. Tespit Edilen Bug'lar (Yazılım ve Güvenlik Hataları)

### BUG-m5-01: İşveren Sohbet Ekranından Adayı Yetenek Havuzuna Ekleyemiyor (Firestore İzin Hatası)
- **Konum**: `lib/features/chat/presentation/chat_detail_screen.dart:158-229`, `lib/features/talent_pool/services/talent_pool_service.dart:15`, `firestore.rules`
- **Önem**: **Yüksek**
- **Tekrar Üretme Adımları**:
  1. `employer@e2e.test` ile giriş yapın.
  2. Mesajlar sekmesinden bir adayla olan sohbete (ör. L1) girin.
  3. Sağ üstteki menüden "Yetenek Havuzuna Ekle" seçeneğine dokunun.
  4. Açılan diyalogda bir not girin ve "Ekle" butonuna basın.
- **Beklenen Davranış**: Aday işverenin yetenek havuzuna eklenmeli ve "Aday yetenek havuzunuza eklendi." bildirimi görünmelidir.
- **Gerçekleşen Davranış**: `firestore.rules` dosyasında `user_profiles/{userId}/talent_pool` alt koleksiyonu için istemci yazma kuralı bulunmamaktadır. Firestore işlemi `permission-denied` hatasıyla reddeder ve kullanıcıya "İşlem için izniniz yok" / hata uyarısı verilir.
- **Test Akışı**: `.maestro/m5_chat/bugs/bug_talent_pool_permission_denied.yaml`

---

### BUG-m5-02: Puanlama Yapıldıktan Sonra "Deneyimini Değerlendir" Butonu Aktif Kalıyor ve Tekrar Gönderimde StateError Fırlatılıyor
- **Konum**: `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:102-142`, `lib/features/ratings/presentation/submit_rating_screen.dart:33-77`, `lib/features/ratings/services/rating_service.dart:30-36`
- **Önem**: **Orta**
- **Tekrar Üretme Adımları**:
  1. Görüşmeyi "İşe Alındı Olarak İşaretle" ile onaylayın.
  2. Ekranda beliren `ChatHiredBanner` içerisindeki "Deneyimini Değerlendir" butonuna dokunun.
  3. Yıldız puanı ve yorum girip "Değerlendirmeyi Gönder"e basın.
  4. Sohbet ekranına geri dönüldüğünde aynı banner'da "Deneyimini Değerlendir" butonunun hâlâ yer aldığını görün.
  5. Butona tekrar dokunup yeni bir puanlama göndermeyi deneyin.
- **Beklenen Davranış**: Kullanıcı puanlama yaptıktan sonra buton pasifleşmeli veya "Değerlendirildi" şeklinde güncellenmelidir.
- **Gerçekleşen Davranış**: Buton aktif kalır; kullanıcı tekrar gönderdiğinde `RatingService` içindeki `Bu görüşme için zaten değerlendirme yaptınız.` hatası (`StateError`) kullanıcıya SnackBar olarak yansıtılır.
- **Test Akışı**: `.maestro/m5_chat/bugs/bug_duplicate_rating_banner_persists.yaml`

---

### BUG-m5-03: İşe Alım Aksiyonu Rol Kontrolü Olmaksızın Adaya da Gösteriliyor (Yetki / İş Mantığı Tutarsızlığı)
- **Konum**: `lib/features/chat/presentation/chat_detail_screen.dart:377-387`
- **Önem**: **Orta**
- **Tekrar Üretme Adımları**:
  1. `seeker@e2e.test` (iş arayan) ile giriş yapın.
  2. Mesajlar sekmesinden işveren ile olan sohbete girin.
  3. Sağ üstteki açılır menüyü açın.
- **Beklenen Davranış**: "İşe Alındı Olarak İşaretle" aksiyonu bir işveren kararı olduğundan sadece işveren (`isEmployer` veya `posterId == myUid`) için görüntülenmelidir.
- **Gerçekleşen Davranış**: Menü kontrolünde `if (_conversation?.hired != true)` yazıldığı için iş arayan da bu seçeneği görebilmekte ve ilanı tek taraflı olarak işe alındı durumuna geçirebilmektedir.

---

### BUG-m5-04: ChatListScreen İçindeki Oturum Kapalı Durumu Ulaşılamaz Ölü Kod (Dead Code)
- **Konum**: `lib/features/chat/presentation/chat_list_screen.dart:24-59` vs `lib/app/router.dart:100, 124`
- **Önem**: **Düşük / Mimari Tutarsızlık**
- **Tekrar Üretme Adımları**:
  1. Oturum kapalıyken uygulamayı açın.
  2. Alt gezinme çubuğundan "Mesajlar" sekmesine dokunun.
- **Beklenen Davranış**: Ya `ChatListScreen` içinde özenle hazırlanmış "Mesajlaşmak İçin Giriş Yapın" sayfası görünmeli ya da bu kod temizlenmelidir.
- **Gerçekleşen Davranış**: `router.dart` içerisindeki `isProtectedRoute(location)` kuralı `/chat` yolunu doğrudan `/login` sayfasına yönlendirdiği için `ChatListScreen`'in oturum açılmamış durumu asla çizilemez (tamamen dead code kalmıştır).

---

## 2. UX ve Erişilebilirlik Bulguları (Accessibility & Hardcoded Strings)

1. **Gönder Butonunda Tooltip / Semantics Eksikliği**:
   - `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:349`:
     ```dart
     IconButton(
       icon: Icon(Icons.send_rounded, color: Theme.of(context).primaryColor),
       onPressed: onSend,
     )
     ```
     Gönder butonuna `tooltip: 'Gönder'` atanmamıştır. Ekran okuyucu kullanan görme engelli kullanıcılar için buton etiketsiz kalmakta, test otomasyonunda metin eşleştirmesi yapılamamaktadır.

2. **Sohbet Menü Butonunda Özel Tooltip Eksikliği**:
   - `lib/features/chat/presentation/chat_detail_screen.dart:342`:
     `PopupMenuButton` widget'ında `tooltip` parametresi verilmediği için sistem Flutter'ın genel varsayılanı olan "Menüyü göster" değerine düşmektedir.

3. **Hardcoded Türkçe Metinler (Yerelleştirme Eksikliği)**:
   - `ChatListScreen` ve `ChatDetailScreen` içerisinde çok sayıda kullanıcı arayüzü metni doğrudan kaynak kodda statik string olarak tanımlanmıştır:
     - `'Mesajlarım'`
     - `'Henüz Mesajınız Yok'`
     - `'İlan detay sayfasından ilan sahibine mesaj göndererek hemen iletişim başlatabilirsiniz.'`
     - `'İşe alındı olarak işaretle'`
     - `'Bu görüşmede işe alımın gerçekleştiğini onaylıyor musunuz?'`
     - `'Vazgeç'` / `'Onayla'`
     - `'Mesajınızı yazın...'`
     - `'Bu görüşmede işe alım gerçekleşti.'`
     - `'Deneyimini Değerlendir'`
     - `'Yetenek Havuzuna Ekle'`
   - Bu metinler `app_tr.arb` ve l10n sistemine bağlanmadığından, dil İngilizce, Almanca, Rusça veya Arapça yapıldığında Türkçe görünmeye devam edecektir.

---

## 3. Test Edilemeyen Akışlar ve Nedenleri

1. **WhatsApp ile İletişim Başlatma (`_openWhatsApp`)**:
   - `listing_detail_screen.dart:109-140` içerisinde WhatsApp uygulamasına harici `https://wa.me/...` URL çağrısı yapılmaktadır. Emülatörde WhatsApp yüklü olmadığından ve harici sistem uygulamaları E2E kapsamı dışında tutulduğundan bu akış işletim sistemi seviyesinde test edilememiştir.

2. **Mülakat Saati Teklifinde Dinamik Tarih/Saat Seçimi (`showDatePicker` / `showTimePicker`)**:
   - `chat_detail_screen.dart:268-290` içerisinde mülakat teklifi eklenirken açılan takvim ve saat çarkı diyalogları cihaz çözünürlüğü ve içinde bulunulan aya göre değişken olduğundan kırılganlık yaratmaktadır. Bu nedenle mülakat diyalogunun açılması, alanlarının doğrulanması ve iptal/kapatma akışı test edilmiş, iç takvim çarkı manipülasyonu izole edilmiştir.

# Kritik: Firestore Güvenlik Kuralları Sıkılaştırması

## Öncelik: ACİL (Critical) — birden fazla bağımsız denetimde tekrar tekrar bulundu, doğrulandı

## Bulgular ve Kanıt (mevcut `firestore.rules`)

### 1. Kullanıcı kendini admin yapabiliyor
- `firestore.rules:31-33`: `match /user_profiles/{userId} { allow read: if true; allow create, update: if isOwner(userId); ... }` — hiçbir alan kısıtlaması yok.
- `firestore.rules:16`: `isAdmin()` kontrolü aynı `user_profiles/{uid}` dokümanındaki `isAdmin` alanına bakıyor.
- **Sonuç**: Herhangi bir kullanıcı kendi profilini `{isAdmin: true}` ile güncelleyip `/admin` rotasına tam erişim kazanabilir.
- **Fix**: `update` kuralına, `isAdmin`/`adminRole`/varsa `isVerified`/`verificationStatus` gibi yetki alanlarının `request.resource.data` ile `resource.data` arasında DEĞİŞMEDİĞİNİ doğrulayan bir kontrol ekle (`!request.resource.data.diff(resource.data).affectedKeys().hasAny(['isAdmin', 'adminRole'])` deseni). Bu alanlar yalnızca admin tarafından (ayrı bir `isAdmin() ||` dalıyla) veya hiç client'tan değiştirilemesin.

### 2. Tüm giriş yapmış kullanıcılar birbirinin özel mesajlarını okuyabiliyor
- `firestore.rules:56-57`: `match /conversations/{conversationId} { allow read: if isSignedIn(); ... }`
- `firestore.rules:65-66`: `match /messages/{messageId} { allow read: if isSignedIn(); ... }`
- **Fix**: Her ikisini de `resource.data.posterId == request.auth.uid || resource.data.seekerId == request.auth.uid` ile sınırla. `messages` alt koleksiyonunda üst `conversations` dokümanını `get()` ile okuyup aynı kontrolü uygula (create kuralında zaten bu desen kullanılıyor, aynısını read'e de uygula).

### 3. Boost/satın alma kayıtları herkese açık + sahiplik kontrolü hatalı
- `firestore.rules:93-97`: `boosts` — `allow read: if isSignedIn();` (herkes okuyor) VE `allow create, update: if isSignedIn() && request.resource.data.userId == request.auth.uid;` — **update** kuralı `request.resource.data` (yeni yazılan veri) kontrol ediyor, `resource.data` (mevcut dokümanın GERÇEK sahibi) DEĞİL. Yani bir kullanıcı başkasına ait bir `boosts` dokümanını, update sırasında `userId` alanını kendi uid'sine çevirerek ele geçirebilir.
- `firestore.rules:98-102`: `boost_purchases` — aynı şekilde `allow read: if isSignedIn();` herkese açık.
- **Fix**: Her iki koleksiyonda da `read`i `resource.data.userId == request.auth.uid || isAdmin()` ile sınırla. `boosts` update kuralına `resource.data.userId == request.auth.uid` kontrolünü EKLE (request.resource kontrolüne ek olarak, ikisi de sağlanmalı).

### 4. Rating oluşturma yeterince doğrulanmıyor
- `firestore.rules:106-109`: `allow create: if isSignedIn() && request.resource.data.raterId == request.auth.uid;` — puan aralığı (1-5), `ratedUserId != raterId` (kendine oy veremesin) kontrolü yok.
- **Fix (MVP kapsamı)**: En azından `request.resource.data.rating is number && request.resource.data.rating >= 1 && request.resource.data.rating <= 5` ve `request.resource.data.ratedUserId != request.auth.uid` kontrollerini ekle. Görüşmenin gerçekten var olup olmadığını/işe alımla sonuçlanıp sonuçlanmadığını doğrulamak (conversation `get()` ile) MVP kapsamı dışında bırakılabilir, ama kolayca eklenebiliyorsa ekle.

### 5. Eksik koleksiyon kuralları — özellik tamamen çalışmıyor
- `certificates` (top-level, bkz. `lib/features/profile/services/certificate_service.dart:42`) ve `conversations/{id}/interview_slots` (bkz. `lib/shared/services/chat_service.dart:133,156,169`) için **hiçbir rule yok**. Dosyanın sonundaki catch-all (`match /{document=**} { allow read, write: if false; }`) devreye giriyor → `permission-denied`.
- **Fix**: `certificate_service.dart` ve `chat_service.dart`'ı okuyup gerçek okuma/yazma desenini çıkar, uygun scoped rule'lar ekle:
  - `certificates/{certId}`: muhtemelen `userId` alanına sahip, sahibi + admin (moderasyon onayı için) erişebilmeli.
  - `conversations/{conversationId}/interview_slots/{slotId}`: üst konuşmanın katılımcıları (posterId/seekerId) okuyup yazabilmeli.

### 6. Konuşma güncellemesinde alan kısıtlaması yok
- `firestore.rules:61-63`: `allow update: if isSignedIn() && (resource.data.posterId == request.auth.uid || resource.data.seekerId == request.auth.uid);` — katılımcı olan taraf `posterId`/`seekerId` alanlarının KENDİSİNİ de değiştirebiliyor (participant hijack riski).
- **Fix**: `!request.resource.data.diff(resource.data).affectedKeys().hasAny(['posterId', 'seekerId'])` ekle — bu iki alan update'te asla değişemesin.
- **DİKKAT**: `hired` gibi durum alanlarının değişmesi muhtemelen meşru bir uygulama akışı (işe alım işaretleme) — bunu KIRMA, sadece `posterId`/`seekerId`'yi kilitle. Değiştirmeden önce `chat_service.dart`'ta hangi alanların update ile yazıldığını kontrol et.

## Genel Yaklaşım
- Değişiklikleri TEK TEK yap, her birinden sonra mevcut testleri çalıştır (`flutter test`, özellikle `test/services/firestore_services_test.dart`, `test/services/conversation_scoped_query_test.dart`, `test/services/listing_service_filters_test.dart` — `fake_cloud_firestore` paketi gerçek rule'ları simüle ETMEZ, bu yüzden rule değişiklikleri bu testleri kırmaz ama davranış regresyonlarını da yakalamaz; asıl doğrulama Firebase Emulator ile yapılmalı).
- Mümkünse `firebase emulators:start --only firestore` + basit bir manuel/script test ile her kuralı doğrula (emulator kuruluysa). Kurulu değilse en azından kural sözdizimini `firebase deploy --only firestore:rules --dry-run` (varsa) veya dikkatli manuel inceleme ile doğrula.
- **BU SPEC'İ ALAN İŞÇİ**: `firestore.rules` tek dosya, başka hiçbir işçi bu dosyaya dokunmuyor — düşük çakışma riski, ama YÜKSEK etkili bir dosya. Her değişiklikten sonra ilgili Flutter servis dosyasını (chat_service, boost_service, profile_service, rating servisi) tekrar oku ve senin kuralının o servisin GERÇEKTE yaptığı read/write'ları kırmadığından emin ol.

## Acceptance Criteria
- [ ] Kullanıcı kendi `isAdmin`/`adminRole` alanını client'tan değiştiremiyor
- [ ] Konuşma/mesaj okuma sadece katılımcılara açık
- [ ] `boosts`/`boost_purchases` okuma sadece sahibine (+admin) açık
- [ ] `boosts` update'te gerçek sahiplik (`resource.data.userId`) kontrol ediliyor
- [ ] Rating oluşturma en az puan aralığı + kendine oy verememe kontrolü yapıyor
- [ ] `certificates` ve `interview_slots` için scoped rule'lar eklendi, mevcut kod akışları kırılmadı
- [ ] Konuşma update'inde `posterId`/`seekerId` değiştirilemiyor, `hired` gibi diğer alanlar hâlâ değişebiliyor
- [ ] Mevcut `flutter test` suite'i hâlâ yeşil

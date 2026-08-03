# Atlanan testler

- `ProfileService`, paylaşılan `VerificationService` ve `StorageService`, bağımlılıklarını kurucu üzerinden almıyor; doğrudan `FirebaseFirestore.instance` / `FirebaseStorage.instance` kullanıyor. Production kodunu değiştirmeme kuralı nedeniyle gerçek Firebase'e bağlanmadan güvenilir birim test yazılamadı.
- `NotificationService`, platform kanalı kullanan `FlutterLocalNotificationsPlugin` örneğini kendi içinde oluşturuyor. Enjekte edilebilir bir sınır olmadığı için host birim testinde atlandı.
- `StorageService` için `Reference` / `UploadTask` mock'ları servise verilemiyor; servis her çağrıda statik `FirebaseStorage.instance` üzerinden referans üretiyor.
- `PaymentService._onPurchaseUpdate` private olduğu için doğrudan çağrılmadı; davranışı public `purchaseStream`, `verifyPurchase`, `fetchProducts` ve `purchaseProduct` üzerinden test edildi.
- `BannerAd`, `Boost`, `BoostPurchase`, `Listing`, `Conversation`, `Message`, `Report`, admin `AdminAction` ve admin `VerificationRequest` modellerinde production tarafında `==`/`hashCode` veya `copyWith` bulunmuyor. Var olmayan API'ler için production koduna dokunmadan test yazılamaz; mevcut constructor ve serileştirme davranışları test edildi.
- `AppUser` modelinde `copyWith`, `==` ve `hashCode`; `OnboardingSlideData` modelinde serileştirme ve `copyWith` API'si bulunmuyor. Mevcut public davranışlar test edildi.

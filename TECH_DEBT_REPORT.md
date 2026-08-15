# Kod Kalitesi ve Teknik Borç Analizi

Tarih: 2026-08-15

## Yönetici özeti

Kod tabanının genel katman ayrımı anlaşılır ve test altyapısı mevcut; ancak ödeme/boost güven sınırı kritik seviyede zayıf. İlk iş olarak boost yetkilendirmesi ve Firebase kuralları düzeltilmeli. Ardından büyük ekran dosyaları parçalanmalı, hata yönetimi standartlaştırılmalı ve Firebase kuralları emülatör testleriyle güvence altına alınmalı.

## Önceliklendirilmiş bulgular

### P0 — Satın alma doğrulaması yapılmadan ücretli boost veriliyor

- Kanıt: `functions/src/index.ts:313-420`
- Callable function yalnızca oturum, ürün kimliği, ilan sahipliği ve daha önce kullanılmamış bir `transactionId` kontrol ediyor.
- İstemciden gelen `purchaseToken`, `verificationData` ve `platform` verileri doğrulanmadan kaydediliyor (`functions/src/index.ts:358`, `functions/src/index.ts:389-390`).
- Kullanıcı benzersiz bir sahte işlem kimliği göndererek ücret ödemeden aktif boost oluşturabilir.

Öneri: Google Play Developer API / App Store Server API ile sunucu tarafı doğrulama yapın; doğrulanmış ürün, kullanıcı, paket kimliği, işlem durumu ve tüketim bilgisini eşleştirin. İşlem kimliğini belge kimliği veya transaction içinde benzersiz/idempotent anahtar yapın. App Check zorunluluğu ve kötüye kullanım hız sınırı ekleyin.

### P0 — Firestore kuralları ücretli alanların istemciden değiştirilmesine izin veriyor

- Kanıt: `firestore.rules:27-31`
- İlan sahibi, kendi ilanında tüm alanları güncelleyebiliyor. `isBoosted`, `boostExpiresAt`, `boostType`, `boostPurchaseId`, `posterId` gibi sunucu kontrollü olması gereken alanlar korunmuyor.
- Sonuç: ödeme fonksiyonu atlanarak boost durumu doğrudan yazılabilir; kayıt sahipliği ve diğer güvenilir alanlar değiştirilebilir.

Öneri: İstemci güncellemelerinde değiştirilebilir alanları allowlist ile sınırlandırın. Boost ve sahiplik alanlarının değişmesini yalnızca Admin SDK'ya bırakın.

### P0 — “Referral reward” yolu sınırsız ücretsiz boost üretmeye açık

- Kanıt: `firestore.rules:126-140`
- İmzalı kullanıcı, `platform == 'referral_reward'` ve `price == 0` koşullarıyla doğrudan sınırsız `boosts` ve `boost_purchases` belgesi oluşturabilir/güncelleyebilir.
- Kural kredi bakiyesi, ilan sahipliği, süre, durum, ürün veya tek kullanımlık tüketimi doğrulamıyor.

Öneri: Bu istemci yazma yolunu kapatın. Krediyi yalnızca transaction kullanan bir callable function içinde atomik olarak tüketin ve boost'u Admin SDK ile oluşturun.

### P1 — Storage ilan görsellerinde nesne sahipliği yok

- Kanıt: `storage.rules:34-49`
- Her giriş yapmış kullanıcı, bildiği herhangi bir `listingId/fileName` yoluna yazabilir veya mevcut nesneyi silebilir/ezebilir.

Öneri: Yolu kullanıcı kimliğiyle namespace edin (`listing_images/{uid}/{listingId}/...`) ve `uid` sahipliğini kuralda doğrulayın. Alternatif olarak önce taslak ilan belgesi oluşturup Storage kuralında Firestore sahipliğini kontrol edin. Create/update/delete izinlerini ayrı tanımlayın.

### P1 — Mesaj bütünlüğü kurallarla korunmuyor

- Kanıt: `firestore.rules:85-93`
- Katılımcı olmak mesaj oluşturmaya yetiyor; `senderId`, zaman damgası ve izin verilen alanlar doğrulanmıyor. Katılımcı diğer kullanıcı adına mesaj yazabilir.

Öneri: `request.resource.data.senderId == request.auth.uid` şartı, alan allowlist'i, tip/boyut kontrolleri ve değiştirilemez sunucu zaman stratejisi ekleyin.

### P1 — Kritik kurallar için otomatik test/CI kapısı görünmüyor

- Firestore ve Storage kuralları için emülatör tabanlı test dosyası bulunamadı.
- `.github/workflows` bulunamadı; analiz ve testlerin merge öncesinde zorunlu çalıştığına dair repo içi kanıt yok.

Öneri: `@firebase/rules-unit-testing` ile pozitif/negatif yetki testleri yazın. CI'da Flutter analiz/test, TypeScript build ve rules testlerini zorunlu hale getirin.

### P2 — God widget / yüksek değişiklik maliyeti

En büyük elle yazılmış ekranlar:

- `lib/features/home/presentation/home_screen.dart`: 1643 satır
- `lib/features/listings/presentation/listing_detail_screen.dart`: 1343 satır
- `lib/features/profile/presentation/profile_screen.dart`: 987 satır
- `lib/features/listings/presentation/edit_listing_screen.dart`: 943 satır
- `lib/features/listings/presentation/create_listing_screen.dart`: 845 satır
- `lib/features/chat/presentation/chat_detail_screen.dart`: 673 satır

Bu dosyalar görünüm, durum, veri erişimi ve eylem akışlarını aynı yerde toplama eğiliminde; inceleme ve regresyon riskini artırıyor.

Öneri: Önce create/edit listing ortak form modelini ve alan widget'larını çıkarın. Ardından home ve detail ekranlarını bölüm widget'ları + Riverpod controller/use-case sınırlarına ayırın. Satır sayısını tek hedef yapmayın; bağımsız değişim nedenlerini ayırın.

### P2 — Hata yönetimi parçalı ve bazı hatalar sessizce yutuluyor

- Tarama, `lib` altında çok sayıda geniş `catch (e)` ve en az 15 adet `catch (_)` örneği gösterdi.
- Örnekler: `lib/features/admin/presentation/listing_management_screen.dart:205`, `lib/features/chat/presentation/chat_detail_screen.dart:102`, `lib/features/home/presentation/home_screen.dart:754`.

Öneri: Firebase/HTTP/storage hatalarını typed failure modeline çeviren ortak sınır oluşturun. Kullanıcı mesajı, telemetry/log ve retry davranışını merkezi belirleyin; gerçekten beklenen durumlar dışında boş `catch` kullanmayın.

### P2 — Statik analiz politikası minimum düzeyde

- `analysis_options.yaml` yalnızca varsayılan `flutter_lints` paketini içeriyor; projeye özgü katı kurallar ve borç bütçesi yok.

Öneri: `strict-casts`, `strict-inference`, `strict-raw-types` seçeneklerini kademeli etkinleştirin; `unawaited_futures`, `discarded_futures`, `avoid_dynamic_calls` gibi kuralları değerlendirin. Mevcut ihlalleri baseline/backlog ile aşamalı azaltın.

## Uygulama sırası

1. Boost istemci yazmalarını kapatın ve ilan güncelleme allowlist'i ekleyin.
2. Satın alma makbuzunu gerçek mağaza API'leriyle doğrulayın; idempotency ve App Check ekleyin.
3. Storage sahipliği ile mesaj bütünlüğü kurallarını düzeltin.
4. Tüm güvenlik kuralları için emülatör testleri ve CI kapısı ekleyin.
5. Create/edit listing ortak formunu çıkarın; ardından home/detail/profile ekranlarını parçalayın.
6. Ortak hata modeli ve daha katı analiz politikasını kademeli uygulayın.

## Doğrulama notları

- `functions` altında `npm run build` başarılı oldu.
- Çalışma ortamında `flutter` komutu PATH üzerinde bulunmadığından `flutter analyze` ve `flutter test` çalıştırılamadı. Bu nedenle Dart tarafındaki derleme/test sağlığı hakkında “başarılı” sonucu verilmemiştir.
- İnceleme statik ve repo kapsamındadır; canlı Firebase yapılandırmasının bu dosyalarla deploy eşleşmesi ayrıca doğrulanmalıdır.

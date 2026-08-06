# Quick Spec: Dead Code & Lint Cleanup

## Task
`flutter analyze` çıktısındaki gerçek "dead code" ve unused-import/element bulgularını temizle. Sadece aşağıdaki somut listeye odaklan — kapsamı `deprecated_member_use` (withOpacity, activeColor vb.) veya stil önerilerine (`unnecessary_underscores`, `curly_braces_in_flow_control_structures`) genişletme, onlar ayrı bir iştir.

## Bulgular (flutter analyze, 2026-08-06 itibarıyla)

### Gerçek dead code (öncelikli)
- `lib/features/profile/presentation/edit_profile_screen.dart:71` — `dead_code` + `dead_null_aware_expression`: sol operand null olamayacağından sağ taraf hiç çalışmıyor. Mantığı incele, gereksiz null-aware ifadeyi kaldır.
- `lib/features/profile/presentation/certificates_screen.dart:249` — `unreachable_switch_default`: switch zaten tüm case'leri kapsıyor, `default` dalı hiç tetiklenmiyor. Kaldır veya eksik bir case olup olmadığını doğrula.

### Kullanılmayan import/field/element
- `lib/shared/providers/profile_provider.dart:6` — unused import `../services/storage_service.dart`
- `lib/features/profile/presentation/verification_request_screen.dart:10` — unnecessary import (zaten `profile_provider.dart` üzerinden geliyor)
- `lib/shared/services/payment_service.dart:17` — `_purchases` field `final` olabilir
- `lib/features/profile/services/certificate_service.dart:36` — initializing formal kullanılabilir (`this._storageService`)
- `test/features/home/home_screen_test.dart:6` — unused import `favorite_service.dart`
- `test/features/home/home_screen_test.dart:28` — kullanılmayan `_listingService` + geçersiz `@override` (bu bir gerçek hataya işaret ediyor olabilir, kontrol et)
- `test/services/certificate_service_test.dart:1` — unused import `dart:io`
- `test/services/conversation_scoped_query_test.dart:3` — unused import `conversation.dart`
- `test/services/listing_service_filters_test.dart:4` — unused import `listing_model.dart`
- `test/shared/desktop_top_nav_bar_test.dart:6` — unused import `desktop_top_nav_bar.dart`
- `lib/shared/providers/profile_provider.dart:6` — unused import (yukarıda tekrar, tek seferde düzelt)

### İncelemesi gereken (opsiyonel, süre kalırsa)
- `test/shared/providers/paginated_listings_provider_test.dart:11` — sealed `DocumentSnapshot` class'ını extend/implement ediyor, gelecekte Firebase SDK güncellemesinde kırılabilir. Composition'a çevrilebilir mi bak (zorunlu değil, sadece not).

## Verification
- [ ] `flutter analyze` bu listede sayılan tüm satırlarda artık uyarı vermiyor
- [ ] `flutter analyze` toplam issue sayısı listede değinilmeyen (deprecated_member_use, style) kalemler dışında düşmüş
- [ ] `flutter test` yeşil (özellikle dokunduğun dosyaların testleri)
- [ ] Kaldırdığın hiçbir kod gerçekten kullanılan bir şeyi kırmıyor — her silme öncesi grep ile referans kontrolü yap

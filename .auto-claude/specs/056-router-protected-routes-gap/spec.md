# Router: Korumalı Rota Boşlukları

## Öncelik: Orta

## Bulgu
`lib/app/router.dart`'taki `isProtected` kontrolü (satır ~60-70) şu rotaları KAPSAMIYOR, yani giriş yapmamış/anonim kullanıcı bu URL'lere doğrudan gidebiliyor:

- `/listing/:id/edit` (sadece sahibi düzenleyebilmeli)
- `/listing/:id/qr-poster`
- `/onboarding/role` (mevcut kontrol `location == '/onboarding'` — TAM eşleşme, `startsWith` değil, bu yüzden `/onboarding/role` alt rotası kapsanmıyor)
- `/seasonal-calendar` (varsa — router.dart'ta bu rotanın gerçekten var olup olmadığını kontrol et, yoksa bu maddeyi atla)

Firestore kuralları bazı yazma işlemlerini engellese de, ekranın kendisi anonim kullanıcıya açılıp bozuk/boş bir arayüz veya gereksiz sorgu göstermesine neden oluyor — kullanıcı deneyimi ve savunma katmanı eksikliği.

## Fix
`isProtected` ifadesine ekle:
```dart
location.endsWith('/edit') ||
location.endsWith('/qr-poster') ||
location.startsWith('/onboarding') ||  // '==' yerine startsWith, '/onboarding/role'u da kapsasın
```
`/seasonal-calendar` router.dart'ta gerçekten tanımlıysa aynı şekilde ekle.

**Dikkat**: `location.endsWith('/edit')` gibi geniş bir eşleşme kullanırken, uygulamada başka (yanlışlıkla korunmasını istemediğin) bir `/edit` ile biten rota olmadığından emin ol — router.dart'taki tüm route path'lerini gözden geçir.

## Dosya Çakışma Uyarısı
Sadece `router.dart`. Not: spec 040 (referans sistemi, PR #31) bu dosyaya `/profile/invite` route'u eklemişti — eğer o PR merge olmadan bu görev başlarsa, merge/rebase sırasında küçük bir context farkı olabilir, ciddi çakışma beklenmiyor (farklı satırlara dokunuluyor).

## Acceptance Criteria
- [ ] Anonim kullanıcı `/listing/123/edit`'e gittiğinde `/login`'e yönlendiriliyor
- [ ] Anonim kullanıcı `/listing/123/qr-poster`'a gittiğinde `/login`'e yönlendiriliyor
- [ ] Anonim kullanıcı `/onboarding/role`'a gittiğinde `/login`'e yönlendiriliyor
- [ ] Giriş yapmış kullanıcı için bu rotalarda regresyon yok (hâlâ normal açılıyor)
- [ ] `flutter analyze` temiz, `flutter test` geçiyor

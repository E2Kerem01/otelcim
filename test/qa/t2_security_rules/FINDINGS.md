# t2 FINDINGS — firestore.rules / storage.rules + client↔rules contract

Bütün bulgular Firestore/Storage emülatöründe gerçek kurallarla doğrulandı
(`node run.mjs --bugs` → 53 bug testinin hepsi FAIL). Ayrıntılı açıklama,
tekrar üretme adımları ve önerilen düzeltmeler: `otelcim_qa/shared/reports/t2.md`.

| ID | Şiddet | Konum | Bulgu | Repro testi |
|---|---|---|---|---|
| BUG-t2-01 | kritik | firestore.rules:28-31, 88-89 | Banlı/askıdaki kullanıcı kendi `isBanned`, `isSuspended`, `suspensionEnd`, `warnings` alanlarını silebiliyor | user_profiles.spec.ts › "a moderated user cannot rewrite …" |
| BUG-t2-02 | yüksek | firestore.rules:28-31 | Herkes kendine `isVerified/verificationStatus/verifiedAt` yazıp doğrulanmış rozet alıyor | user_profiles.spec.ts › "… verified badge via …" |
| BUG-t2-03 | kritik | firestore.rules:86-87 | Profil create sadece `isAdmin`'e bakıyor: `freeBoostCredits:999`, `referralCount`, `referralRewardGranted`, `isVerified` vb. yazılabiliyor | user_profiles.spec.ts › "a new profile cannot be created with …" |
| BUG-t2-04 | yüksek | firestore.rules:86-90 | Profil sil + yeniden oluştur → ücretsiz acil hakkı, referral bayrağı ve **ban** sıfırlanıyor | user_profiles.spec.ts › "deleting and re-creating …" |
| BUG-t2-05 | orta | firestore.rules:28-31 | `referredBy` sonradan (kendine dahi) yazılabiliyor → referral ödülü suistimali (t1 ile bağlantılı) | user_profiles.spec.ts › "referredBy cannot be rewritten …" |
| BUG-t2-06 | yüksek | firestore.rules:85 | `user_profiles` anonim okunabiliyor; `email`, `phoneNumber`, `fcmToken` açık (KVKK) | user_profiles.spec.ts › "an anonymous caller cannot read …" |
| BUG-t2-07 | orta | notification_service.dart:111-119, main.dart:69-72 | `clearFcmToken` signOut **sonrası** (anonim) ya da yeni kullanıcı adına çalışıyor → red → eski hesap aynı cihaza push almaya devam ediyor | user_profiles.spec.ts › FCM token lifecycle |
| BUG-t2-08 | kritik | firestore.rules:84-99 (kural yok) | `user_profiles/{uid}/talent_pool` için kural yok → Yetenek Havuzu prod'da tamamen çalışmıyor | user_profiles.spec.ts › "talent_pool: the employer can …" |
| BUG-t2-09 | kritik | firestore.rules:63-64 | İlan create'te `isBoosted:true, boostExpiresAt:2099`, `boostPurchaseId`, `urgentListingPurchaseId` yazılabiliyor → ödemesiz boost | listings.spec.ts › "a listing cannot be born boosted" |
| BUG-t2-10 | yüksek | firestore.rules:44-47, 63-64 | `posterVerified` create ve update'te serbest → sahte "doğrulanmış işveren" rozeti | listings.spec.ts › posterVerified testleri |
| BUG-t2-11 | düşük | firestore.rules:44-47, 63-64 | `viewCount/messageCount` create/update'te serbest | listings.spec.ts › counter testleri |
| BUG-t2-12 | yüksek | edit_listing_screen.dart:183-223 ↔ firestore.rules:46 | Düzenleme ekranı `isUrgent`'i göndermiyor → acil ilan hiç düzenlenemiyor (permission-denied); `lat/lng` null'a eziliyor (t4) | listings.spec.ts › EditListingScreen contract |
| BUG-t2-13 | yüksek | listing_service.dart:220-232 ↔ firestore.rules:76-78 | `createBatchListings` (Toplu İlan) prod'da her zaman başarısız: contact kuralı `get()` batch içinde henüz olmayan ilanı göremiyor | listings.spec.ts › "one batch with N listings …" |
| BUG-t2-14 | orta | firestore.rules:74-79, listing_service / auth_service | İlan silinince `private/contact` (telefon/e-posta) kalıyor, giriş yapmış herkes okuyabiliyor, sahibi artık silemiyor | listings.spec.ts › "deleting a listing does not leave …" |
| BUG-t2-15 | düşük | firestore.rules:62 | Göç öncesi ilanlarda üst seviye `contactInfo` anonim okunuyor (ilan düzenlenene kadar) | listings.spec.ts › legacy contactInfo |
| BUG-t2-16 | yüksek | firestore.rules:119-121 | Konuşma create `posterId`'yi ilan sahibine, `seekerId`'yi çağırana, id'yi `listingId_seekerId`'ye bağlamıyor → başkası adına/rastgele kullanıcıya konuşma (spam + referral farming) | chat.spec.ts › BUG-t2-16 testleri |
| BUG-t2-17 | orta | firestore.rules:122-126 | Konuşma update'i sadece `posterId/seekerId`'yi koruyor: `lastMessage` sınırsız/sahte, `lastSenderId` sahte, `listingId` değişiyor, **iş arayan kendini `hired:true` yapabiliyor** (puanlama kapısı) | chat.spec.ts › preview + hired testleri |
| BUG-t2-18 | düşük | firestore.rules:150-154 | interview_slots'ta alan kontrolü yok: öneren kendi önerisini onaylıyor, önerilmemiş saat seçilebiliyor, `proposedBy` sahte | chat.spec.ts › interview_slots |
| BUG-t2-19 | orta | report_service.dart:39-55 ↔ firestore.rules:162 | `hasAlreadyReported` sorgusu reddediliyor, hata yutuluyor → hep `false`, mükerrer şikâyet engeli yok | trust_and_payments.spec.ts › hasAlreadyReported |
| BUG-t2-20 | orta | firestore.rules:167-168 | Doğrulama başvurusu `status:'approved'` ile oluşturulabiliyor | trust_and_payments.spec.ts › "… already approved" |
| BUG-t2-21 | yüksek | verification_service.dart:71-79 ↔ firestore.rules:169-170 | Başvurusu olmayan her işverende legacy `userId` sorgusu permission-denied → ekrana hata | trust_and_payments.spec.ts › "… with no request returns empty" |
| BUG-t2-22 | yüksek | firestore.rules:205-213, rating_model.dart:14 | Puan create konuşmaya/işe alıma bağlı değil, doc id serbest → yabancılar sınırsız puan verebilir; `moderationStatus:'approved'` istemciden (model varsayılanı da approved) | trust_and_payments.spec.ts › ratings; client_payload_contract_test.dart |
| BUG-t2-23 | düşük | firestore.rules:210 | `stars` için `is number` → 3.5 kabul, model int, `fromDoc` sessizce 3'e kesiyor | trust_and_payments.spec.ts › fractional stars |
| BUG-t2-24 | orta | firestore.rules:221-222 | Sertifika `status:'approved'` ile oluşturulabiliyor | trust_and_payments.spec.ts › "a certificate cannot be created already approved" |
| BUG-t2-25 | yüksek | storage.rules:31,43,49,56,62,75 | `allow write` içinde `request.resource` silmede null → profil fotoğrafı, ilan/lojman görseli, doğrulama belgesi, sertifika, banner **silinemiyor** | storage.spec.ts › "the owner can delete a …" |
| BUG-t2-26 | orta | storage.rules:68 | `user_videos` (herkese açık) içerik tipi kontrolü yok → `text/html` vb. barındırılabiliyor | storage.spec.ts › intro videos |
| BUG-t2-27 | yüksek | auth_service.dart:210-296 ↔ firestore.rules | `deleteAccount` zincirinin çoğu reddediliyor ve hata yutuluyor; birçok koleksiyon hiç denenmiyor (tablo aşağıda) — KVKK unutulma hakkı | delete_account.spec.ts |

## deleteAccount sözleşme tablosu (Alice olarak, uygulamadaki sırayla)

| Adım | İstemci işlemi | Sonuç |
|---|---|---|
| 1 | `user_profiles/{uid}` delete | ✅ izin |
| 2 | `listings where posterId==uid` + delete | ✅ izin (ama `private/contact` alt dokümanı kalıyor → BUG-t2-14) |
| 3 | `reports where reporterId==uid` | ❌ sorgu reddedildi (okuma sadece admin), delete kuralı da yok |
| 4 | `boosts` / `boost_purchases where userId==uid` + delete | sorgu ✅, delete ❌ (`allow write: if false`) |
| 5 | `verification_requests where employerId==uid` + delete | sorgu ✅, delete ❌ (delete kuralı yok) |
| 6 | `conversations where posterId/seekerId==uid`, `messages` + delete | sorgu ✅, mesaj/konuşma delete ❌ (kural yok) |
| — | favorites, seasonal_subscriptions (iç içe + düz), talent_pool, certificates, ratings, interview_slots, Storage dosyaları | ⚠️ hiç denenmiyor |

Kaskattan sonra kalan dokümanlar (delete_account.spec.ts, `--bugs` çıktısı):
`listings/…/private/contact`, `reports/r1`, `boosts/b1`, `boost_purchases/p1`,
`verification_requests/v1`, iki konuşma + mesajları + interview_slots,
`favorites`, iki `seasonal_subscriptions`, `talent_pool`, `certificates/c1`, `ratings/…`.

## Kural tarafından doğrulanan (bug olmayan) sözleşmeler — özet

- Mesaj kuralı sağlam: `senderId==auth`, 1..5000 karakter, sadece 3 alan, `sentAt==request.time`; mesajlar değiştirilemez.
- Boost/purchase koleksiyonlarına istemci yazması tamamen kapalı; sahibi ve admin okur; `userId==me` sorgusu çalışır.
- İlan update'inde boost/urgent/posterId alanları korunuyor; `removed` ilanı sahibi geri açamıyor.
- Profil update'inde `isAdmin`, `freeBoostCredits`, `referralCount`, `referralRewardGranted`, `hasUsedFreeUrgentListing` korunuyor.
- Storage: yükleme yolları uid'e bağlı, 10 MB / 15 MB sınırları doğru, doğrulama belgeleri sadece sahibi+admin.

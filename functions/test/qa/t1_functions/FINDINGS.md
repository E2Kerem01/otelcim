# t1 — Cloud Functions (`functions/src/index.ts`) bulguları

Çalıştırma (npm install gerekmez, Node >= 22.18; test edilen: v24.18.0):

```
node --test "functions/test/qa/t1_functions/*.test.mjs"                       # suite (BUG testleri skip)
node --env-file=functions/test/qa/t1_functions/run-bugs.env --test \
     --test-name-pattern=BUG "functions/test/qa/t1_functions/*.test.mjs"      # BUG testlerini açar → hepsi FAIL
```

`harness.mjs`, `firebase-admin/*`, `firebase-functions/*` ve `jsonwebtoken` modüllerini
`module.registerHooks` ile `fakes/runtime.mjs`'e yönlendiriyor; `fetch` global olarak sahteleniyor.
Sahte Firestore her okuma/yazmada event loop'a dönüyor (eşzamanlılık gerçekten iç içe geçiyor) ve
`runTransaction`'ı serileştiriyor (gerçek Firestore'un serializable garantisi).

Tüm BUG testleri doğru davranışı assert eder; `RUN_BUGS=1` ile açıldığında 23'ünün hepsi FAIL eder (doğrulandı).

| ID | Şiddet | Yer | Bulgu | Repro testi |
|---|---|---|---|---|
| BUG-t1-01 | yüksek | index.ts:577-645 (aynı kalıp urgent: 718-761) | Replay kontrolü (query) ile yazma (batch) transaction dışında; aynı token ile eşzamanlı iki çağrı iki boost üretir (farklı `listingId` ile → tek ödemeyle iki ilan). | boost_purchase › BUG-t1-01 |
| BUG-t1-02 | yüksek | index.ts:610, 829 ↔ lib/features/boosts/domain/boost_model.dart:39-49 | `boosts.durationType` = `days14`/`days30`; Dart `'14'`/`'30'` bekliyor → her boost 7 günlük görünür. | boost_purchase › BUG-t1-02, redeem_free_boost › BUG-t1-02 |
| BUG-t1-03 | yüksek | index.ts:598-599, 637-643; 803-804, 854-860 | Uzatma `now + süre` ile eziyor; 25 günü kalan boost'a 7 günlük alım süreyi kısaltır (ücretli ve ücretsiz). | boost_purchase › BUG-t1-03, redeem_free_boost › BUG-t1-03 |
| BUG-t1-04 | yüksek | index.ts:235-248 ↔ 963-1000 | Bölge push'u reconcile'dan bağımsız; ücretsiz hakkı bitmiş kullanıcının acil ilanı downgrade edilse de bölgeye push gider (spam). | urgent_notifications › BUG-t1-04 |
| BUG-t1-05 | orta | index.ts:895-897 | `referredBy === refereeId` kontrolü yok → kendine ücretsiz boost (kural tarafı: t2, `referredBy` istemci yazılabilir). | referral_reward › BUG-t1-05 |
| BUG-t1-06 | orta | index.ts:521-529 | Apple makbuzunda ilk eşleşen işlem alınıyor; eski (işlenmiş) işlem öndeyse yeni ödeme `already-exists` → para alınır, boost verilmez. | boost_purchase › BUG-t1-06 |
| BUG-t1-07 | düşük | index.ts:471-480 | `callAppleVerifyReceipt` `response.ok` kontrol etmiyor; Apple HTML 503 → ham SyntaxError → istemciye anlamsız `internal`. | boost_purchase › BUG-t1-07 |
| BUG-t1-08 | düşük | index.ts:549 | `BOOST_PRODUCTS[productId]` prototip anahtarlarını (`constructor`) kabul ediyor; mağazaya kadar gidiyor. | boost_purchase › BUG-t1-08 |
| BUG-t1-09 | orta | index.ts:891-918 | Referral ödülü transaction'sız; ilan + sohbet tetikleyicisi eşzamanlı → çift ödül. | referral_reward › BUG-t1-09 |
| BUG-t1-10 | orta | index.ts:911-918 | Ödül ve bayrak iki ayrı `update`; bayrak yazımı patlarsa sonraki eylem tekrar ödüllendirir. | referral_reward › BUG-t1-10 |
| BUG-t1-11 | yüksek | index.ts:78 | Gönderen adı yoksa **e-posta adresi** karşı tarafa bildirim başlığı olarak gidiyor (KVKK/PII). | chat_notification › BUG-t1-11 |
| BUG-t1-12 | orta | index.ts (hiçbir fonksiyon) | `quietHoursStart/End` hiçbir bildirimde dikkate alınmıyor. | chat_notification › BUG-t1-12 |
| BUG-t1-13 | orta | index.ts:297-334 | Mülakat bildirimi: tek try içinde döngü; ilk katılımcıya `send` hata verirse (eski token) ikincisine gitmiyor. | interview_notification › BUG-t1-13 |
| BUG-t1-14 | düşük | index.ts:297-303 | Mülakat bildirimi `notificationPreferences.messages`'ı okumuyor. | interview_notification › BUG-t1-14 |
| BUG-t1-15 | orta | index.ts:155-162 ↔ lib/features/seasonal/services/seasonal_service.dart:103,112 | Bildirimde ham sezon kodu (`yaz_2025 için …`) görünüyor; üstelik geçmiş sezon. | seasonal_reminders › BUG-t1-15 |
| BUG-t1-16 | düşük | index.ts:173 ↔ lib/shared/services/notification_service.dart:58-79 | `channelId: 'reminders'` istemcide oluşturulmuyor (yalnızca `messages`, `urgent_listings`). | seasonal_reminders › BUG-t1-16 |
| BUG-t1-17 | düşük | index.ts:79 | 120+ karakter önizleme UTF-16 surrogate çiftini bölüyor (emoji → �). | chat_notification › BUG-t1-17 |
| BUG-t1-18 | düşük | index.ts:52 | `posterId === seekerId` konuşmada gönderen kendi mesajının push'unu alıyor. | chat_notification › BUG-t1-18 |
| BUG-t1-19 | orta | index.ts:144 ↔ lib/shared/models/user_profile.dart:15 | Dart varsayılanı `seasonalReminders:false`; açıkça abone olan yeni kullanıcı hatırlatma alamıyor. | seasonal_reminders › BUG-t1-19 |
| BUG-t1-20 | düşük | index.ts:203-210 | Yalnızca boşluktan oluşan bölge → `region_` konusuna push. | urgent_notifications › BUG-t1-20 |
| BUG-t1-21 | düşük | index.ts:209 ↔ notification_service.dart:14-19 | `"İzmir"` → JS `region_i_zmir`, Dart `region_izmir` → push kaybolur (bugün form ASCII `region.id` yazdığı için gizli). | urgent_notifications › BUG-t1-21 |

## Bölge → FCM topic tablosu (t7 ile ortak)

Dart değerleri gerçek `regionTopicName` Dart VM'de çalıştırılarak alındı (geçici flutter testi, sonra silindi).

| Girdi | JS (`index.ts`) | Dart (`regionTopicName`) | Aynı mı |
|---|---|---|---|
| `bodrum` | `region_bodrum` | `region_bodrum` | ✔ |
| `Bodrum` | `region_bodrum` | `region_bodrum` | ✔ |
| `"  Antalya "` | `region_antalya` | `region_antalya` | ✔ |
| `Ege Bölgesi` | `region_ege_b_lgesi` | `region_ege_b_lgesi` | ✔ |
| `Muğla` | `region_mu_la` | `region_mu_la` | ✔ |
| `İzmir` | `region_i_zmir` | `region_izmir` | ✖ (BUG-t1-21) |
| `Çeşme` | `region__e_me` | `region__e_me` | ✔ |
| `KAPADOKYA` | `region_kapadokya` | `region_kapadokya` | ✔ |
| `🏖️ Bodrum` | `region_____bodrum` | `region_____bodrum` | ✔ |
| `side-manavgat.v2~%` | `region_side-manavgat.v2~%` | aynı | ✔ |
| `"   "` | `region_` | `region_` (istemci `selectRegion` boş bölgeyi zaten reddeder) | ✔ (BUG-t1-20) |

`tourism_region.dart`'taki 10 `id`'nin tamamı `region_<id>` üretir (testte Dart kaynağı parse edilerek doğrulanıyor).

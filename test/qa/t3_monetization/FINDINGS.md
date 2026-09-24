# t3 — Gelir akışları (boost, acil ilan, IAP, banner reklam) bulguları

Ayrıntılı rapor: `C:\Users\kmeti\otelcim_qa\shared\reports\t3.md`.
Bilinen hata testleri skip'li; çalıştırmak için:
`flutter test test/qa/t3_monetization --dart-define=T3_RUN_BUGS=true` (28 test kırmızı olmalı).

| ID | Şiddet | Dosya:satır | Repro testi |
|---|---|---|---|
| BUG-t3-01 | Orta | `lib/features/boosts/domain/boost_model.dart:39-51` | boost_models_test: `14-day server boost ("days14") parses as days14` (+2) |
| BUG-t3-02 | Orta | `boost_model.dart:74`, `banner_ad_model.dart:36` | boost_models_test: `durationDays stored as a double…`, `order stored as a double…`; banner_ad_edge_test: `one hand-edited banner with order 1.0…`; boost_service_test: `one malformed boost document…` |
| BUG-t3-03 | Kritik | `lib/shared/services/payment_service.dart:151` | payment_service_test: `boost / urgent products are bought as consumables…` |
| BUG-t3-04 | Yüksek | `payment_service.dart:81-83` | payment_service_test: `successful purchase is NOT acknowledged before the backend verified it` |
| BUG-t3-05 | Orta | `boost_service.dart:57-63`, `urgent_listing_service.dart:59-68`, `error_mapper.dart:35` | boost_purchase_screen_test / urgent_listing_purchase_screen_test: `[BUG-t3-05] …` |
| BUG-t3-06 | Yüksek | `boost_purchase_screen.dart:47-58`, `urgent_listing_purchase_screen.dart:58-64` | `[BUG-t3-06] …` (iki ekran) |
| BUG-t3-07 | Yüksek | `boost_purchase_screen.dart:269-290` (+ sunucu, t1) | `[BUG-t3-07] extending an active boost…` |
| BUG-t3-08 | Düşük | `boost_purchase_screen.dart:207-210` | `[BUG-t3-08] priceOverride parses…` |
| BUG-t3-09 | Orta | `boost_purchase_screen.dart:451-453` | `[BUG-t3-09] paid purchase button is disabled…` |
| BUG-t3-10 | Orta | `urgent_listing_purchase_screen.dart:158-162` | `[BUG-t3-10] listing that is already urgent…` |
| BUG-t3-11 | Orta | `my_boosts_screen.dart:140,165,180` | `[BUG-t3-11] only the purchase that is actually running…` |
| BUG-t3-12 | Düşük | `banner_ad_model.dart:76-77` | boost_models_test: `copyWith cannot clear an end date…` |
| BUG-t3-13 | Düşük | `my_boosts_screen.dart:124` | `[BUG-t3-13] prices use Turkish formatting…` |
| BUG-t3-14 | Orta | `boost_service.dart:130-133,150-153`, `banner_ad_service.dart:39-42,60-63` | boost_service_test: `a rejected … query surfaces…` (2); my_boosts_screen_test: `[BUG-t3-14] …` |
| BUG-t3-15 | Orta | `banner_ad_service.dart:25` + `admin_banner_ads_screen.dart:346-362` | banner_ad_edge_test: `banner whose end date is today…` |
| BUG-t3-16 | Düşük | `banner_ad_carousel.dart:204` | `[BUG-t3-16] advertiser name is upper-cased with Turkish rules` |
| BUG-t3-17 | Düşük | `admin_banner_ads_screen.dart:365-405,533-541,378` | admin_banner_ads_screen_test: `[BUG-t3-17] …` (3) |

Test edilemeyen: `BoostService.processBoostPurchase/redeemFreeBoost`, `UrgentListingService` (FirebaseAuth.instance + statik `http.post`, URL hardcoded) → boost_service_test'teki üç test yalnızca bunu belgeler; yanıt ayrıştırma mantığı (200+error, 500+HTML, boş gövde) test edilemedi.

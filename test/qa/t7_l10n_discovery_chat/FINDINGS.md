# t7 — Yerelleştirme, Keşif, Harita ve Sohbet QA Bulguları

**Uzman:** t7 (Gemini)  
**Tarih:** 2026-09-23  
**Kapsam:** l10n (#60, #61), RTL, Home/Discovery/Nearby/Categories, Chat, Notification, Responsive/Theme  
**Test Klasörü:** `test/qa/t7_l10n_discovery_chat/`

---

## 1. Bulunan Hatalar Tablosu

| ID | Şiddet | Dosya:Satır | Kısa Tanım | Repro Testi |
|---|---|---|---|---|
| **BUG-t7-01** | Yüksek | `lib/features/**`, `lib/shared/widgets/**` | ~490+ hardcoded Türkçe metin (Issue #60) | `hardcoded_strings_ratchet_test.dart` ("Target: Zero hardcoded...") |
| **BUG-t7-01b** | Orta | `lib/l10n/app_de.arb` | Almanca ARB'de eksik anahtarlar (~99/253) | `l10n_arb_parity_test.dart` ("German ARB has 100% key parity...") |
| **BUG-t7-01c** | Orta | `lib/l10n/app_ru.arb` | Rusça ARB'de eksik anahtarlar (~99/253) | `l10n_arb_parity_test.dart` ("Russian ARB has 100% key parity...") |
| **BUG-t7-01d** | Orta | `lib/features/categories/presentation/categories_screen.dart:27` | Kategoriler ekranında İngilizce'de Türkçe etiket sızıntısı | `hardcoded_strings_ratchet_test.dart` ("CategoriesScreen in English...") |
| **BUG-t7-01e** | Orta | `lib/features/chat/presentation/chat_list_screen.dart:27-50` | Giriş yapılmamış sohbet ekranında İngilizce'de Türkçe metin sızıntısı | `hardcoded_strings_ratchet_test.dart` ("ChatListScreen unauthenticated...") |
| **BUG-t7-01f** | Düşük | `lib/shared/widgets/desktop_top_nav_bar.dart:145,241` | DesktopTopNavBar'da "Turizm & Otel İş İlanları" ve "Favorilerim" hardcoded | `hardcoded_strings_ratchet_test.dart` ("DesktopTopNavBar in English...") |
| **BUG-t7-02** | Yüksek | `lib/features/home/presentation/widgets/home_screen_widgets.dart:63` | `salaryLabel` min+max aralığında '$min - $max TL' hardcoded, bidi izolasyonsuz (Issue #61) | `bidi_rtl_currency_test.dart` ("HomeAdvancedFilters.salaryLabel...") |
| **BUG-t7-02b** | Orta | `lib/l10n/app_ar.arb:76-77` | Arapça maaş etiketlerinde bidi kontrol karakteri/izolasyonu eksikliği | `bidi_rtl_currency_test.dart` ("Arabic currency strings in ARB...") |
| **BUG-t7-02c** | Orta | `lib/features/home/presentation/widgets/home_screen_widgets.dart` | Maaş sayılarında yerelleştirilmiş `NumberFormat` yerine ham `int.toString()` kullanımı | `bidi_rtl_currency_test.dart` ("Large salary amounts use...") |
| **BUG-t7-03** | Yüksek | `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:295` | `ChatMessageList` fiziksel `Alignment.centerRight` kullanıyor; Arapça/RTL'de baloncuklar ters tarafta | `bidi_rtl_currency_test.dart` ("ChatMessageList uses AlignmentDirectional...") |
| **BUG-t7-04** | Orta | `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:129` | `ChatHiredBanner` değerlendirme butonunda fiziksel `Alignment.centerRight` kullanıyor | `bidi_rtl_currency_test.dart` ("ChatHiredBanner uses AlignmentDirectional...") |
| **BUG-t7-04b** | Düşük | `lib/features/categories/presentation/categories_screen.dart:30`, `lib/features/discovery/presentation/regions_screen.dart:52` | RTL dillerde geri/ters yöne işaret eden sabit `Icons.chevron_right` kullanımı | `bidi_rtl_currency_test.dart` |
| **BUG-t7-05** | Orta | `lib/shared/services/locale_service.dart:42-60` | `LocaleController._load()` asenkron yarış durumu (setLocale seçimini ezme) | `locale_controller_test.dart` ("LocaleController._load does not overwrite...") |
| **BUG-t7-06** | Yüksek | `lib/shared/services/chat_service.dart:44-78` | `watchConversations` alt sorgulardan biri hata verirse stream hiçbir şey yaymıyor ve UI kilitleniyor | `chat_service_test.dart` ("watchConversations emits error or empty...") |
| **BUG-t7-07** | Orta | `lib/shared/services/chat_service.dart:37-38` | `watchConversations` sort comparator'ı null tarihler için `DateTime.now()` çağırıyor (kararsız sıralama) | `chat_service_test.dart` ("watchConversations sort comparator...") |
| **BUG-t7-08** | Orta | `lib/shared/services/chat_service.dart:142-164` | `getOrCreateConversation` kullanıcının kendi ilanıyla konuşma başlatmasını engellemiyor (`posterId == seekerId`) | `chat_service_test.dart` ("getOrCreateConversation rejects self-conversation...") |
| **BUG-t7-09** | Düşük | `lib/shared/services/chat_service.dart:166-180` | `sendMessage` boş veya salt boşluk metinleri kabul edip Firestore'a kaydediyor | `chat_service_test.dart` ("sendMessage rejects empty or whitespace-only...") |
| **BUG-t7-10** | Orta | `lib/shared/services/chat_service.dart:131-132` | `watchMessages` timestamp'i henüz atanmamış yerel mesajı epoch 0 ile en tepeye atıyor (UX zıplaması) | `chat_service_test.dart` ("watchMessages orders pending messages...") |
| **BUG-t7-11** | Orta | `lib/shared/services/chat_service.dart:205-220` | `confirmInterviewSlot` seçilen slotun önerilen slotlar listesinde olduğunu doğrulamıyor | `chat_service_test.dart` ("confirmInterviewSlot validates that selectedSlot...") |
| **BUG-t7-12** | Yüksek | `lib/shared/services/notification_service.dart:15-18`, `functions/src/index.ts:209` | Unicode birleşik nokta farkı yüzünden `"İzmir"` (`region_i_zmir`) ile `"izmir"` (`region_izmir`) uyuşmuyor; bildirim kayboluyor | `notification_service_region_test.dart` ("regionTopicName produces identical...") |
| **BUG-t7-13** | Düşük | `lib/features/discovery/presentation/regions_screen.dart:21,50` | `RegionsScreen` yalnızca İngilizce kontrolü yapıyor; Almanca, Rusça ve Arapça için Türkçe isim gösteriyor | `discovery_nearby_test.dart` ("RegionsScreen provides localized region...") |

---

## 2. Hata Detayları ve Çözüm Önerileri

### BUG-t7-12: FCM Konu Adı Unicode Ayrışması ("İzmir" vs "izmir")
- **Şiddet:** Yüksek
- **Dosya:** `lib/shared/services/notification_service.dart:14-20` ve `functions/src/index.ts:209`
- **Açıklama:** Dart ve V8 motorunda büyük Türkçe `"İ"` harfi `toLowerCase()` yapıldığında iki Unicode kod noktasına ayrışır: Latin küçük `i` (U+0069) ve birleşik üst nokta `\u0307` (U+0307). `replaceAll(RegExp(r'[^a-z0-9-_.~%]'), '_')` filtresi birleşik noktayı `_` ile değiştirerek `"region_i_zmir"` üretir. Fakat ilan veya istemci küçük harfli `"izmir"` ilettiğinde standart tek `i` olduğu için `"region_izmir"` konusu üretilir.
- **Sonuç:** Kullanıcı arayüzden `"İzmir"` bölgesini seçip abone olduğunda FCM konusu `region_i_zmir` olur. Backend ilanın küçük harfli bölgesine (`region: "izmir"`) push attığında bildirim `region_izmir` konusuna gider. **İzmir'deki tüm acil ilan bildirimleri sessizce kaybolur.**
- **Öneri:** `regionTopicName` fonksiyonunda `toLowerCase()` öncesinde Türkçe harfler açıkça ASCII karşılıklarına çevrilmelidir:
  ```dart
  String regionTopicName(String region) {
    final normalized = region.trim()
        .replaceAll('İ', 'i').replaceAll('I', 'i')
        .replaceAll('Ğ', 'g').replaceAll('ğ', 'g')
        .replaceAll('Ü', 'u').replaceAll('ü', 'u')
        .replaceAll('Ş', 's').replaceAll('ş', 's')
        .replaceAll('Ö', 'o').replaceAll('ö', 'o')
        .replaceAll('Ç', 'c').replaceAll('ç', 'c')
        .toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9-_.~%]'), '_');
    return 'region_$safe';
  }
  ```

### BUG-t7-03: Sohbet Mesaj Baloncuklarının RTL'de Ters Hizalanması
- **Şiddet:** Yüksek
- **Dosya:** `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:295`
- **Açıklama:** `ChatMessageList` içinde mesaj baloncukları:
  ```dart
  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft
  ```
  şeklinde fiziksel hizalanmaktadır. Arapça (RTL) modunda metin akışı sağdan sola olduğu için ekranın sağı START (başlangıç), solu ise END (bitiş) tarafıdır.
- **Sonuç:** Arapça kullanan bir kullanıcının kendi gönderdiği mesajlar fiziksel sağda kalır; yani Arapça okuma düzeninde "karşıdan gelen mesaj" konumunda görünür.
- **Öneri:** `AlignmentDirectional.centerEnd` (gönderen) ve `AlignmentDirectional.centerStart` (alıcı) kullanılmalıdır.

### BUG-t7-06: `ChatService.watchConversations` Hata Durumunda Stream'in Asılı Kalması
- **Şiddet:** Yüksek
- **Dosya:** `lib/shared/services/chat_service.dart:44-78`
- **Açıklama:** Poster ve Seeker sorgularının her ikisinde de `onError: handleError` tanımlanmış ve bu metot sadece `debugPrint` çağırmaktadır.
  ```dart
  void emitConversations() {
    if (!hasPosterSnapshot || !hasSeekerSnapshot || controller.isClosed) return;
    ...
  }
  ```
- **Sonuç:** Alt sorgulardan biri yetki veya ağ hatası aldığında o sorgunun snapshot bayrağı asla `true` olmaz. `emitConversations` hiçbir zaman çalışmaz ve stream hata yaymaz. UI sonsuza kadar `CircularProgressIndicator` içinde takılı kalır.
- **Öneri:** `handleError` içinde `controller.addError(error, stackTrace)` çağrılmalıdır.

---

## 3. Kod Kalitesi ve Mimari Bulguları

1. **God Widget Dosyaları:**
   - `lib/features/home/presentation/widgets/home_screen_widgets.dart` 1391 satır. İçinde filtre alt sayfası, filtre çipleri, arama çubuğu ve ilan kartları tek bir devasa dosyada yer alıyor.
   - `lib/features/home/presentation/home_screen.dart` 670 satır.
   - `lib/features/chat/presentation/chat_detail_screen.dart` 425 satır.

2. **Para ve Sayı Biçimlendirme Eksikliği:**
   - Projede `intl` paketinin `NumberFormat` sınıfı maaş alanlarında kullanılmıyor.
   - String interpolasyonu ile `'$salary TL'` veya `'$minSalaryTl - $maxSalaryTl TL'` gibi elle metin birleştirme yapılıyor. Bu durum çok dilli ortamda hem çeviriyi imkansız kılıyor hem de RTL dillerde bidi sırasını bozuyor.

3. **Yönelimsiz Padding (Non-directional Padding):**
   - Kod tabanında `EdgeInsets.only(left: ...)` ve `EdgeInsets.only(right: ...)` kalıbı yaygın olarak kullanılıyor. RTL destekleyen uygulamalarda `EdgeInsetsDirectional.only(start: ..., end: ...)` tercih edilmelidir.

---

## 4. Test Edilemeyen Alanlar ve Nedeni

1. **`NotificationService` Platform Eklentileri:**
   - `NotificationService` kurucusunda `FirebaseMessaging.instance` ve `FlutterLocalNotificationsPlugin` sınıfları doğrudan alan başlatıcı olarak oluşturuluyor.
   - Kurucu üzerinden enjekte edilemedikleri için `init()`, `setCurrentUser()`, `selectRegion()` gibi gerçek platform kanalı ve FCM çağrıları yapan metotlar host ortamındaki birim testlerinde doğrudan çalıştırılamıyor.
   - **Çözüm Önerisi:** Bağımlılıkların kurucu üzerinden (`this._messaging`, `this._plugin`) enjekte edilebilmesi sağlanmalı, varsayılan parametre olarak singleton'lar atanmalıdır.

2. **Acil İlan Bildirimi Tıklama Yönlendirmesi:**
   - `NotificationService._handleOpenedMessage` sadece `conversationId` alanını kontrol ediyor:
     ```dart
     final conversationId = message.data['conversationId'] as String?;
     if (conversationId != null && conversationId.isNotEmpty) {
       _onOpenChat?.call(conversationId);
     }
     ```
   - Cloud Functions tarafından gönderilen acil ilan bildirimlerinde ise `type: 'urgent_listing'`, `listingId` alanları gönderiliyor. İstemci bu veriyi dinlemediği için kullanıcı bildirime tıkladığında ilan sayfasına yönlendirilemiyor.

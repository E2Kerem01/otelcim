# m12_device_a11y — Erişilebilirlik, Karanlık Mod, Büyük Yazı, RTL ve Cihaz Uyumluluğu Bulguları

**Tarih:** 2026-09-24  
**Kapsam:** `lib/app/theme*`, `lib/main.dart`, `lib/core/responsive/`, `lib/features/{home,listings,profile,chat,auth}/`  
**Test Aracı:** Maestro E2E YAML akışları & Statik Kod / UI Hiyerarşisi İncelemesi  

---

## 1. Tespit Edilen Hatalar ve Teknik Bulgular (Bugs)

### BUG-m12-01: Sistem Karanlık Modunda Uygulama Açık Temaya Kilitli (`ThemeMode.light`)
- **Dosya / Satır:** `lib/main.dart:84` ve `lib/app/theme.dart:5-75`
- **Önem Derecesi:** Yüksek
- **Tekrar Üretme Adımları:**
  1. Cihaz / emülatör ayarlarından sistem karanlık modunu açın (`adb shell cmd uimode night yes`).
  2. Uygulamayı başlatın.
- **Beklenen Davranış:** Uygulama `themeMode: ThemeMode.system` ile sistemin karanlık mod tercihini algılamalı ve `darkTheme` yapılandırmasını devreye alarak koyu arayüz sunmalıdır.
- **Gerçek Davranış:** `MaterialApp.router` içinde `themeMode: ThemeMode.light` hardcoded olarak sabitlenmiştir. Ayrıca `darkTheme` parametresi hiç tanımlanmamıştır. Bu sebeple kullanıcı veya sistem gece modunu seçse dahi uygulama tamamen beyaz/açık renk temada çalışmaktadır.

---

### BUG-m12-02: Kritik İkon-Only Butonlarda Erişilebilirlik Etiketi / Tooltip Eksikliği (D6)
- **Dosya / Satır:**
  - `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:349` (`IconButton(icon: Icon(Icons.send_rounded), onPressed: onSend)`)
  - `lib/features/listings/presentation/listing_detail_screen.dart:233` (`IconButton(icon: const Icon(Icons.share_outlined), onPressed: ...)`)
  - `lib/features/home/presentation/home_screen.dart:243` (`IconButton(icon: const Icon(Icons.clear_rounded), onPressed: _clearSearch)`)
  - `lib/features/home/presentation/widgets/home_screen_widgets.dart:211` (`IconButton(icon: const Icon(Icons.close), onPressed: ...)`)
  - `lib/features/listings/presentation/create_listing_screen.dart:442` (`InkWell(child: Icon(Icons.close))`)
- **Önem Derecesi:** Orta
- **Tekrar Üretme Adımları:**
  1. Ekran okuyucu (TalkBack veya Maestro accessibility inspection) açıkken sohbet detay veya ilan detay ekranına girin.
  2. Gönder veya Paylaş butonunun üzerine gelin.
- **Beklenen Davranış:** İkon-only butonların her birinde `tooltip:` özelliği veya `Semantics(label: ...)` sarmalayıcısı bulunmalı; ekran okuyucu butonun işlevini (örn. "Gönder", "Paylaş", "Aramayı Temizle", "Kapat") seslendirmelidir.
- **Gerçek Davranış:** Belirtilen butonlarda hiçbir erişilebilirlik etiketi bulunmamaktadır. Ekran okuyucu bu butonları "Etiketsiz düğme" (unlabeled button) olarak okumakta veya tamamen atlamaktadır.

---

### BUG-m12-03: Arapça RTL Modunda Maaş Bilgisinin Hardcoded LTR Türkçe Formatında Kalması (#61)
- **Dosya / Satır:** `lib/features/home/presentation/widgets/home_screen_widgets.dart:809, 1059`
- **Önem Derecesi:** Orta
- **Tekrar Üretme Adımları:**
  1. Uygulama dilini Arapça (`ar`) yapın.
  2. Ana sayfadaki ilan kartlarına bakın.
- **Beklenen Davranış:** Para birimi ve sayısal format yerelleştirilmeli (ARB şablonundaki `salaryMinAndUp: "{amount} ليرة فأكثر"` veya Arapça sayı/para birimi gösterimi kullanılmalı) ve RTL akışına uyumlu olmalıdır.
- **Gerçek Davranış:** Ham string olarak saklanan `listing.salary` ("35.000 TL") doğrudan LTR yönünde basılmakta; Arapça RTL düzeninde çift yönlü metin (BiDi) hizalama bozukluğuna yol açmaktadır.

---

### BUG-m12-04: Profil Menüsü ve Sohbet Ekranlarında Yaygın Hardcoded Türkçe Metinler (#60)
- **Dosya / Satır:**
  - `lib/features/profile/presentation/profile_screen.dart:420-495`
  - `lib/features/chat/presentation/widgets/chat_detail_widgets.dart:342`
  - `lib/features/listings/presentation/listing_detail_screen.dart:212`
- **Önem Derecesi:** Düşük
- **Tekrar Üretme Adımları:**
  1. Dili İngilizce, Almanca, Rusça veya Arapça olarak değiştirin.
  2. Hesabım sekmesine gidin.
- **Beklenen Davranış:** Tüm profil satır başlıkları (`AppLocalizations`) üzerinden çevrilmelidir.
- **Gerçek Davranış:** "Profili Düzenle", "Belgelerim / Sertifika Cüzdanı", "Favorilerim", "İlanlarım", "Öne Çıkarılan İlanlarım", "Bildirim Ayarları", "Gizlilik ve Veri Ayarları", "Arkadaşını Davet Et", "Uygulama Dili", "Çıkış Yap" ve mesaj giriş ipucu ("Mesajınızı yazın...") tamamen hardcoded Türkçe olarak kalmaktadır.

---

## 2. Yazı Boyutu 2.0 (Font Scale 2.0) ve Taşma (Overflow) Riskleri

Kaynak kodun incelenmesi sonucunda, büyük font boyutlarında (Accessibility Font Scaling 2.0) taşma (RenderFlex overflow) riski taşıyan yapılar tespit edilmiştir:

1. **İlan Kartı Üst Rozet Satırı (`home_screen_widgets.dart:860-968`):**
   - Tek bir yatay `Row` içerisinde Kategori Rozeti, Boost Rozeti, Sezon Rozeti, Uyum Skoru Rozeti, Acil Rozeti, Favori Butonu ve İlan Tarihi yan yana dizilmiştir.
   - Normal yazı boyutunda bile yoğun olan bu satır, font boyutu 2.0 olduğunda metinlerin genişlemesi sebebiyle sağ taraftan `RenderFlex overflowed by ... pixels` hatası üretme riski taşımaktadır.
   - **Öneri:** Rozet grubu tek bir yatay satır yerine `Wrap(spacing: 6, runSpacing: 4, ...)` içerisine alınmalıdır.

2. **Sabit Yükseklikli Yatay Çip Listeleri (`home_screen.dart:373`):**
   - Kategori filtre çipleri `SizedBox(height: 48)` içine yerleştirilmiştir.
   - Font scale 2.0 olduğunda çip metinleri 2 katına çıkmakta, dikey padding ile birlikte 48 piksel yüksekliği aşarak alt kısımdan kırpılma tehlikesi yaratmaktadır.
   - **Öneri:** Sabit `height: 48` yerine `IntrinsicHeight` veya responsive dikey sınır kullanılmalıdır.

3. **İki Sütunlu Izgara Görünümü (`home_screen.dart:576-581`):**
   - `childAspectRatio: _columnCount == 2 ? 0.80 : ...` sabit oranla kilitlenmiştir.
   - Büyük yazılarda başlık 2 satıra, konum 1 satıra ve maaş büyüyen yazıya sahip olduğunda kartın altındaki maaş alanı kart sınırından dışarı taşabilir.

---

## 3. Yatay Ekran (Landscape) ve Responsive Düzen İncelemesi

1. **Breakpoint Geçişleri (`ResponsiveLayout`):**
   - Pixel 10 Pro cihazı yatay konuma (`LANDSCAPE_LEFT`) çevrildiğinde mantıksal genişlik 768 pikselin üzerine çıkmaktadır.
   - Bu durumda `router.dart:206`'daki `isDesktop` kontrolü tetiklenmekte; alt navigasyon çubuğu gizlenerek ekranın üstüne `DesktopTopNavBar` yerleşmektedir.
   - `LoginScreen` ve `ListingDetailScreen` de geniş ekran moduna geçerek iki sütunlu (Master-Detail / Sticky Action Card) masaüstü düzenine dönüşmektedir.
   - **Sonuç:** Yatay modda responsive geçişler başarıyla çalışmakta, içerik formları ve navigasyon kullanılabilir kalmaktadır.

2. **RTL Yön Aynalama Eksikliği:**
   - Profil menüsündeki `Icons.chevron_right_rounded` (`profile_screen_widgets.dart:70`), Arapça RTL modunda sola doğru yönelmemekte, sabit olarak sağa bakmaktadır.
   - **Öneri:** `Icons.chevron_right` yerine Flutter'ın otomatik yön aynalamalı widget'ları veya `Transform.scale(scaleX: -1)` kullanılmalıdır.

---

## 4. Test Edilemeyen Akışlar ve Gerekçeleri

1. **İşletim Sistemi TalkBack Seslendirmesi:**
   - TalkBack'in TTS (Text-to-Speech) ses çıktısının akustiği ve doğru telaffuz Maestro üzerinden doğrudan test edilemez; yalnızca Android Accessibility Node Hiyerarşisindeki `contentDescription` / `tooltip` varlığı assert edilebilir.
2. **Fotoğraf / Dosya Yükleme Ekranları:**
   - PLAN.md güvenlik kuralları gereği Firebase Storage emüle edilmediğinden dosya yükleme tetiklenmemiştir; sadece form elemanları test edilmiştir.

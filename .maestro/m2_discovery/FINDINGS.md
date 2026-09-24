# m2_discovery bulguları

## Koddan doğrulanan kapsam

- Ana feed `lib/features/home/presentation/home_screen.dart` ve `home_screen_widgets.dart` içinde; arama ipucu `İş ilanı ara...`, filtre tooltip'i `Filtreler`, yakınındaki düğme `Yakınımda`, sezon tooltip'i `Sezon Takvimi`, sonuç biçimi `{count} sonuç`.
- Feed kartı metinleri seed'deki başlık/konum/maaş değerlerini kullanıyor. Boost etiketi `lib/features/boosts/presentation/widgets/boost_badge.dart:30` içinde hardcoded `Öne Çıkan`; acil etiketi ARB `urgentBadge` değerinden `ACİL`.
- Kategori ekranı `lib/features/categories/presentation/categories_screen.dart` içinde `Kategoriler` ve gerçek kategori label'ları hardcoded/constants kaynaklıdır.
- Bölge listesi `lib/features/discovery/presentation/regions_screen.dart`; harita ekranı `region_map_screen.dart`; m2 akışları harita tile/marker içeriğini assert etmiyor.
- Yakındaki ekran izin açıklaması, `Vazgeç`, `Devam Et`, `Tekrar dene` ve `km uzakta` metinlerini ARB/kaynak widget'tan alır.
- Sezon takvimi `lib/features/seasonal/presentation/seasonal_calendar_screen.dart` içinde yerelleştirilmemiş Türkçe metinler de içerir; akış yalnızca ekranı ve yetkisiz kullanıcı görünümünü doğrular.

## Bug'lar

### BUG-M2-01 — Yüksek

- Kaynak: `lib/shared/constants/listing_filters.dart:55-71` (`ListingSeason` yalnızca `yaz_2025`, `kis_2025_26`, `tum_yil`); seed: `.maestro/seed/seed.mjs:64,100-107` (`season: 'yaz_2026'`).
- Tekrar üretme: `bugs/BUG-M2-01_season_2026_filter.yaml` akışını çalıştır; ana sayfada Filtreler'i açıp Sezon dropdown'ını aç.
- Beklenen: `Yaz 2026` seçeneği görünür; seçilince seed'in yaz_2026 aktif ilanları filtrelenir.
- Gerçek: `Yaz 2026` seçeneği yok; bu sezon için doğru filtre seçilemiyor.

## UX / erişilebilirlik bulguları

- `home_screen.dart:242-249` arama alanının temizleme `IconButton`'ında `tooltip` yok. Akış 02 bu nedenle clear ikonunu seçmeye çalışmak yerine odaktaki alanı `eraseText` ile temizliyor; ikon düğmesi erişilebilir seçiciyle bağımsız doğrulanamıyor.
- Feed görünüm düğmeleri ve bölge/yakındaki segmented düğmeleri tooltip ile etiketlenmiş; akışlarda tooltip tabanlı seçiciler için `# TAHMİN` notları bırakıldı.
- Feed görünüm düğmelerindeki Flutter `Key` değerleri (`grid_col_2`, `grid_col_table`) cihaz hiyerarşisinde seçilebilir görünmedi; Maestro akışlarında kaynak tooltip metinleri (`2 Sütun`, `Tablo Görünümü`) kullanılmalıdır.
- Sezon takvimi ekranında bazı Türkçe metinler doğrudan widget içinde hardcoded (`seasonal_calendar_screen.dart:42-121,155-276`); mevcut `tr` akışını bozmadığı için bug klasörüne alınmadı.

## Test edilemeyen / özellikle dokunulmayanlar

- Boş feed içindeki `Örnek İlanları Veritabanına Yükle` düğmesine basılmadı; PLAN güvenlik yasağı gereği seed'i bozmamak için yalnızca boş durum metni assert edildi.
- Harita tile/marker içeriği assert edilmedi; kaynak ekranı açılıp liste moduna geçiş ve geri tuşu doğrulandı.
- m2 kaynaklarında discovery için jobseeker/employer ayrımı yok; akış 15 employer ile rol-bağımsız feed erişimini doğrular. Rol kısıtlı aksiyonlar m4/m5 kapsamındadır.
- Fotoğraf/dosya, satın alma/boost redeem ve Cloud Function sonuçları m2 kapsamında değildir ve tetiklenmedi.

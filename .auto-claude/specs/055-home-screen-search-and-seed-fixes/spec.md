# Ana Sayfa: Otomatik Sahte Veri Yükleme, Arama Debounce, Mobil Sütun Taşması

## Öncelik: Yüksek

Üç ayrı bulgu, hepsi `lib/features/home/presentation/home_screen.dart` içinde — tek işçiye, tek dosya olarak veriliyor (çakışma riski olmasın diye).

## 1. Sonuçsuz aramada otomatik sahte ilan yükleme (Kritik/Veri Bütünlüğü)
- `_buildEmptyState` metodu (satır ~530) içinde `Future.microtask(() => ref.read(listingServiceProvider).seedSampleListings());` var — bu metod HER boş sonuç durumunda (gerçekten boş DB olsun ya da kullanıcı "xyz123" gibi sonuçsuz bir arama yapmış olsun farketmeksizin) tetikleniyor.
- **Fix**: Bu otomatik `Future.microtask` çağrısını KALDIR. Metodun altındaki manuel "Örnek İlanları Veritabanına Yükle" butonu (satır ~556-561) zaten var, dokunma — sadece otomatik tetiklemeyi sil.

## 2. Arama kutusunda debounce yok (Performans/Firebase kotası)
- Arama `TextField`'ının `onChanged` callback'i (satır ~230 civarı, `setState(() => _searchQuery = value.trim())`) her tuş vuruşunda direkt state güncelliyor, bu da (muhtemelen `_currentParams`/pagination provider üzerinden) her harfte yeniden sorgu tetikliyor.
- **Fix**: 300-400ms'lik bir debounce ekle (paket eklemeden, `Timer`/`Timer?` ile — `dart:async` zaten kullanılabilir): kullanıcı yazmayı bıraktıktan 300-400ms sonra `_searchQuery`/sorgu güncellensin. `State`'e bir `Timer? _debounce;` ekle, `onChanged`'de `_debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 350), () => setState(() => _searchQuery = value.trim()));`, `dispose()`'da `_debounce?.cancel();` unutma.

## 3. Mobilde 3-4 sütun seçilebiliyor, kartlar taşıyor
- Sütun sayısı toggle'ı (satır ~399 civarı, `[1, 2, 3, 4].map((cols) => ...)`) mobil ekranda da 3/4 seçeneğini gösteriyor; küçük telefon genişliğinde bu kadar sütun kart içeriğinin (başlık, buton) birbirine girmesine yol açıyor.
- **Fix**: Toggle'ın seçenek listesini ekran genişliğine göre sınırla — `context.isDesktop`/`context.isTablet` (zaten `lib/core/responsive/responsive_layout.dart`'ta var, import et) `false` ise (yani mobil genişlikte) sadece `[1, 2]` göster, tablet/desktop'ta `[1, 2, 3, 4]` tam liste kalsın. Mobilde eğer kullanıcı daha önce (örn. masaüstünde) 3/4 seçmişse ve sonra mobile geçtiyse `_columnCount`'u da mobil sınırına clamp'le (`if (!context.isTablet && !context.isDesktop && _columnCount > 2) _columnCount = 2;` gibi, `didChangeDependencies` içinde, mevcut responsive init mantığının yanına).

## Dosya Çakışma Uyarısı
Sadece `home_screen.dart`. Başka spec bu dosyaya dokunmuyor.

## Acceptance Criteria
- [ ] "xyz123" gibi sonuçsuz bir arama yapıldığında Firestore'a otomatik örnek ilan YAZILMIYOR (manuel buton hâlâ çalışıyor)
- [ ] Arama kutusuna hızlıca yazıldığında her harfte değil, yazma durduktan ~350ms sonra sorgu tetikleniyor
- [ ] Mobil genişlikte (< 600px) sütun toggle'ında sadece 1/2 seçenekleri var, kartlar taşmıyor
- [ ] Masaüstünde 1/2/3/4 seçenekleri hâlâ çalışıyor (spec 043-049'daki responsive grid fix'i bozulmadı)
- [ ] `flutter analyze` temiz, `flutter test` geçiyor (özellikle `test/features/home/home_screen_test.dart`)

# m11_resilience bulguları

## Kod bulguları

| Önem | Konum | Bulguyu yeniden üretme | Beklenen / gerçek |
|---|---|---|---|
| Yüksek | `lib/shared/services/listing_service.dart:287-432`, `lib/shared/providers/paginated_listings_provider.dart:77-113` | `# seed: many`; ana sayfada `Sayfa İlanı 30` arat | Beklenen: arama tüm sayfalarda aranır. Gerçek: sorgu önce ilk 20 belgeyi çeker, arama sonradan istemci tarafında filtrelenir; P30 ilk sayfada olmadığı için sonuç yok. `bugs/BUG-M11-01...` |
| Orta | `lib/features/home/presentation/home_screen.dart:424-425` | `# seed: many`; ilk sayfa yüklenir | Beklenen: toplam aktif sonuç sayısı. Gerçek: `paginationState.listings.length`, ilk ekranda 20 gösterir; yükleme sonrası sayı büyür. `bugs/BUG-M11-02...` |
| Yüksek | `lib/shared/providers/paginated_listings_provider.dart:62-74, 101-113` ve `lib/features/home/presentation/home_screen.dart:537-541,605-643` | offline akışı veya Firestore erişim hatası | Beklenen: kullanıcıya ağ hatası ve yeniden dene. Gerçek: hata yalnızca loglanıp boş listeye dönüyor; Home normal boş durumunu ve seed butonunu gösteriyor. `bugs/BUG-M11-03_offline_feed_shows_empty_state.yaml` doğru davranışı belgeleyen skip akışıdır. |
| Düşük | `lib/features/home/presentation/home_screen.dart:424-425` | Uzun başlıklı ilanı kartta aç | Sonuç satırı `listings.length` ile karttaki yüklenmiş kayıtları sayıyor; toplam sayı semantiği ile sayfalama semantiği aynı değil. |

## UX / erişilebilirlik notları

- Filtre ve takvim düğmeleri kaynakta `tooltip` ile etiketli; akışlar bu erişilebilir metinleri kullanıyor.
- Grid/tablo düğmelerinde kaynakta `Key` ve `Tooltip` var; ancak akışlar m11 kapsamında kart içeriği ve sayfalama davranışına odaklandı.
- Boş durumdaki `Örnek İlanları Veritabanına Yükle` düğmesi testlerde bilerek tetiklenmedi; PLAN güvenlik yasağı.
- Uzun içerik akışı görsel taşmayı `takeScreenshot` ile kayıt altına alır; görsel karar cihaz çalıştırmasında verilecektir.

## Test edilemeyenler

- Bu ortamda cihaz/emülatör ve ağ kesme yetkisi yok; Maestro/ADB çalıştırılmadı. `bugs/BUG-M11-03_offline_feed_shows_empty_state.yaml` akışını orkestratör uçak modu ile çalıştırmalıdır.
- Firestore ağ hatasının gerçek ekran çıktısı cihaz koşusunda doğrulanmalıdır; kaynak kod şu an hata durumunu ayrı state olarak taşımıyor.

## Tahmin edilen seçiciler

- `E-posta`, `Şifre`, `Giriş Yap`: ortak login akışındaki gerçek form metinlerinden alınmıştır; `_helpers/login_no_hide_keyboard.yaml` içinde login kuralına uygun olarak `hideKeyboard` yoktur.
- `Filtreler`: `HomeScreen` içindeki `l10n.filtersTooltip` erişilebilirlik etiketinden alınmıştır.
- `grid_col_*` kullanılmadı; kaynakta key olsa da bu dilimin temel sayfalama senaryolarında metin/tooltip seçicileri tercih edildi.
- Uzun formdaki `Örn. ...` seçicileri `create_listing_screen.dart` içindeki hardcoded hint’lerden alınmıştır; regex noktaları ve `+` karakteri kaçırılmıştır.
- Kaynakta karşılığı olmayan tahmini seçici yoktur.

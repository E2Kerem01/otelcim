# İlan Kategorileri — Analiz ve Öneri

_Hazırlanma: 2026-08-30 · Kapsam: `lib/shared/constants/categories.dart` `ListingCategory` enum'u_

> **Durum (2026-09-05):** Öneri A'nın iki turu da uygulandı — ilk turda
> `barBarmen`, `spaWellness`, `havuzPlaj`, `rezervasyonSatis`, `muhasebeIk`
> (9 → 14), ikinci turda `onburoIliskiler`, `pastaneSteward`, `ulasimSofor`,
> `bahcePeyzaj`, `cocukKulubu`, `depoAmbar`, `saglik`, `stajyer` eklendi
> (14 → 22). Bölüm 3'teki liste artık tamamlanmış durumda.

## 1. Mevcut durum

Tek seviyeli, 9 değerli bir enum:

| Enum | Etiket |
|------|--------|
| `resepsiyon` | Resepsiyon |
| `katHizmetleri` | Kat Hizmetleri |
| `mutfakAsci` | Mutfak / Aşçı |
| `servisGarson` | Servis / Garson |
| `guvenlik` | Güvenlik |
| `animasyon` | Animasyon |
| `yonetim` | Yönetim |
| `teknikServis` | Teknik Servis |
| `diger` | Diğer |

`category`, ilan dokümanında enum'un `.name` string'i olarak saklanıyor
(`listing.category`). Filtre, kart rengi ve ikon hep bu enum üzerinden çözülüyor.

## 2. Boşluk analizi

Türkiye kıyı turizminde tam donanımlı resort kadrosu düşünüldüğünde eksik kalan
büyük alanlar:

| Eksik alan | Neden önemli | Şu an nereye düşüyor |
|------------|--------------|----------------------|
| **SPA & Wellness** (terapist, masör, hamam görevlisi, güzellik uzmanı, SPA resepsiyon) | Kıyı resort'larında ayrı ve büyük bir departman; sezonluk yoğun talep | `diger` |
| **Bar / Barmen / Barista** | Resort'ta mutfak-servisten ayrı yönetilir, ayrı ilan verilir | `servisGarson` içine sıkışıyor |
| **Havuz & Plaj** (cankurtaran, havuz görevlisi, plaj görevlisi) | Sezonluk-kritik, yasal cankurtaran zorunluluğu var | `diger` / `teknikServis` |
| **Önbüro yan roller** (misafir ilişkileri, concierge, bellboy, santral, night audit) | Resepsiyon'dan ayrı pozisyonlar | `resepsiyon` |
| **Rezervasyon & Satış-Pazarlama** (rezervasyon, satış, dijital pazarlama, call center) | Ofis tarafı, resepsiyondan bağımsız kadro | `resepsiyon` / `yonetim` |
| **Mutfak alt rolleri: pastane / steward-bulaşık** | Pasta şefi ve steward ayrı ilan verilen roller | `mutfakAsci` |
| **Ulaşım / Transfer / Şoför** | Havalimanı transferi, personel servisi | `diger` |
| **Bahçe & Peyzaj** | Resort'ta ayrı ekip | `teknikServis` / `diger` |
| **Çocuk Kulübü / Bebek Bakıcısı** | Animasyondan ayrı, farklı yetkinlik | `animasyon` |
| **Muhasebe / Finans / Satın Alma / İnsan Kaynakları** | "Yönetim" çok genel; bu roller ayrı aranır | `yonetim` |
| **Depo / Ambar** | Satın almadan ayrı operasyon rolü | `diger` |
| **Sağlık (revir hemşiresi/doktor)** | Büyük tesislerde zorunlu | `diger` |
| **Stajyer** | Turizm/otelcilik okullarından yoğun sezonluk akış | `diger` |

`diger` oranı yüksekse bu, kategorilerin gerçek talebi karşılamadığının en net
sinyali — filtreleme değerini düşürür.

## 3. Öneri

### Öneri A — Genişletilmiş tek seviye (önerilen, düşük risk)

Enum'a **yeni değer eklemek geriye dönük uyumlu** (eski ilanlar etkilenmez).
Mevcut 9 değeri koruyup şunları ekle:

```
spaWellness      → SPA & Wellness
barBarmen        → Bar / Barmen
havuzPlaj        → Havuz & Plaj
onburoIliskiler  → Misafir İlişkileri / Önbüro
rezervasyonSatis → Rezervasyon / Satış-Pazarlama
pastaneSteward   → Pastane / Steward
ulasimSofor      → Ulaşım / Şoför
bahcePeyzaj      → Bahçe & Peyzaj
cocukKulubu      → Çocuk Kulübü / Bakıcı
muhasebeIk       → Muhasebe / İnsan Kaynakları / Satın Alma
depoAmbar        → Depo / Ambar
saglik           → Sağlık / Revir
stajyer          → Stajyer
```

Sonuç: 9 → ~22 kategori. Her yeni değer için `listingCategoryLabels`,
`listingCategoryIcons`, `listingCategoryColors` haritalarına satır eklenmeli
(hepsi `const` ve `!` ile okunuyor — eksik bırakılırsa runtime crash).

**Dezavantaj:** 22 öğeli düz dropdown uzun; kategori filtre çipleri kalabalıklaşır.

### Öneri B — İki seviye (departman → pozisyon)

Ana departman (~8) + altında pozisyon. Örn. `Yiyecek-İçecek → Aşçı / Garson /
Barmen / Steward`. UI'da önce departman, sonra pozisyon seçilir; filtre
departman seviyesinde kalır.

**Dezavantaj:** `listing_model`, form, filtre, kart, `getPaginatedListings`
sorgu katmanı ve mevcut ilanların migration'ı — hepsi dokunulur. Ayrı bir
spec/ADR hak ediyor.

### Tavsiye

**Öneri A ile başla.** Talebi en çok karşılayacak 5 ekleme: `spaWellness`,
`barBarmen`, `havuzPlaj`, `rezervasyonSatis`, `muhasebeIk`. Kalan eklemeler
ikinci turda. İki seviyeli yapı (Öneri B) ancak `diger` + tek-seviye filtre
gerçekten yetersiz kalırsa gündeme alınmalı.

## 4. Yapılırsa dokunulacak yerler

- `lib/shared/constants/categories.dart` — enum + 3 harita
- `lib/l10n/app_*.arb` — kategori etiketleri lokalize edilecekse
- `test/domain/domain_models_test.dart` — enum sayısını sabitleyen test varsa
- Kategori bazlı analytics/rapor varsa yeni değerler eklenince kırılmaz ama
  "bilinmeyen kategori" fallback'i `diger`'e düşer — kontrol et

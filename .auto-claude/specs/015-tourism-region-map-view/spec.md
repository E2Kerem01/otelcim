# Turizm Bölgesi Harita Görünümü

`feature-14` (Tourism Region-Based Job Discovery) kapsamının harita parçası.
**014 (bölge modeli) merge edildikten sonra başla** — bu spec, 014'ün eklediği
`region` alanını ve bölge taxonomy'sini kullanır.

## Açıklama

Türkiye haritası üzerinde turizm bölgelerine göre kümelenmiş ilan pin'leri
gösteren bir harita görünümü. Bir kümeye dokununca 014'te oluşturulan bölge
ilan feed'i açılır.

## Rationale

Harita görünümü, bölge bazlı keşfi görsel ve keşfedilebilir hale getirir.
Rakiplerden hiçbiri (Kariyer.net'in konum filtresi bozuk — pain-2-3) doğru
çalışan bir harita/konum deneyimi sunmuyor.

## Yapılacaklar

- Harita paketi seç: **`flutter_map` + OpenStreetMap tile'ları önerilir**
  (Google Maps API key/billing kurulumu gerektirmez, `pubspec.yaml`'a yeni
  bağımlılık eklenecek). Ekip zaten Google Maps kullanıyorsa onun yerine
  `google_maps_flutter` kullan — proje genelinde tutarlılığı kontrol et.
- Yeni ekran: `lib/features/discovery/presentation/region_map_screen.dart`
  (veya benzeri). Ana ekrana ya da Bölgeler ekranına bir "Harita" sekmesi/
  buton olarak bağla.
- Her turizm bölgesi için sabit bir merkez koordinat kullan (bölge taxonomy
  dosyasına 014 tarafından eklenmediyse burada ekle: `{regionId: LatLng}`).
- Bölge başına ilan sayısına göre büyüyen/renk değişen küme marker'ları çiz.
- Marker'a dokununca 014'ün oluşturduğu bölge-filtrelenmiş ilan ekranına git.
- Konum verisi olmayan ilanlar haritada gösterilmez ama metin aramada/feed'de
  görünmeye devam eder (arama tarafını bozma).

## User Stories

- Bir iş arayan olarak, otel işlerini haritada görmek istiyorum ki coğrafi
  dağılımı hızlıca kavrayabileyim.

## Acceptance Criteria

- [ ] Harita ekranı Türkiye'yi gösteriyor, 10 bölge için kümelenmiş marker var
- [ ] Marker büyüklüğü/etiketi o bölgedeki aktif ilan sayısını yansıtıyor
- [ ] Marker'a dokununca ilgili bölgenin ilan listesi açılıyor
- [ ] Harita ekranına ana ekrandan/Bölgeler ekranından ulaşılabiliyor
- [ ] Konumsuz ilanlar feed'den/aramadan düşmüyor, sadece haritada görünmüyor
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor

## Bağımlılıklar

- **014 (Bölge Modeli & Keşif Ekranı)** — önce merge edilmiş olmalı.

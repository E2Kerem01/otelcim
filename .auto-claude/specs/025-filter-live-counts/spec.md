# Filtre Seçeneklerinde Canlı Sonuç Sayısı

Sahibinden.com analizinden çıkan, doğrudan bugün canlıda yaşadığımız bir
soruna çözüm: kullanıcı bölge/sezon filtresi seçtiğinde hiçbir uyarı
olmadan "0 sonuç" ile karşılaşıyor. Sahibinden her filtre seçeneğinin
yanında "İstanbul (1.234)" gibi canlı eşleşme sayısı gösteriyor —
kullanıcı seçmeden önce kaç sonuç çıkacağını görüyor.

## Açıklama

`home_screen.dart` içindeki "Gelişmiş filtreler" sheet'inde (`_FilterSheet`)
**Turizm bölgesi** ve **Sezon** dropdown'larının her seçeneğinin yanına,
o seçenek uygulandığında kaç aktif ilan çıkacağını gösteren bir sayı ekle
(örn. "Antalya (0)", "Yaz 2025 (3)").

## Rationale

Bugün canlıda region/season filtrelerini test ederken hiçbir mevcut
ilanda bu alanlar dolu olmadığı için "0 sonuç" ile karşılaştık — filtre
kodu doğru çalışıyordu ama kullanıcı deneyimi olarak sessiz ve kafa
karıştırıcıydı. Sahibinden'in "seçenek yanında sayı" deseni, kullanıcının
boşa filtre uygulamasını engelliyor ve şeffaflık sağlıyor.

## Yapılacaklar

- **ÖNEMLİ — performans:** Sayıları hesaplarken TÜM ilanları çekip
  Dart'ta saymak YASAK (mevcut `watchActiveListings()` zaten bu
  anti-pattern'i kullanıyor ve TECH-002 olarak takip ediliyor — bunu
  daha da kötüleştirme). Bunun yerine Firestore'un **aggregate count()
  sorgusunu** kullan:
  ```dart
  final count = await FirebaseFirestore.instance
      .collection('listings')
      .where('status', isEqualTo: 'active')
      .where('region', isEqualTo: regionId) // veya 'season'
      .count()
      .get();
  ```
  Bu, doküman indirmeden sadece sayıyı döndürür, ucuzdur.
- `lib/shared/services/listing_service.dart` içine yeni bir metot ekle,
  örn. `Future<int> countActiveListings({String? region, String? season})`
  — `count()` aggregate query kullanarak.
- `_FilterSheet` açıldığında (veya bölge/sezon dropdown'ı ilk render
  olduğunda), her seçenek için bu sayıyı paralel olarak (`Future.wait`)
  çek ve dropdown item'larının yanında `(N)` formatında göster. Sayı
  yüklenene kadar seçenek metni sayı olmadan görünsün (loading state
  için ekstra spinner şart değil, sadece sayı geç gelsin).
- 10 bölge + 3 sezon seçeneği için toplam 13 count sorgusu bir defada
  atılacak — makul bir sayı, endişelenme.
- Gerekiyorsa `firestore.indexes.json`'a count sorgusu için ek composite
  index gerekmiyor (tekil equality + count() genelde tek alan index'i
  yeterli, `status`+`region` ve `status`+`season` için ayrı index'ler
  gerekebilir — `flutter test`/canlı denemede Firestore "index gerekli"
  hatası verirse hata mesajındaki linkten index'i `firestore.indexes.json`'a
  ekle).
- Kapsam: sadece **Turizm bölgesi** ve **Sezon** dropdown'ları. Şehir,
  çalışma tipi gibi diğer filtrelere sayı ekleme — bu spec'in kapsamı
  dışında, ayrı bir iş olabilir.

## User Stories

- Bir iş arayan olarak, bir bölge veya sezon seçmeden önce o seçimde kaç
  ilan olduğunu görmek istiyorum ki boşa filtre uygulamayayım.

## Acceptance Criteria

- [ ] `listing_service.dart`'a `count()` aggregate query kullanan bir
      sayım metodu eklendi (client-side tam liste taraması YOK)
- [ ] Turizm bölgesi dropdown'ında her bölgenin yanında aktif ilan
      sayısı görünüyor
- [ ] Sezon dropdown'ında her sezonun yanında aktif ilan sayısı görünüyor
- [ ] Sayı 0 olan bir seçenek seçilebilir durumda kalıyor (engellenmiyor,
      sadece bilgilendiriyor)
- [ ] Sayılar yüklenirken UI donmuyor / hata vermiyor
- [ ] `flutter test` geçiyor, sayım metodu için unit test eklendi
      (fake_cloud_firestore count() destekliyor mu kontrol et, desteklemiyorsa
      servis metodunu mock'layarak test et)

## Bağımlılıklar

- `lib/features/discovery/domain/tourism_region.dart` (bölge listesi) ve
  `lib/shared/constants/listing_filters.dart` (`ListingSeason` enum) —
  ikisi de zaten mevcut, üzerine inşa edilecek.
- 023 ve 024 ile dosya çakışması yok (onlar detay ekranına dokunuyor, bu
  home_screen.dart'ın filtre sheet'ine ve listing_service.dart'a
  dokunuyor — listing_service.dart'a sadece YENİ bir metot ekleniyor,
  var olan metotlara dokunulmuyor, düşük çakışma riski).

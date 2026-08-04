# Toplu İlan Girişi (Batch Listing Creation)

`feature-15` (Seasonal Hiring Mode) kapsamının parçası. Diğer sezonluk
spec'lerden (017, 019) bağımsız çalışılabilir — yeni, izole bir ekran.

## Açıklama

Otel işverenlerinin tek bir akışta birden fazla pozisyonu (aynı otel
bilgileriyle) tek seferde yayınlayabilmesi. Örn. bir otel yaz sezonu öncesi
aynı anda 10 farklı departmana ilan açmak istediğinde tek tek form
doldurmak yerine tek akışta hepsini girer.

## Rationale

Oteller sezon öncesi onlarca pozisyonu doldurmak zorunda. Toplu ilan girişi,
işverenlerin tek tek ilan girmek için harcadığı zamanı ciddi şekilde
azaltır. Bu, mevcut tekli ilan oluşturma akışının üstüne eklenen ayrı bir
giriş noktasıdır — mevcut `create_listing_screen.dart` akışını bozma.

## Yapılacaklar

- Yeni ekran: "Toplu İlan Ver" (örn.
  `lib/features/listings/presentation/batch_create_listing_screen.dart`).
  Mevcut ilan oluşturma ekranından ayrı bir giriş noktası (My Listings veya
  İlan Ver ekranında bir "Toplu Giriş" seçeneği/butonu olarak eriştir).
- Akış: önce paylaşılan otel bilgilerini (otel adı, adres/şehir, fotoğraflar,
  iletişim bilgisi) bir kez gir; sonra her pozisyon için satır satır
  kategori, başlık, maaş, çalışma tipi gir (ekle/sil yapılabilen dinamik
  liste).
- "Yayınla" dendiğinde her satır, mevcut `Listing` modeliyle ayrı bir
  Firestore dokümanı olarak oluşturulur (paylaşılan otel bilgileri her
  dokümana kopyalanır — ayrı bir "otel" koleksiyonu icat etme, mevcut
  `Listing` şemasını kullan).
- Firestore'a yazarken batch write (`WriteBatch`) kullan, tek tek
  `add()` çağırma — atomiklik ve performans için.
- 017 merge edildiyse (sezon alanı varsa), her satıra opsiyonel sezon
  seçici de ekle; henüz merge edilmediyse bu alanı atla, ayrı bir küçük
  takip PR'ı ile eklenir.

## User Stories

- Bir otel işvereni olarak, sezon öncesi 10 pozisyonu tek seferde
  yayınlamak istiyorum ki zaman kaybetmeyeyim.

## Acceptance Criteria

- [ ] "Toplu İlan Ver" ekranına mevcut ilan yönetimi akışından ulaşılabiliyor
- [ ] Paylaşılan otel bilgileri bir kez giriliyor, pozisyon satırları
      dinamik olarak eklenip çıkarılabiliyor
- [ ] En az 1, en fazla makul bir üst sınır (örn. 20) pozisyon girilebiliyor
- [ ] Yayınlama tek bir Firestore batch write ile atomik şekilde yapılıyor
- [ ] Yayınlanan her ilan, tekli oluşturulan ilanla aynı şekilde feed'de
      görünüyor (mevcut model/şemayı bozmuyor)
- [ ] Yarım bırakılan/hatalı satırlar varsa kullanıcı uyarılıyor, hiçbir
      şey yayınlanmıyor (hepsi ya da hiçbiri)
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, batch oluşturma mantığı için unit test var

## Bağımlılıklar

- Yok (diğer sezonluk spec'lerden bağımsız, düşük çakışma riski).

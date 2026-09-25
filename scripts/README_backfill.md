# Search keyword backfill

`backfill_search_keywords.mjs`, uygulamadaki
`lib/shared/utils/search_keywords.dart` algoritmasını Node tarafında birebir
uygulayarak `user_profiles` ve `listings` belgelerindeki `searchKeywords`
alanlarını tamamlar.

Betik varsayılan olarak dry-run çalışır: kaç belgenin değişeceğini gösterir,
Firestore'a yazmaz. Algoritma eşleşmesini kontrol etmek için önce:

```text
node scripts/backfill_search_keywords.mjs --self-test
```

Önce Firestore Emulator Suite üzerinde deneyin. Emulator çalışırken proje
kökünde:

```text
firebase emulators:start --only firestore
```

Başka bir terminalde Windows PowerShell:

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:GCLOUD_PROJECT = 'otelcim'
node scripts/backfill_search_keywords.mjs
node scripts/backfill_search_keywords.mjs --apply
```

Canlı Firestore için `firebase-admin` servis hesabı kimlik bilgilerini
`GOOGLE_APPLICATION_CREDENTIALS` ile gösterin. `functions/node_modules` altında
bağımlılıkların kurulu olduğundan emin olun (`cd functions; npm ci`). Önce
dry-run çıktısını inceleyin, ardından aynı ortam değişkenleriyle `--apply`
çalıştırın:

```text
node scripts/backfill_search_keywords.mjs
node scripts/backfill_search_keywords.mjs --apply
```

`--apply`, yazma işlemlerini Firestore'un 400 belge batch sınırının altında
parçalara böler. Arama alanları şunlardır: kullanıcılar için ad, e-posta, otel
adı ve telefon; ilanlar için başlık, ilan sahibi, şehir, konum ve bölge.

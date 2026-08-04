# Genel Kurallar (Tüm İşçiler İçin)

Bu doküman, bu klasördeki (014-021) görev tariflerinden herhangi birini alan
her AI işçisi için geçerlidir. Kendi spec dosyanı okumadan önce bunu oku.

## 1. Repo & Branch

- Repo: `https://github.com/E2Kerem01/otelcim.git`
- Base branch: `master`
- Kendi branch'ini `auto-claude/0NN-kisa-isim` formatında aç (spec klasör
  numaranla eşleşsin, örn. spec `014-...` ise branch `auto-claude/014-...`).
- İş bitince `master`'a PR aç. Kendi kendine merge etme — review bekle.
- PR açıklamasına hangi spec dosyasını uyguladığını yaz (`.auto-claude/specs/0NN-.../spec.md`).

## 2. Kapsam Disiplini

- **Sadece kendi spec'indeki Acceptance Criteria'yı uygula.** Alakasız
  refactor, lint temizliği, bağımsız bug fix yapma — ayrı bir iş.
- Ortak dosyalara (`listing_model.dart`, arama/filtre paneli, `home_screen.dart`
  gibi) sadece spec'inde açıkça istenen alanı ekle; o dosyadaki alakasız kodu
  değiştirme. Aşağıda "Dosya Çakışma Uyarıları" bölümüne bak.
- Var olan alanları (`city`, `location`, `salary`, `category`, `employmentType`
  — `lib/features/listings/domain/listing_model.dart`) tekrar icat etme, üzerine inşa et.

## 3. Teknoloji ve Konvansiyonlar

- Flutter/Dart, state yönetimi Riverpod, routing GoRouter, Firebase (Auth,
  Firestore, Storage, Cloud Functions, FCM), Material 3.
- Yeni özellik klasörleri `lib/features/<feature_adi>/{domain,services,presentation}`
  şeklinde, mevcut feature'lardaki (`favorites`, `ratings`, `boosts` vb.) yapıyı örnek al.
- Harici paket eklemeden önce `pubspec.yaml`'da zaten var mı kontrol et.

## 4. Lokalizasyon (ZORUNLU)

- Tüm kullanıcıya görünen metinler `lib/l10n/app_tr.arb` VE `lib/l10n/app_en.arb`
  dosyalarına eklenmeli (proje `intl`/ARB tabanlı localization kullanıyor,
  şablon dosya `app_tr.arb`). Hardcoded Türkçe string ekleme.

## 5. Firestore Şeması

- Modele/koleksiyona yeni alan eklersen, `toMap()`/`fromMap()` (veya
  `fromFirestore`) ikisini birden güncelle.
- Yeni compound query yazıyorsan gerekli composite index'i
  `firestore.indexes.json` dosyasına ekle (bkz. proje geçmişinde
  "declare required composite indexes as code" commit'i — index'ler kod
  olarak takip ediliyor, konsoldan elle eklenmiyor).

## 6. Test & CI

- PR açmadan önce lokal olarak `flutter test` çalıştır ve geçtiğinden emin ol
  (CI'da `pr_checks.yml` zaten bunu zorunlu tutuyor, ayrıca `flutter build web`
  derleme kontrolü de var).
- Yeni iş mantığı (servis, model parsing, filtreleme vb.) için unit test ekle.

## 7. Güvenlik

- Firebase API key, service account JSON, `.env` içeriği gibi hiçbir secret'ı
  commit etme.
- Kullanıcı konumu (GPS) veya kişisel veri toplayan her akışta izin/rıza akışı
  olmadan veri toplama.

## 8. Dosya Çakışma Uyarıları (spec'ler arası)

- **014, 015, 016** (turizm bölgesi/harita/GPS) üçü de `listing_model.dart`'a
  dokunabilir (`region`, sonra `lat`/`lng`). **014 önce merge edilmeli**,
  015/016 onun eklediği alan adlarını (`region`) baz alsın.
- **017, 018, 019** (sezonluk) içinde **017 önce merge edilmeli** (season
  alanını o ekliyor); 019 filtre panelini güncellerken 017'nin eklediği
  `season` alanını kullanır.
- 018 (toplu ilan girişi) diğerlerinden bağımsız, yeni bir ekran — çakışma riski düşük.
- Kendi PR'ını açmadan hemen önce `master`'ı rebase/merge et, çakışmayı erken gör.

## 9. Commit/PR Mesaj Stili

- Kısa, açıklayıcı, `feat(alan): ne yapıldığı` formatı (repodaki geçmiş
  commit'lere bak, örn. `feat(chat): add message template selection bottom sheet`).
- Gövdede "neden" yaz, "ne" değil (kod zaten neyi gösteriyor).

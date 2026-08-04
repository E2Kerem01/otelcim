# Genel Kurallar (Tüm İşçiler İçin) — v2

Bu doküman, bu klasördeki (030-037) görev tariflerinden herhangi birini
alan her AI işçisi için geçerlidir. Kendi spec dosyanı okumadan önce bunu
oku. **Bu, önceki turda yaşanan gerçek sorunlara göre güçlendirilmiş bir
sürüm** — aşağıdaki her kural, bugün gerçekten olmuş bir hatayı önlemek
için var.

## 0. KRİTİK: Git Komutlarını Sen Çalıştırma — Hepimiz Aynı Klasörü Paylaşıyoruz

**Tüm işçiler aynı local çalışma dizinini (aynı checkout'u) paylaşıyor.**
Önceki turda bir işçi bu kurala rağmen `git commit` çalıştırdı ve bu,
branch'in karışmasına, başka bir işçinin işinin yanlış yere gitmesine yol
açtı. Bu yüzden:

- `git checkout`, `git branch`, `git add`, `git commit`, `git push`,
  `git pull`, `git merge`, `git reset`, `git stash` — **HİÇBİRİNİ**
  çalıştırma. İstisna yok, "hızlı bir commit" de dahil.
- Kod değişikliklerini normal şekilde dosyalara yaz (Write/Edit).
- Çalışma dizininde spec'inle ilgisi olmayan dosyalar (başka bir işçinin
  bitmemiş işi) görürsen **dokunma, silme, değiştirme** — sadece
  görmezden gel.
- Git durumu (branch, uncommitted değişiklikler) kafanı karıştırıyorsa
  hiçbir şeyi düzeltmeye çalışma, koordinatöre sor.

## 1. KRİTİK: "Bitti" Demeden Önce Kendi İşini Denetle

**Önceki turda birden fazla işçi, aslında diskte olmayan bir dosyayı
"oluşturdum" dedi, ya da test dosyası yazmadığı halde "test eklendi ve
geçti" dedi.** Koordinatör bunu grep ile yakaladı ama bu güven kaybına ve
zaman kaybına yol açtı. Bu yüzden "tamamlandı" bildirimi göndermeden
önce ZORUNLU:

1. Oluşturduğunu/değiştirdiğini iddia ettiğin HER dosyayı tekrar oku
   (Read tool ile) ve içeriğin gerçekten orada olduğunu doğrula.
2. Route/wiring eklediğini iddia ediyorsan (örn. router.dart'a route,
   bir ekrana buton), o satırın gerçekten dosyada olduğunu grep'le
   kontrol et — "eklemeyi planladım" ile "gerçekten ekledim" arasındaki
   farkı kapat.
3. Test eklediğini iddia ediyorsan, test dosyasının diskte var olduğunu
   ve içinde iddia ettiğin senaryoların gerçekten yazılı olduğunu
   doğrula.
4. `flutter test`/`flutter analyze` çalıştıramıyorsan (SDK yok vb.), bunu
   AÇIKÇA söyle — "test geçti" deme, "test çalıştıramadım, kod
   göz muayenesiyle doğru" de. Yanlış "test geçti" iddiası, doğru
   olmayan bir iddiadan daha kötü çünkü koordinatörün güvenini kırıyor.

## 2. Kapsam Disiplini

- **Sadece kendi spec'indeki Acceptance Criteria'yı uygula.** Alakasız
  refactor, lint temizliği, bağımsız bug fix yapma.
- Paylaşılan dosyalara (bkz. her spec'in "Dosya Çakışma Uyarısı" bölümü)
  sadece spec'inde açıkça istenen kodu ekle; başka bir işçinin
  eklediğini fark ettiğin kodu SİLME veya "temizleme" adı altında
  değiştirme.
- Var olan alanları/enum'ları (`ExperienceLevel`, `EducationLevel`,
  `region`, `season` — `lib/features/listings/domain/listing_model.dart`,
  `lib/shared/constants/listing_filters.dart`) tekrar icat etme, üzerine
  inşa et.

## 3. Teknoloji ve Konvansiyonlar

- Flutter/Dart, Riverpod, GoRouter, Firebase (Auth, Firestore, Storage,
  Cloud Functions, FCM), Material 3.
- Yeni özellik klasörleri `lib/features/<ad>/{domain,services,presentation}`.
- Yeni paket eklemeden önce `pubspec.yaml`'da zaten var mı kontrol et.

## 4. Lokalizasyon (ZORUNLU)

Tüm kullanıcıya görünen metinler `lib/l10n/app_tr.arb` VE
`lib/l10n/app_en.arb`'a eklenmeli. Hardcoded string ekleme.

## 5. Firestore Şeması

- Yeni alan eklersen `toMap()`/`fromDoc()`/`fromFirestore()` ikisini
  birden güncelle.
- Yeni compound query yazıyorsan gerekli composite index'i
  `firestore.indexes.json`'a ekle.
- Yeni bir koleksiyon açıyorsan (bu turda birkaç spec yeni koleksiyon
  açıyor), `firestore.rules`'a KENDİN dokunma — mevcut kural dosyası
  bilinçli bir güvenlik tasarımı, koordinatör senin koleksiyonun için
  gereken kuralı ayrıca ekleyecek. Spec'inde bunu not düş, kodu yaz ama
  rules dosyasını değiştirme.

## 6. Test & CI

- `flutter test` lokal olarak geçtiğinden emin ol (geçemiyorsan §1.4'e bak).
- Yeni iş mantığı için unit test ekle.

## 7. Güvenlik

- Firebase API key, service account JSON, `.env` içeriği gibi hiçbir
  secret'ı commit etme (zaten commit atmıyorsun ama koda da yazma).
- Kullanıcı konumu/kişisel veri toplayan akışlarda izin/rıza olmadan veri
  toplama.

## 8. Bildirim Formatı

İşin bitince koordinatöre şunu bildir:
```
[İşçi X] — spec 0NN tamamlandı. §1'deki kendi-denetim adımlarını
uyguladım: [oluşturduğun/değiştirdiğin dosyaları tek tek Read ile
doğruladığını, test durumunu (geçti/çalıştıramadım) açıkça belirt].
Commit/push talimatını bekliyorum.
```

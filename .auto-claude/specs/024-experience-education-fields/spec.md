# Deneyim & Eğitim Durumu Alanları

Sahibinden.com analizinden çıkan bir bulgu: rakip ilan detaylarında
"Deneyim" ve "Eğitim Durumu" gibi yapılandırılmış alanlar var, Otelcim'de
yok. Bu alanları `Listing` modeline, ilan formuna ve detay ekranına ekle.

## Açıklama

İşverenlerin ilan oluştururken opsiyonel olarak minimum deneyim
("Deneyim Aranmıyor" / "1 Yıldan Az" / "1-3 Yıl" / "3+ Yıl") ve eğitim
seviyesi ("Eğitim Şartı Yok" / "En Az İlköğretim" / "En Az Lise" / "En
Az Üniversite") belirtebilmesi. Bu, iş arayanların kendilerine uygun
olmayan ilanları hızlıca elemesini sağlar.

## Rationale

Otel/turizm sektöründe deneyim ve eğitim beklentisi pozisyona göre çok
değişir (örn. resepsiyon için dil/deneyim şartı ağır, kat hizmetleri
için hafif). Bu alanların eksikliği hem işveren tarafında (uygun olmayan
adaylardan mesaj alma) hem iş arayan tarafında (uygun olmayan ilanlara
zaman harcama) sürtünme yaratıyor. Sahibinden'de bu alanlar zaten var ve
kullanıcılar bekliyor olabilir.

## Yapılacaklar

- `lib/shared/constants/listing_filters.dart` (veya benzeri uygun bir
  constants dosyası) içine iki yeni enum ekle:
  - `enum ExperienceLevel { none, underOneYear, oneToThreeYears, threePlusYears }`
    ile Türkçe `label` getter'ı ("Deneyim Aranmıyor", "1 Yıldan Az",
    "1-3 Yıl", "3+ Yıl").
  - `enum EducationLevel { none, primary, highSchool, university }` ile
    Türkçe `label` getter'ı ("Eğitim Şartı Yok", "En Az İlköğretim",
    "En Az Lise", "En Az Üniversite").
- `lib/features/listings/domain/listing_model.dart`'a `experienceLevel`
  (String?) ve `educationLevel` (String?) alanları ekle — nullable,
  `toMap()`/`fromDoc()` güncelle. Eski ilanlarla geriye dönük uyumlu olsun.
- `create_listing_screen.dart` ve `edit_listing_screen.dart`'a bu iki
  alan için opsiyonel dropdown seçici ekle (zorunlu değil, boş
  bırakılabilir).
- `listing_detail_screen.dart`'ta, mevcut bilgi satırlarının
  (kategori/konum/maaş gibi) yanına Deneyim ve Eğitim Durumu satırlarını
  ekle — sadece değer varsa göster, boşsa satırı gizle.
- Bu iki alanı search/filter panosuna EKLEME — kapsam dışı, sadece
  görüntüleme ve girişe odaklan (filtreleme ayrı bir iş olabilir).

## User Stories

- Bir işveren olarak, ilanıma minimum deneyim ve eğitim beklentimi
  eklemek istiyorum ki uygun olmayan adaylardan gereksiz mesaj almayayım.
- Bir iş arayan olarak, bir ilanın deneyim/eğitim şartını görüp kendime
  uygun olup olmadığına hızlıca karar vermek istiyorum.

## Acceptance Criteria

- [ ] `ExperienceLevel` ve `EducationLevel` enum'ları tanımlı, Türkçe
      label'ları var
- [ ] `Listing` modelinde `experienceLevel`/`educationLevel` alanları
      var, mevcut ilanlarla geriye dönük uyumlu (null-safe)
- [ ] Oluşturma/düzenleme formunda iki alan da opsiyonel dropdown olarak
      seçilebiliyor
- [ ] İlan detay ekranında değer varsa gösteriliyor, yoksa satır
      görünmüyor (regresyon yok)
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, model için unit test eklendi

## Bağımlılıklar

- 023 ile dosya çakışması yok (o sadece detay ekranındaki iletişim
  bölümüne dokunuyor, bu ise bilgi satırlarına — farklı bölgeler).
- 025, bu spec'in eklediği alanları filtrelemeye ÇEVİRMİYOR — kapsam
  dışı bırakıldı, o yüzden 025 ile de çakışma riski düşük.

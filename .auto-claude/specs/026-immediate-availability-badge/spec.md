# "Hemen Başlayabilir" Anlık Müsaitlik Rozeti

Phase 5 ideation raporundan (`.auto-claude/ideation/phase5-market-research.md`,
Feature 5.12) MoSCoW "Must Have" olarak işaretlenmiş, düşük karmaşıklık /
yüksek etkili bir feature.

## Açıklama

İş arayan kullanıcıların profillerinde "Şu An Boşta / Hemen Başlayabilir"
rozetini aktif edebilmesi. Bu rozet, işverenin o kullanıcıyla olan
sohbette ve kullanıcının profilinde görünür.

## Rationale

Acil eleman ihtiyacı olan otel İK yöneticileri, pasif adaylar yerine o
gün çalışmaya hazır olanları önceliklendirmek ister. Otelcim'de şu an
işverenlerin aday profillerini tarayabildiği bir ekran yok (akış: işveren
ilan açar, iş arayan mesaj atar) — bu yüzden rozet, bir sohbet başladığında
işverenin göreceği yerlerde gösterilecek. Düşük efor, yüksek güven/hız
etkisi.

## Yapılacaklar

- `lib/shared/models/user_profile.dart`'a `availableImmediately` (bool,
  default `false`) alanı ekle. `toMap()`/`fromFirestore` (dosyadaki
  gerçek metot adına bak) güncelle.
- `lib/features/profile/presentation/edit_profile_screen.dart`'a **sadece
  `userType == 'jobseeker'` olan kullanıcılar için görünen** bir switch/
  toggle ekle: "Şu An Boşta / Hemen Başlayabilir". Employer profillerinde
  bu alan görünmesin.
- Rozet gösterimi:
  - `lib/features/chat/presentation/chat_detail_screen.dart` içinde,
    karşı taraf iş arayan ve `availableImmediately == true` ise sohbet
    başlığının/AppBar'ının yanında küçük bir rozet (örn. yeşil nokta +
    "Hemen Başlayabilir" chip) göster.
  - `lib/features/chat/presentation/chat_list_screen.dart` içindeki
    sohbet satırlarında da aynı rozeti (küçük ikon yeterli) göster.
  - Kullanıcının kendi profil ekranında (`profile_screen.dart`) da bu
    toggle'ın durumu görünür olsun.
- Rozeti nereden okuyacağını belirlerken: sohbet ekranları karşı
  tarafın `UserProfile`'ını zaten bir şekilde çekiyor olabilir (kontrol
  et); çekmiyorsa `user_profiles/{uid}` dokümanını okuyan hafif bir
  provider ekle (tüm koleksiyonu taramadan, tek doküman `get`/`watch`).

## User Stories

- Bir iş arayan olarak, hemen çalışmaya başlayabileceğimi işverene sohbet
  üzerinden belli etmek istiyorum.
- Bir otel işvereni olarak, sohbet ettiğim adayın hemen başlayıp
  başlayamayacağını hızlıca görmek istiyorum.

## Acceptance Criteria

- [ ] `UserProfile`'da `availableImmediately` alanı var, default `false`,
      geriye dönük uyumlu
- [ ] Profil düzenleme ekranında SADECE iş arayan kullanıcılar için
      toggle görünüyor, işveren profillerinde yok
- [ ] Sohbet detay ekranında ve sohbet listesinde, iş arayan karşı taraf
      bu ayarı açtıysa rozet görünüyor
- [ ] Rozet tek bir dokümanı okuyarak geliyor (koleksiyon taraması yok)
- [ ] Yeni metinler `app_tr.arb`/`app_en.arb`'a eklendi
- [ ] `flutter test` geçiyor, model için unit test eklendi

## Bağımlılıklar

- Diğer aktif spec'lerle (023, 024, 025) dosya çakışması yok — bu spec
  `user_profile.dart`, `edit_profile_screen.dart`, `chat_detail_screen.dart`,
  `chat_list_screen.dart`, `profile_screen.dart` dosyalarına dokunuyor,
  diğerleri `listing_detail_screen.dart`, `listing_model.dart`,
  `home_screen.dart`/`listing_service.dart`'a dokunuyor.

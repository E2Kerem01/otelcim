# 15 Saniyelik Video Tanıtım Profili

Roadmap `feature-26` (phase-5). Ideation raporu Feature 5.5.

## Açıklama

İş arayanların profillerine kısa (15-30 saniye) bir tanıtım videosu
yükleyebilmesi.

## Yapılacaklar

- `lib/shared/models/user_profile.dart`'a `introVideoUrl` (String?) alanı
  ekle.
- `pubspec.yaml`'a video seçimi için `image_picker`'ın video desteğini
  kullan (`ImagePicker().pickVideo(...)`, zaten `image_picker` pubspec'te
  var, ek paket gerekmeyebilir). Video oynatma için `video_player` paketi
  gerekebilir — yoksa ekle.
- `edit_profile_screen.dart`/`profile_form.dart`'a (SADECE iş arayanlar
  için, `026`'daki `_isEmployer` deseni gibi) video yükleme alanı ekle.
  Süre sınırı (max 30sn) client-side kontrol edilsin (mümkünse
  `pickVideo`'nun `maxDuration` parametresiyle).
  - Video Firebase Storage'a `user_videos/{userId}/intro.mp4` altında
    yüklensin.
- `profile_screen.dart` ve sohbet ekranlarında (chat_detail_screen.dart)
  video varsa küçük bir "Tanıtım Videosunu İzle" butonu/thumbnail
  göster, tıklanınca `video_player` ile oynat.

## Acceptance Criteria

- [ ] Video yükleme SADECE iş arayan profillerinde görünüyor
- [ ] Süre/boyut sınırı uygulanıyor
- [ ] Video profil ve sohbet ekranında oynatılabiliyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`user_profile.dart`, `edit_profile_screen.dart`, `profile_form.dart`,
`chat_detail_screen.dart` — bu dosyalara **031, 036, 037** de dokunabilir.
Sadece kendi eklemen gereken satırları ekle, mevcut kodu değiştirme.

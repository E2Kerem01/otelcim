# Sezon Dışı Yetenek Havuzu

Roadmap `feature-29` (phase-5). Ideation raporu Feature 5.9. Mevcut
sezonluk altyapı (`feature-15`, tamamlandı) ve favoriler (`feature-8`,
tamamlandı) üzerine kurulu.

## Açıklama

İşverenlerin, sohbet ettiği/işe aldığı adayları "Yetenek Havuzu"na
ekleyip gelecek sezon için not tutabilmesi.

## Yapılacaklar

- Yeni Firestore subcollection: `user_profiles/{employerId}/talent_pool/
  {candidateId}` (alanlar: `candidateId`, `candidateName`, `note`?,
  `addedAt`, `conversationId`?).
- `chat_detail_screen.dart`'a (işveren için) AppBar menüsünde/overflow'da
  "Yetenek Havuzuna Ekle" seçeneği ekle, opsiyonel bir not girme dialogu
  göster.
- Yeni ekran: `lib/features/profile/presentation/talent_pool_screen.dart`
  — işverenin havuzundaki adayları listele (isim, not, eklenme tarihi),
  her adaya "Sohbete Dön" butonu (mevcut `conversationId`'ye git).
- `profile_screen.dart`'a (sadece işveren için) "Yetenek Havuzum" giriş
  noktası + router'a `/profile/talent-pool` route'u ekle.

## Acceptance Criteria

- [ ] İşveren bir sohbetten adayı havuza ekleyebiliyor (opsiyonel notla)
- [ ] Yetenek Havuzu ekranı eklenen adayları listeliyor
- [ ] Sadece işveren kullanıcılar bu özelliği görüyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`chat_detail_screen.dart`'a **034, 036** da dokunabilir — sadece kendi
menü öğeni ekle. `profile_screen.dart`'a **031** de dokunuyor (belge
rozeti) — additive, dikkatli birleştirin.

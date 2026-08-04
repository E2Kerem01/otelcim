# Turizm Sertifika & Hijyen Belgesi Doğrulama Cüzdanı

Roadmap `feature-23` (phase-5). Ideation raporu Feature 5.2.

## Açıklama

İş arayanların hijyen belgesi, cankurtaran sertifikası, ehliyet, dil
belgesi gibi dokümanları profillerine yükleyip admin onayıyla doğrulama
rozeti alması.

## Yapılacaklar

- Yeni Firestore koleksiyonu: `certificates` (alanlar: `id`, `userId`,
  `type` — hijyen/cankurtaran/ehliyet/dil/diger, `fileUrl`, `status` —
  pending/approved/rejected, `createdAt`). Belgeleri Firebase Storage'da
  `certificates/{userId}/{certId}` altında sakla (kısıtlı erişim).
- Yeni ekran: `lib/features/profile/presentation/certificates_screen.dart`
  — "Belgelerim" listesi + yükleme akışı (`image_picker`/`file_picker`
  zaten pubspec'te var).
- Yeni servis: `lib/features/profile/services/certificate_service.dart`.
- Admin tarafı: mevcut `lib/features/admin/` altındaki doğrulama
  ekranlarının (`verification_review_screen.dart`) desenini örnek alan
  yeni bir "Belge Doğrulama Kuyruğu" admin ekranı.
- Onaylanmış belgeler kullanıcının profilinde küçük bir rozet olarak
  görünsün (`profile_screen.dart`'a ekle).
- Router'a `/profile/certificates` ve admin için `/admin/certificates`
  route'ları ekle.

## Acceptance Criteria

- [ ] `certificates` koleksiyonu + servis + yükleme ekranı çalışıyor
- [ ] Admin kuyruğunda onay/red işlemi yapılabiliyor
- [ ] Onaylı belgeler profilde rozet olarak görünüyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

Kendi yeni dosyalarına ve `profile_screen.dart`/`router.dart`'a dokunuyor
— `router.dart`'a başka spec de ekleme yapabilir (032, 034, 035, 036),
sadece kendi route'unu ekle, mevcut route'lara dokunma.

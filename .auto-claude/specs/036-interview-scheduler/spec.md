# Uygulama İçi Mülakat Planlayıcı

Roadmap `feature-28` (phase-5). Ideation raporu Feature 5.7.

## Açıklama

Sohbet ekranında işverenin mülakat zaman aralıkları önerebilmesi, adayın
tek tıkla seçip her iki tarafın FCM hatırlatma bildirimi alması.

## Yapılacaklar

- Yeni Firestore subcollection: `conversations/{id}/interview_slots`
  (alanlar: `proposedBy`, `slots`: List<Timestamp>, `selectedSlot`:
  Timestamp?, `status`: pending/confirmed).
- `chat_detail_screen.dart`'a (işveren için) "Mülakat Saati Öner" butonu
  ve basit bir tarih/saat seçici (2-3 slot önerisi) ekle.
- Aday tarafında, önerilen slotlar bir kart olarak görünsün, birini
  seçince `selectedSlot`/`status: confirmed` güncellensin.
- `functions/src/index.ts`'e, `selectedSlot` alanı set edildiğinde
  (`onDocumentUpdated`) her iki tarafa "Mülakat Onaylandı" FCM bildirimi
  gönderen bir fonksiyon ekle. Slot zamanından ~1 saat önce hatırlatma
  göndermek için ayrı bir scheduled function (Cloud Scheduler + Functions)
  gerekiyorsa, bunu MVP kapsamı dışına al — sadece "onay anında" bildirim
  yeterli, kapsamı büyütme.

## Acceptance Criteria

- [ ] İşveren sohbette 2-3 mülakat zaman önerisi sunabiliyor
- [ ] Aday bir slot seçebiliyor, seçim her iki tarafta görünüyor
- [ ] Onay anında her iki tarafa FCM bildirimi gidiyor
- [ ] `app_tr.arb`/`app_en.arb` güncellendi, `flutter test` geçiyor

## Dosya Çakışma Uyarısı

`chat_detail_screen.dart`'a **034, 037** de dokunabilir — sadece kendi
eklemen gereken UI parçasını ekle, mevcut sohbet mantığını değiştirme.
`functions/src/index.ts`'e sadece YENİ bir export ekle, var olanlara
dokunma.

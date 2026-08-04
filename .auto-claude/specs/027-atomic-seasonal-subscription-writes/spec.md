# Atomik Olmayan Sezon Aboneliği Yazmasını Düzelt

PR #22 review'inde bulunan, o zaman bloklayıcı olmadığı için takip işi
olarak bırakılan orta seviye bulgu.

## Açıklama

`lib/features/seasonal/services/seasonal_service.dart` içindeki
`addSubscription`, `toggleSubscription`, `deleteSubscription` metotları,
her biri kullanıcının alt koleksiyonuna (`user_profiles/{uid}/
seasonal_subscriptions/{id}`) VE üst seviye ayna koleksiyona
(`seasonal_subscriptions/{id}` — Cloud Function tetikleyicisi için) **iki
ayrı, birbirinden bağımsız** yazma işlemi yapıyor. Ağ hatası ilk
yazmadan sonra olursa iki koleksiyon senkron dışı kalır: kullanıcı
arayüzde "abone oldum" görür ama üst koleksiyona hiç yazılmadığı için
`sendSeasonalReminders` Cloud Function'ı hiç tetiklenmez — kullanıcı
sessizce hiç hatırlatma almaz.

## Rationale

Bu, sessiz bir veri bütünlüğü hatası — kullanıcıya hata göstermiyor ama
özelliği (sezonluk hatırlatma) arka planda bozuyor. `createBatchListings`
metodunda (spec 018) doğru yapılan `_db.batch()` deseni burada da
uygulanmalı.

## Yapılacaklar

- `lib/features/seasonal/services/seasonal_service.dart` içindeki üç
  metodu (`addSubscription`, `toggleSubscription`, `deleteSubscription`)
  `FirebaseFirestore.batch()` kullanacak şekilde yeniden yaz:
  ```dart
  Future<void> addSubscription({...}) async {
    final subDocRef = _db
        .collection('user_profiles')
        .doc(userId)
        .collection('seasonal_subscriptions')
        .doc(); // önce ID üret
    final mirrorDocRef = _db.collection('seasonal_subscriptions').doc(subDocRef.id);
    final batch = _db.batch();
    batch.set(subDocRef, subData);
    batch.set(mirrorDocRef, {...subData, 'subscriptionId': subDocRef.id});
    await batch.commit();
  }
  ```
  `toggleSubscription`/`deleteSubscription` için de aynı şekilde
  `batch.update(...)`/`batch.delete(...)` iki referansa birlikte
  uygulanıp `batch.commit()` ile tek seferde gönderilsin.
- Mevcut davranışı (alan adları, `subscriptionId` mirror dokümanına
  eklenmesi vb.) değiştirme — sadece atomikleştir.
- `test/features/seasonal/seasonal_filter_test.dart` içine (veya yeni
  bir test dosyasına) `FakeFirebaseFirestore` ile: abonelik
  eklendiğinde HER İKİ koleksiyonda da doğru veri olduğunu doğrulayan
  bir test ekle.

## Acceptance Criteria

- [ ] Üç metot da tek bir `WriteBatch.commit()` çağrısıyla her iki
      koleksiyona da yazıyor/güncelliyor/siliyor
- [ ] Var olan davranış (alan adları, `subscriptionId` mirror alanı)
      değişmedi
- [ ] Unit test: abonelik ekleme/güncelleme/silme sonrası her iki
      koleksiyonun da tutarlı olduğunu doğruluyor
- [ ] `flutter test` geçiyor

## Bağımlılıklar

Yok. Sadece `seasonal_service.dart`'a dokunuyor — 023-026 ve diğer
tech-debt spec'leriyle (028, 029) çakışma riski yok.

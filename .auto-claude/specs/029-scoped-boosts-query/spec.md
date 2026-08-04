# Boost Sorgularını Filtreli Hale Getir

028'in eşleniği — aynı anti-pattern `boost_service.dart`'ta da var.

## Açıklama

`lib/features/boosts/services/boost_service.dart` içindeki
`watchUserBoosts(String userId)` ve `watchUserBoostPurchases(String userId)`
metotları, sırasıyla `boosts` ve `boost_purchases` koleksiyonlarının
TAMAMINI çekip Dart tarafında `.where((b) => b.userId == userId)` ile
filtreliyor. Firestore'un kendi `.where()` sorgusuna taşı.

## Rationale

- **Maliyet:** Sistemdeki tüm kullanıcıların boost/satın alma kayıtları
  her kullanıcının cihazına indiriliyor.
- **Gizlilik:** `boost_purchases` bir ödeme kaydı — `firestore.rules`
  (PR #23) bu filtresiz sorgu yüzünden okuma iznini "herhangi bir giriş
  yapmış kullanıcı" seviyesinde bırakmak zorunda kaldı. Bu spec
  tamamlandıktan sonra kuralları sahibine özel (`resource.data.userId
  == request.auth.uid`) şeklinde sıkılaştırmak mümkün olur (ayrı takip
  işi, bu spec'in kapsamı değil).

## Yapılacaklar

- `watchUserBoosts`:
  ```dart
  Stream<List<Boost>> watchUserBoosts(String userId) {
    return _db
        .collection('boosts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(Boost.fromDoc).toList();
          list.sort((a, b) { /* mevcut sıralama mantığı aynı kalsın */ });
          return list;
        })
        .handleError((error) {
          debugPrint('Error watching user boosts: $error');
          return <Boost>[];
        });
  }
  ```
- `watchUserBoostPurchases` için aynı desen (`.where('userId',
  isEqualTo: userId)`), sıralama mantığı aynen korunacak.
- Client-side `.where((p) => p.userId == userId)` / `.where((b) =>
  b.userId == userId)` filtrelerini KALDIR.
- Firestore yeni composite index isteyebilir (örn. `userId` +
  `purchasedAt` sıralaması için) — hata mesajındaki linki takip edip
  `firestore.indexes.json`'a ekle.
- `firestore.rules`'a DOKUNMA — kapsam dışı.

## Acceptance Criteria

- [ ] `watchUserBoosts` ve `watchUserBoostPurchases` artık Firestore'da
      `userId` eşitliğiyle filtreleniyor, tüm koleksiyonu çekmiyor
- [ ] Sıralama davranışı öncekiyle aynı
- [ ] Gerekliyse yeni composite index(ler) `firestore.indexes.json`'a
      eklendi
- [ ] "Boostlarım" / satın alma geçmişi ekranları hatasız çalışıyor
      (regresyon yok)
- [ ] `flutter test` geçiyor, iki metot için de unit test var

## Bağımlılıklar

Yok. Sadece `lib/features/boosts/services/boost_service.dart`'a
dokunuyor — diğer aktif spec'lerle (023-028) dosya çakışması yok.

# Sohbet Listesi Sorgusunu Filtreli Hale Getir

Teknik denetimde (TECH-002) ve Firestore güvenlik kuralları PR'ında
(#23) işaretlenen bulgu: `watchConversations()` filtresiz sorgu
kullanıyor. Bunu düzeltmek hem maliyeti düşürür hem de gelecekte
`conversations` için katı ("sadece katılımcı okur") güvenlik kuralı
yazmanın önünü açar.

## Açıklama

`lib/shared/services/chat_service.dart` içindeki `watchConversations(String uid)`
metodu şu an **tüm** `conversations` koleksiyonunu dinleyip
(`_db.collection('conversations').snapshots()`) sonucu Dart tarafında
`c.posterId == uid || c.seekerId == uid` ile filtreliyor. Bunu
Firestore'un kendi sorgu filtresine taşı.

## Rationale

- **Maliyet:** Sistemdeki HERKESİN sohbetleri her kullanıcının cihazına
  indiriliyor, sadece kendi sohbetleri gösteriliyor. Kullanıcı/sohbet
  sayısı arttıkça bu okuma maliyeti orantısız büyür.
  - **Güvenlik:** `firestore.rules` (PR #23) şu an `conversations` okuma
  iznini "herhangi bir giriş yapmış kullanıcı" seviyesinde bırakmak
  zorunda kaldı çünkü bu filtresiz sorgu, kişiye özel bir kural
  konursa tamamen kırılırdı. Bu spec'i tamamladıktan sonra
  `firestore.rules`'daki `conversations`/`messages` bloklarını
  `resource.data.posterId == request.auth.uid || resource.data.seekerId == request.auth.uid`
  şeklinde sıkılaştırmak mümkün hale gelir (bu spec'in kapsamında
  DEĞİL, ayrı bir takip işi — sadece sorguyu düzelt).

## Yapılacaklar

- `cloud_firestore: ^6.7.1` sürümünde mevcut `Filter.or()` API'sini
  kullanarak sorguyu değiştir:
  ```dart
  Stream<List<Conversation>> watchConversations(String uid) {
    return _db
        .collection('conversations')
        .where(
          Filter.or(
            Filter('posterId', isEqualTo: uid),
            Filter('seekerId', isEqualTo: uid),
          ),
        )
        .snapshots()
        .map((snap) {
          final conversations = snap.docs.map(Conversation.fromDoc).toList();
          conversations.sort((a, b) { /* mevcut sıralama mantığı aynı kalsın */ });
          return conversations;
        })
        .handleError((error) {
          debugPrint('Firestore watchConversations warning: $error');
          return <Conversation>[];
        });
  }
  ```
  (Client-side `.where((c) => ...)` filtresini KALDIR, artık gereksiz.)
- Firestore bu sorgu için yeni bir composite index isteyebilir —
  `flutter test`/canlı denemede "index gerekli" hatası + link gelirse,
  o link'teki index tanımını `firestore.indexes.json`'a elle ekle
  (muhtemelen `posterId`/`seekerId` için ayrı ayrı tekil index'ler
  yeterli olur, `Filter.or` genelde her dala kendi index'ini kullanır).
- Sıralama mantığını (updatedAt/createdAt'a göre) aynen koru, sadece
  ön-filtreleme değişiyor.
- `firestore.rules`'a DOKUNMA — bu spec'in kapsamı sadece sorgu tarafı.

## Acceptance Criteria

- [ ] `watchConversations` artık Firestore'da `posterId`/`seekerId`
      eşitliğiyle filtreleniyor, tüm koleksiyonu çekmiyor
- [ ] Sıralama davranışı öncekiyle aynı
- [ ] Gerekliyse yeni composite index `firestore.indexes.json`'a eklendi
- [ ] Mevcut sohbet listesi/detay ekranları hatasız çalışıyor
      (regresyon yok)
- [ ] `flutter test` geçiyor, sorgu davranışı için unit test var
      (fake_cloud_firestore'un `Filter.or` desteğini kontrol et; test
      etmiyorsa iki ayrı senaryo testiyle davranışı doğrula)

## Bağımlılıklar

Yok. Sadece `lib/shared/services/chat_service.dart`'a dokunuyor —
diğer aktif spec'lerle (023-027, 029) dosya çakışması yok.

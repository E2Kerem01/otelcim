import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';

void main() {
  group('BoostService scoped queries', () {
    late FakeFirebaseFirestore db;
    late BoostService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = BoostService(db);
    });

    test('watchUserBoosts and watchUserBoostPurchases filter by userId server-side', () async {
      await db.collection('listings').doc('l1').set({'status': 'active'});
      await db.collection('listings').doc('l2').set({'status': 'active'});

      await service.processBoostPurchase(
        listingId: 'l1',
        userId: 'user_A',
        productId: 'boost_7_days',
        transactionId: 'tx_1',
      );

      await service.processBoostPurchase(
        listingId: 'l2',
        userId: 'user_B',
        productId: 'boost_14_days',
        transactionId: 'tx_2',
      );

      final userABoosts = await service.watchUserBoosts('user_A').first;
      expect(userABoosts, hasLength(1));
      expect(userABoosts.first.userId, 'user_A');
      expect(userABoosts.first.listingId, 'l1');

      final userAPurchases = await service.watchUserBoostPurchases('user_A').first;
      expect(userAPurchases, hasLength(1));
      expect(userAPurchases.first.userId, 'user_A');

      final userBBoosts = await service.watchUserBoosts('user_B').first;
      expect(userBBoosts, hasLength(1));
      expect(userBBoosts.first.userId, 'user_B');
      expect(userBBoosts.first.listingId, 'l2');
    });
  });
}

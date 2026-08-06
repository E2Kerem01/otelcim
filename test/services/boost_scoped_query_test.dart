import 'package:cloud_firestore/cloud_firestore.dart';
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

      // Boost creation now goes through a Cloud Function
      // (verifyAndProcessBoostPurchase) rather than a direct client write,
      // so seed the fake Firestore docs directly here instead of calling
      // processBoostPurchase().
      Future<void> seedBoost({
        required String listingId,
        required String userId,
        required String durationType,
        required int durationDays,
        required String transactionId,
      }) async {
        final now = DateTime.now();
        final boostRef = db.collection('boosts').doc();
        await boostRef.set({
          'id': boostRef.id,
          'listingId': listingId,
          'userId': userId,
          'durationType': durationType,
          'durationDays': durationDays,
          'price': 49.99,
          'purchasedAt': Timestamp.fromDate(now),
          'expiresAt': Timestamp.fromDate(now.add(Duration(days: durationDays))),
          'platform': 'in_app_purchase',
          'transactionId': transactionId,
          'status': 'active',
        });
        final purchaseRef = db.collection('boost_purchases').doc();
        await purchaseRef.set({
          'id': purchaseRef.id,
          'userId': userId,
          'listingId': listingId,
          'boostId': boostRef.id,
          'durationType': durationType,
          'price': 49.99,
          'platform': 'in_app_purchase',
          'transactionId': transactionId,
          'productId': 'boost_${durationDays}_days',
          'status': 'completed',
          'purchasedAt': Timestamp.fromDate(now),
          'verifiedAt': Timestamp.fromDate(now),
        });
      }

      await seedBoost(
        listingId: 'l1',
        userId: 'user_A',
        durationType: '7',
        durationDays: 7,
        transactionId: 'tx_1',
      );

      await seedBoost(
        listingId: 'l2',
        userId: 'user_B',
        durationType: '14',
        durationDays: 14,
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

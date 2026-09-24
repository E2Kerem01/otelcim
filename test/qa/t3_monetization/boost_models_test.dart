import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/boosts/domain/boost_model.dart';
import 'package:otelcim/features/boosts/domain/boost_purchase_model.dart';

import 't3_helpers.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  Future<DocumentSnapshot<Map<String, dynamic>>> seed(
    String collection,
    Map<String, dynamic> data,
  ) async {
    final ref = db.collection(collection).doc();
    await ref.set(data);
    return ref.get();
  }

  // Exactly what verifyAndProcessBoostPurchase writes to `boosts`
  // (functions/src/index.ts:606-618).
  Map<String, dynamic> serverBoost(String durationTypeEnum, int days) => {
        'listingId': 'l1',
        'userId': 'u1',
        'durationType': durationTypeEnum,
        'durationDays': days,
        'price': 89.99,
        'purchasedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'expiresAt': Timestamp.fromDate(DateTime(2026, 9, 1 + days)),
        'platform': 'google_play',
        'transactionId': 'GPA.1',
        'status': 'active',
      };

  group('Boost.fromDoc — server-written documents', () {
    test('7-day server boost ("days7") parses as days7', () async {
      final boost = Boost.fromDoc(await seed('boosts', serverBoost('days7', 7)));
      expect(boost.durationType, BoostDurationType.days7);
      expect(boost.durationDays, 7);
    });

    test('14-day server boost ("days14") parses as days14', () async {
      final boost = Boost.fromDoc(await seed('boosts', serverBoost('days14', 14)));
      expect(boost.durationType, BoostDurationType.days14);
    }, skip: bug('BUG-t3-01: server writes durationType "days14", client only understands "14" -> every boost reads as days7'));

    test('30-day server boost ("days30") parses as days30', () async {
      final boost = Boost.fromDoc(await seed('boosts', serverBoost('days30', 30)));
      expect(boost.durationType, BoostDurationType.days30);
    }, skip: bug('BUG-t3-01: server writes durationType "days30", client only understands "30"'));

    test('durationType and durationDays never disagree for a server boost', () async {
      final boost = Boost.fromDoc(await seed('boosts', serverBoost('days30', 30)));
      final daysFromType = switch (boost.durationType) {
        BoostDurationType.days7 => 7,
        BoostDurationType.days14 => 14,
        BoostDurationType.days30 => 30,
      };
      expect(daysFromType, boost.durationDays);
    }, skip: bug('BUG-t3-01: a 30-day server boost reads as durationType=days7 but durationDays=30'));

    test('free referral boost (price 0, platform referral_reward) keeps price 0', () async {
      final boost = Boost.fromDoc(await seed('boosts', {
        ...serverBoost('days7', 7),
        'price': 0,
        'platform': 'referral_reward',
      }));
      expect(boost.price, 0.0);
      expect(boost.platform, 'referral_reward');
    });

    test('integer price from the server is widened to double', () async {
      final boost = Boost.fromDoc(await seed('boosts', {...serverBoost('days7', 7), 'price': 50}));
      expect(boost.price, 50.0);
    });

    test('empty document falls back to safe defaults instead of throwing', () async {
      final boost = Boost.fromDoc(await seed('boosts', {}));
      expect(boost.durationType, BoostDurationType.days7);
      expect(boost.durationDays, 7);
      expect(boost.price, 0.0);
      expect(boost.status, BoostStatus.active);
      expect(boost.expiresAt, isNull);
      expect(boost.listingId, isEmpty);
    });

    test('unknown status string falls back to active', () async {
      final boost = Boost.fromDoc(await seed('boosts', {...serverBoost('days7', 7), 'status': 'refunded'}));
      expect(boost.status, BoostStatus.active);
    });

    test('durationDays stored as a double (14.0) does not crash parsing', () async {
      final snap = await seed('boosts', {...serverBoost('days14', 14), 'durationDays': 14.0});
      expect(() => Boost.fromDoc(snap), returnsNormally);
    }, skip: bug('BUG-t3-02: `durationDays as int?` throws TypeError for a double (e.g. console/Admin-SDK edit)'));
  });

  group('BoostPurchase.fromDoc — server-written documents', () {
    test('paid purchase written by the server round-trips its fields', () async {
      final purchase = BoostPurchase.fromDoc(await seed('boost_purchases', {
        'userId': 'u1',
        'listingId': 'l1',
        'boostId': 'b1',
        'durationType': '14',
        'price': 89.99,
        'platform': 'google_play',
        'transactionId': 'GPA.1',
        'productId': 'boost_14_days',
        'purchaseToken': 'tok',
        'verificationData': null,
        'status': 'completed',
        'purchasedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        'verifiedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      }));
      expect(purchase.durationType, '14');
      expect(purchase.status, PurchaseStatus.completed);
      expect(purchase.boostId, 'b1');
      expect(purchase.verificationData, isNull);
      expect(purchase.verifiedAt, DateTime(2026, 9, 1));
    });

    test('referral purchase (no purchaseToken/verificationData keys, price 0) parses', () async {
      final purchase = BoostPurchase.fromDoc(await seed('boost_purchases', {
        'userId': 'u1',
        'listingId': 'l1',
        'boostId': 'b1',
        'durationType': '7',
        'price': 0,
        'platform': 'referral_reward',
        'transactionId': 'referral_b1',
        'productId': 'referral_free_boost',
        'status': 'completed',
        'purchasedAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
      }));
      expect(purchase.price, 0.0);
      expect(purchase.purchaseToken, isNull);
      expect(purchase.productId, 'referral_free_boost');
    });

    test('unknown / missing status falls back to pending', () async {
      final unknown = BoostPurchase.fromDoc(await seed('boost_purchases', {'status': 'weird'}));
      final missing = BoostPurchase.fromDoc(await seed('boost_purchases', {}));
      expect(unknown.status, PurchaseStatus.pending);
      expect(missing.status, PurchaseStatus.pending);
      expect(missing.durationType, '7');
    });

    test('refunded status is recognised', () async {
      final purchase = BoostPurchase.fromDoc(await seed('boost_purchases', {'status': 'refunded'}));
      expect(purchase.status, PurchaseStatus.refunded);
    });
  });

  group('BannerAd.fromDoc — tolerance of hand-edited documents', () {
    test('missing isActive defaults to active, missing order to 0', () async {
      final ad = BannerAd.fromDoc(await seed('banner_ads', {'title': 'T'}));
      expect(ad.isActive, isTrue);
      expect(ad.order, 0);
      expect(ad.startDate, isNull);
      expect(ad.endDate, isNull);
    });

    test('order stored as a double (1.0) does not crash parsing', () async {
      final snap = await seed('banner_ads', {'title': 'T', 'order': 1.0});
      expect(() => BannerAd.fromDoc(snap), returnsNormally);
    }, skip: bug('BUG-t3-02: `order as int?` throws for a double; one such banner hides every banner (see banner_ad_edge_test)'));

    test('copyWith cannot clear an end date back to "Süresiz"', () {
      final ad = BannerAd(
        id: 'a',
        title: 'T',
        advertiserName: 'A',
        imageUrl: 'i',
        targetUrl: 'u',
        endDate: DateTime(2026, 10, 1),
      );
      // Passing null means "keep" in copyWith, so there is no way to remove
      // an end date once set (the admin form has no clear button either).
      final cleared = ad.copyWith(endDate: null);
      expect(cleared.endDate, isNull);
    }, skip: bug('BUG-t3-12: BannerAd.copyWith uses `endDate ?? this.endDate`; an end/start date can never be removed'));
  });
}

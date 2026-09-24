import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/boosts/services/boost_service.dart';
import 'package:otelcim/features/listings/services/urgent_listing_service.dart';

import 't3_helpers.dart';

void main() {
  group('Cloud Function callers are not unit-testable (FirebaseAuth.instance + static http.post)', () {
    // These document the testability problem rather than business logic:
    // with no Firebase app there is no seam to inject an auth/http fake, so
    // the call fails before any request/response handling can be exercised.
    test('processBoostPurchase rethrows when Firebase is not initialised', () async {
      final service = BoostService(FakeFirebaseFirestore());
      await expectLater(
        service.processBoostPurchase(
          listingId: 'l1',
          userId: 'u1',
          productId: 'boost_7_days',
          transactionId: 'GPA.1',
          platform: 'google_play',
        ),
        throwsA(anything),
      );
    });

    test('redeemFreeBoost rethrows when Firebase is not initialised', () async {
      final service = BoostService(FakeFirebaseFirestore());
      await expectLater(service.redeemFreeBoost(listingId: 'l1', userId: 'u1'), throwsA(anything));
    });

    test('UrgentListingService.processUrgentListingPurchase rethrows when Firebase is not initialised', () async {
      await expectLater(
        const UrgentListingService().processUrgentListingPurchase(
          listingId: 'l1',
          productId: UrgentListingService.urgentListingProductId,
          platform: 'google_play',
        ),
        throwsA(anything),
      );
    });
  });

  group('BoostService.watchUserBoosts', () {
    late FakeFirebaseFirestore db;
    late BoostService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = BoostService(db);
    });

    Future<void> seedBoost(String id, {DateTime? purchasedAt, Object durationDays = 7, String userId = 'u1'}) {
      return db.collection('boosts').doc(id).set({
        'listingId': 'l1',
        'userId': userId,
        'durationType': 'days7',
        'durationDays': durationDays,
        'price': 49.99,
        'purchasedAt': purchasedAt == null ? null : Timestamp.fromDate(purchasedAt),
        'expiresAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
        'platform': 'google_play',
        'transactionId': 'GPA.$id',
        'status': 'active',
      });
    }

    test('orders newest first and puts a pending (null) purchasedAt last', () async {
      await seedBoost('old', purchasedAt: DateTime(2026, 1, 1));
      await seedBoost('pending');
      await seedBoost('new', purchasedAt: DateTime(2026, 9, 1));

      final boosts = await service.watchUserBoosts('u1').first;
      expect(boosts.map((b) => b.id), ['new', 'old', 'pending']);
    });

    test('re-emits when the server writes a new boost for the user', () async {
      await seedBoost('first', purchasedAt: DateTime(2026, 9, 1));
      final emissions = <List<String>>[];
      final sub = service.watchUserBoosts('u1').listen((b) => emissions.add(b.map((x) => x.id).toList()));
      await pumpEventQueue();

      await seedBoost('second', purchasedAt: DateTime(2026, 9, 2));
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.last, ['second', 'first']);
    });

    test('one malformed boost document does not hide the user\'s other boosts', () async {
      await seedBoost('good', purchasedAt: DateTime(2026, 9, 1));
      await seedBoost('bad', purchasedAt: DateTime(2026, 9, 2), durationDays: 14.0);

      final events = <List<String>>[];
      final sub = service.watchUserBoosts('u1').listen((b) => events.add(b.map((x) => x.id).toList()));
      await pumpEventQueue();
      await sub.cancel();

      expect(events, isNotEmpty);
      expect(events.last, contains('good'));
    }, skip: bug('BUG-t3-02 / BUG-t3-14: `durationDays as int?` throws in map(); handleError swallows it, stream emits nothing'));
  });

  group('BoostService stream error handling', () {
    Future<(List<Object>, List<Object>)> collect(Stream<List<Object>> stream) async {
      final data = <Object>[];
      final errors = <Object>[];
      final sub = stream.listen(data.add, onError: errors.add);
      await pumpEventQueue();
      await sub.cancel();
      return (data, errors);
    }

    test('a rejected boosts query surfaces as an error or an empty list, not silence', () async {
      final service = BoostService(buildFailingFirestore('boosts'));
      final (data, errors) = await collect(service.watchUserBoosts('u1'));
      expect(data.isNotEmpty || errors.isNotEmpty, isTrue);
    }, skip: bug('BUG-t3-14: .handleError return value is ignored -> stream emits nothing -> UI loads forever'));

    test('a rejected boost_purchases query surfaces as an error or an empty list, not silence', () async {
      final service = BoostService(buildFailingFirestore('boost_purchases'));
      final (data, errors) = await collect(service.watchUserBoostPurchases('u1'));
      expect(data.isNotEmpty || errors.isNotEmpty, isTrue);
    }, skip: bug('BUG-t3-14: same .handleError pattern in watchUserBoostPurchases'));

    test('guard: the failing Firestore fake really emits permission-denied', () async {
      // Guard test: proves the failing-Firestore fake really errors, so the
      // two skipped tests above fail for the right reason.
      final raw = buildFailingFirestore('boosts').collection('boosts').where('userId', isEqualTo: 'u1').snapshots();
      final completer = Completer<Object>();
      raw.listen((_) {}, onError: completer.complete);
      expect(await completer.future, isA<FirebaseException>());
    });
  });
}

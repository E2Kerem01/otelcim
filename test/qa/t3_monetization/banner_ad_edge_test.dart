import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';

import 't3_helpers.dart';

void main() {
  late FakeFirebaseFirestore db;
  late BannerAdService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = BannerAdService(db);
  });

  Future<void> seed(String id, Map<String, dynamic> extra) {
    return db.collection('banner_ads').doc(id).set({
      'title': id,
      'advertiserName': 'Jolly Tur',
      'imageUrl': '',
      'targetUrl': 'https://example.com',
      'order': 0,
      'isActive': true,
      ...extra,
    });
  }

  Future<List<String>> activeIds() async =>
      (await service.watchActiveBannerAds().first).map((a) => a.id).toList();

  group('watchActiveBannerAds — date window boundaries', () {
    test('banner that started a minute ago is shown', () async {
      await seed('a', {'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1)))});
      expect(await activeIds(), ['a']);
    });

    test('banner that starts in a minute is not shown yet', () async {
      await seed('a', {'startDate': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1)))});
      expect(await activeIds(), isEmpty);
    });

    test('banner ending in a minute is still shown; one that ended a minute ago is not', () async {
      await seed('live', {'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 1)))});
      await seed('ended', {'endDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 1)))});
      expect(await activeIds(), ['live']);
    });

    test('isActive=false hides a banner even inside its date window', () async {
      await seed('off', {
        'isActive': false,
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'endDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      });
      expect(await activeIds(), isEmpty);
    });

    test('banner whose end date is today (picked in the admin date picker) runs through today', () async {
      // showDatePicker returns midnight, so "Bitiş: 24.9.2026" is stored as
      // 2026-09-24 00:00 and the banner disappears at the START of the last
      // day the advertiser paid for.
      final now = DateTime.now();
      await seed('today', {'endDate': Timestamp.fromDate(DateTime(now.year, now.month, now.day))});
      expect(await activeIds(), ['today']);
    }, skip: bug('BUG-t3-15: endDate is exclusive midnight; a banner booked "until today" is hidden all of today'));
  });

  group('watchActiveBannerAds — ordering', () {
    test('equal order: newer createdAt first, missing createdAt last', () async {
      await seed('older', {'order': 1, 'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1))});
      await seed('noDate', {'order': 1});
      await seed('newer', {'order': 1, 'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1))});
      await seed('first', {'order': 0});
      expect(await activeIds(), ['first', 'newer', 'older', 'noDate']);
    });

    test('negative order values sort before 0', () async {
      await seed('zero', {'order': 0});
      await seed('pinned', {'order': -1});
      expect(await activeIds(), ['pinned', 'zero']);
    });
  });

  group('watchActiveBannerAds — live updates and bad data', () {
    test('toggleActive(false) removes the banner from the live stream', () async {
      await seed('a', {'order': 0});
      await seed('b', {'order': 1});
      final emissions = <List<String>>[];
      final sub = service.watchActiveBannerAds().listen((l) => emissions.add(l.map((a) => a.id).toList()));
      await pumpEventQueue();

      await service.toggleActive('a', false);
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, ['a', 'b']);
      expect(emissions.last, ['b']);
    });

    test('one hand-edited banner with order 1.0 does not hide every other banner', () async {
      await seed('good', {'order': 0});
      await seed('bad', {'order': 1.0});
      final events = <List<String>>[];
      final sub = service.watchActiveBannerAds().listen((l) => events.add(l.map((a) => a.id).toList()));
      await pumpEventQueue();
      await sub.cancel();
      expect(events, isNotEmpty);
      expect(events.last, contains('good'));
    }, skip: bug('BUG-t3-02: `order as int?` throws in map(); handleError swallows it -> carousel shows nothing'));

    test('updateBannerAd keeps the original createdAt', () async {
      final created = DateTime(2026, 5, 5);
      await seed('a', {'createdAt': Timestamp.fromDate(created)});
      final ad = (await service.watchAllBannerAds().first).single;
      await service.updateBannerAd(ad.copyWith(title: 'Yeni'));
      final data = (await db.collection('banner_ads').doc('a').get()).data()!;
      expect(data['title'], 'Yeni');
      expect((data['createdAt'] as Timestamp).toDate(), created);
    });
  });
}

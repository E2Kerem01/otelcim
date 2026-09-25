import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/admin/services/analytics_service.dart';

void main() {
  final now = DateTime(2026, 9, 24, 12);

  group('AdminAnalyticsService trends', () {
    late FakeFirebaseFirestore db;
    late AdminAnalyticsService service;

    setUp(() {
      db = FakeFirebaseFirestore();
      service = AdminAnalyticsService(db, now: () => now);
    });

    test('compares current and previous periods for new users and listings', () async {
      await db.collection('user_profiles').doc('current-1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 20)),
      });
      await db.collection('user_profiles').doc('current-2').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 21)),
      });
      await db.collection('user_profiles').doc('previous-1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 14)),
      });
      await db.collection('listings').doc('current-1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 22)),
      });
      await db.collection('listings').doc('previous-1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 15)),
      });
      await db.collection('listings').doc('previous-2').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 16)),
      });

      final overview = await service.getOverview(recentDays: 7);

      expect(overview['newUsers'], 2);
      expect(overview.trendFor('newUsers')?.current, 2);
      expect(overview.trendFor('newUsers')?.previous, 1);
      expect(overview.trendFor('newUsers')?.percentChange, 100);
      expect(overview.trendFor('newListings')?.current, 1);
      expect(overview.trendFor('newListings')?.previous, 2);
      expect(overview.trendFor('newListings')?.percentChange, -50);
    });

    test('does not divide by zero or invent a trend for missing values', () {
      expect(calculateTrendPercent(current: 3, previous: 0), isNull);
      expect(calculateTrendPercent(current: 0, previous: 0), isNull);
      expect(calculateTrendPercent(current: null, previous: 4), isNull);
      expect(calculateTrendPercent(current: 4, previous: null), isNull);
    });
  });

  group('AdminAnalyticsService daily series', () {
    test('returns one point per day with parallel user and listing counts', () async {
      final db = FakeFirebaseFirestore();
      final service = AdminAnalyticsService(db, now: () => now);
      await db.collection('user_profiles').doc('u1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 23, 1)),
      });
      await db.collection('user_profiles').doc('u2').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 23, 23)),
      });
      await db.collection('listings').doc('l1').set({
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 24, 2)),
      });

      final series = await service.getDailySeries(days: 3);

      expect(series.map((point) => point.date), [
        DateTime(2026, 9, 22),
        DateTime(2026, 9, 23),
        DateTime(2026, 9, 24),
      ]);
      expect(series.map((point) => point.newUsers), [0, 2, 0]);
      expect(series.map((point) => point.newListings), [0, 0, 1]);
    });

    test('returns an empty series for a non-positive day count', () async {
      final service = AdminAnalyticsService(
        FakeFirebaseFirestore(),
        now: () => now,
      );

      expect(await service.getDailySeries(days: 0), isEmpty);
    });
  });
}

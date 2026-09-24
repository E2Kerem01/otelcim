import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_reporter.dart';

/// Service for providing admin dashboard analytics and metrics
class AdminAnalyticsService {
  AdminAnalyticsService(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final FirebaseFirestore _db;
  final DateTime Function() _now;

  /// Server-side `count()` aggregate: billed ~1 read per 1000 matching docs
  /// instead of downloading every document just to read `.size`.
  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<int> _safeCount(
    Query<Map<String, dynamic>> query, {
    required String context,
  }) async {
    try {
      return await _count(query);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: context);
      return 0;
    }
  }

  /// Returns count of active listings
  Future<int> getActiveListingsCount() async {
    try {
      return await _count(
        _db.collection('listings').where('status', isEqualTo: 'active'),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminAnalyticsService.getActiveListingsCount');
      return 0;
    }
  }

  /// Returns count of new users created in the last [days] days (default: 30)
  Future<int> getNewUsersCount({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      return await _count(
        _db
            .collection('user_profiles')
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate)),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminAnalyticsService.getNewUsersCount');
      return 0;
    }
  }

  /// Returns count of open/pending reports
  Future<int> getOpenReportsCount() async {
    try {
      // Only reports still awaiting a decision (dismissReport sets
      // 'dismissed'); this used to count every report ever filed.
      return await _count(
        _db.collection('reports').where('status', isEqualTo: 'pending'),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminAnalyticsService.getOpenReportsCount');
      return 0;
    }
  }

  /// Returns count of pending verification requests
  Future<int> getPendingVerificationsCount() async {
    try {
      return await _count(
        _db.collection('verification_requests').where('status', isEqualTo: 'pending'),
      );
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'AdminAnalyticsService.getPendingVerificationsCount',
      );
      return 0;
    }
  }

  /// Streams real-time count of active listings
  Stream<int> watchActiveListingsCount() {
    return _db
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.size)
        .handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'AdminAnalyticsService.watchActiveListingsCount',
      );
      return 0;
    });
  }

  /// Streams real-time count of new users in the last [days] days
  Stream<int> watchNewUsersCount({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _db
        .collection('user_profiles')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
        .snapshots()
        .map((snap) => snap.size)
        .handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'AdminAnalyticsService.watchNewUsersCount',
      );
      return 0;
    });
  }

  /// Streams real-time count of open reports
  Stream<int> watchOpenReportsCount() {
    return _db
        .collection('reports')
        .snapshots()
        .map((snap) => snap.size)
        .handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'AdminAnalyticsService.watchOpenReportsCount',
      );
      return 0;
    });
  }

  /// Streams real-time count of pending verification requests
  Stream<int> watchPendingVerificationsCount() {
    return _db
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.size)
        .handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'AdminAnalyticsService.watchPendingVerificationsCount',
      );
      return 0;
    });
  }

  /// Returns all dashboard metrics at once
  /// Every headline number for the admin dashboard, fetched in parallel with
  /// server-side count() aggregates. A failing count (e.g. an index still
  /// building) shows as null instead of failing the whole panel.
  Future<AdminOverview> getOverview({int recentDays = 7}) async {
    final now = _now();
    final currentSince = now.subtract(Duration(days: recentDays));
    final previousSince = currentSince.subtract(Duration(days: recentDays));
    final currentSinceTimestamp = Timestamp.fromDate(currentSince);
    final previousSinceTimestamp = Timestamp.fromDate(previousSince);
    final users = _db.collection('user_profiles');
    final listings = _db.collection('listings');
    final queries = <String, Query<Map<String, dynamic>>>{
      'users': users,
      'jobseekers': users.where('userType', isEqualTo: 'jobseeker'),
      'employers': users.where('userType', isEqualTo: 'employer'),
      'verifiedEmployers': users.where('isVerified', isEqualTo: true),
      'banned': users.where('isBanned', isEqualTo: true),
      'suspended': users.where('isSuspended', isEqualTo: true),
      'newUsers': users.where(
        'createdAt',
        isGreaterThanOrEqualTo: currentSinceTimestamp,
      ),
      'listings': listings,
      'activeListings': listings.where('status', isEqualTo: 'active'),
      'urgentListings': listings
          .where('status', isEqualTo: 'active')
          .where('isUrgent', isEqualTo: true),
      'boostedListings': listings
          .where('status', isEqualTo: 'active')
          .where('isBoosted', isEqualTo: true),
      'newListings': listings.where(
        'createdAt',
        isGreaterThanOrEqualTo: currentSinceTimestamp,
      ),
      'previousNewUsers': users
          .where('createdAt', isGreaterThanOrEqualTo: previousSinceTimestamp)
          .where('createdAt', isLessThan: currentSinceTimestamp),
      'previousNewListings': listings
          .where('createdAt', isGreaterThanOrEqualTo: previousSinceTimestamp)
          .where('createdAt', isLessThan: currentSinceTimestamp),
      'pendingReports': _db.collection('reports').where('status', isEqualTo: 'pending'),
      'pendingVerifications': _db
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending'),
      'pendingCertificates': _db
          .collection('certificates')
          .where('status', isEqualTo: 'pending'),
      'conversations': _db.collection('conversations'),
    };
    final keys = queries.keys.toList();
    final values = await Future.wait(keys.map((key) async {
      try {
        return await _count(queries[key]!);
      } catch (error, stackTrace) {
        logError(error, stackTrace, context: 'AdminAnalyticsService.getOverview.$key');
        return null;
      }
    }));
    final allCounts = Map<String, int?>.fromIterables(keys, values);
    final trends = <String, AdminTrend>{
      'newUsers': AdminTrend(
        current: allCounts['newUsers'],
        previous: allCounts['previousNewUsers'],
      ),
      'newListings': AdminTrend(
        current: allCounts['newListings'],
        previous: allCounts['previousNewListings'],
      ),
    };
    allCounts.remove('previousNewUsers');
    allCounts.remove('previousNewListings');
    return AdminOverview(
      allCounts,
      recentDays: recentDays,
      trends: trends,
    );
  }

  /// Returns daily new-user and new-listing counts for the last [days]
  /// calendar days, oldest first. Each day's two aggregate queries run in
  /// parallel and a failed aggregate is represented by zero for that day.
  Future<List<AdminDailySeries>> getDailySeries({int days = 30}) async {
    if (days <= 0) return [];

    final today = _startOfDay(_now());
    return Future.wait(List.generate(days, (index) async {
      final date = today.subtract(Duration(days: days - index - 1));
      final nextDate = date.add(const Duration(days: 1));
      final start = Timestamp.fromDate(date);
      final end = Timestamp.fromDate(nextDate);
      final userQuery = _db
          .collection('user_profiles')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
      final listingQuery = _db
          .collection('listings')
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
      final counts = await Future.wait([
        _safeCount(userQuery, context: 'AdminAnalyticsService.getDailySeries.users'),
        _safeCount(
          listingQuery,
          context: 'AdminAnalyticsService.getDailySeries.listings',
        ),
      ]);
      return AdminDailySeries(
        date: date,
        newUsers: counts[0],
        newListings: counts[1],
      );
    }));
  }

  static DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<DashboardMetrics> getDashboardMetrics({int newUsersDays = 30}) async {
    try {
      final results = await Future.wait([
        getActiveListingsCount(),
        getNewUsersCount(days: newUsersDays),
        getOpenReportsCount(),
        getPendingVerificationsCount(),
      ]);

      return DashboardMetrics(
        activeListings: results[0],
        newUsers: results[1],
        openReports: results[2],
        pendingVerifications: results[3],
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'AdminAnalyticsService.getDashboardMetrics');
      return DashboardMetrics(
        activeListings: 0,
        newUsers: 0,
        openReports: 0,
        pendingVerifications: 0,
      );
    }
  }
}

/// Container for all dashboard metrics
class DashboardMetrics {
  const DashboardMetrics({
    required this.activeListings,
    required this.newUsers,
    required this.openReports,
    required this.pendingVerifications,
  });

  final int activeListings;
  final int newUsers;
  final int openReports;
  final int pendingVerifications;
}

final adminAnalyticsServiceProvider = Provider<AdminAnalyticsService>(
  (ref) => AdminAnalyticsService(FirebaseFirestore.instance),
);

/// Headline counts for the admin dashboard; a null value means that count
/// could not be loaded.
class AdminOverview {
  const AdminOverview(
    this.counts, {
    required this.recentDays,
    this.trends = const <String, AdminTrend>{},
  });

  final Map<String, int?> counts;
  final int recentDays;
  final Map<String, AdminTrend> trends;

  int? operator [](String key) => counts[key];

  AdminTrend? trendFor(String key) => trends[key];
}

/// Comparison between the current and previous period for one KPI.
class AdminTrend {
  const AdminTrend({required this.current, required this.previous});

  final int? current;
  final int? previous;

  double? get percentChange => calculateTrendPercent(
        current: current,
        previous: previous,
      );
}

/// Calculates percentage change without inventing a value when the previous
/// period is missing or zero.
double? calculateTrendPercent({required int? current, required int? previous}) {
  if (current == null || previous == null || previous == 0) return null;
  return (current - previous) / previous * 100;
}

/// One calendar day's new-user and new-listing aggregates.
class AdminDailySeries {
  const AdminDailySeries({
    required this.date,
    required this.newUsers,
    required this.newListings,
  });

  final DateTime date;
  final int newUsers;
  final int newListings;
}

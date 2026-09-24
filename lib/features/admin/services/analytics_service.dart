import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_reporter.dart';

/// Service for providing admin dashboard analytics and metrics
class AdminAnalyticsService {
  AdminAnalyticsService(this._db);

  final FirebaseFirestore _db;

  /// Server-side `count()` aggregate: billed ~1 read per 1000 matching docs
  /// instead of downloading every document just to read `.size`.
  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
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
    final since = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: recentDays)),
    );
    final users = _db.collection('user_profiles');
    final listings = _db.collection('listings');
    final queries = <String, Query<Map<String, dynamic>>>{
      'users': users,
      'jobseekers': users.where('userType', isEqualTo: 'jobseeker'),
      'employers': users.where('userType', isEqualTo: 'employer'),
      'verifiedEmployers': users.where('isVerified', isEqualTo: true),
      'banned': users.where('isBanned', isEqualTo: true),
      'suspended': users.where('isSuspended', isEqualTo: true),
      'newUsers': users.where('createdAt', isGreaterThanOrEqualTo: since),
      'listings': listings,
      'activeListings': listings.where('status', isEqualTo: 'active'),
      'urgentListings': listings
          .where('status', isEqualTo: 'active')
          .where('isUrgent', isEqualTo: true),
      'boostedListings': listings
          .where('status', isEqualTo: 'active')
          .where('isBoosted', isEqualTo: true),
      'newListings': listings.where('createdAt', isGreaterThanOrEqualTo: since),
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
    return AdminOverview(Map.fromIterables(keys, values), recentDays: recentDays);
  }

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
  const AdminOverview(this.counts, {required this.recentDays});

  final Map<String, int?> counts;
  final int recentDays;

  int? operator [](String key) => counts[key];
}

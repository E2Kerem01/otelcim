import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for providing admin dashboard analytics and metrics
class AdminAnalyticsService {
  AdminAnalyticsService(this._db);

  final FirebaseFirestore _db;

  /// Returns count of active listings
  Future<int> getActiveListingsCount() async {
    try {
      final snap = await _db
          .collection('listings')
          .where('status', isEqualTo: 'active')
          .get();
      return snap.size;
    } catch (e) {
      debugPrint('Error getting active listings count: $e');
      return 0;
    }
  }

  /// Returns count of new users created in the last [days] days (default: 30)
  Future<int> getNewUsersCount({int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final snap = await _db
          .collection('user_profiles')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .get();
      return snap.size;
    } catch (e) {
      debugPrint('Error getting new users count: $e');
      return 0;
    }
  }

  /// Returns count of open/pending reports
  Future<int> getOpenReportsCount() async {
    try {
      final snap = await _db.collection('reports').get();
      return snap.size;
    } catch (e) {
      debugPrint('Error getting open reports count: $e');
      return 0;
    }
  }

  /// Returns count of pending verification requests
  Future<int> getPendingVerificationsCount() async {
    try {
      final snap = await _db
          .collection('verification_requests')
          .where('status', isEqualTo: 'pending')
          .get();
      return snap.size;
    } catch (e) {
      debugPrint('Error getting pending verifications count: $e');
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
        .handleError((Object error) {
      debugPrint('Error watching active listings count: $error');
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
        .handleError((Object error) {
      debugPrint('Error watching new users count: $error');
      return 0;
    });
  }

  /// Streams real-time count of open reports
  Stream<int> watchOpenReportsCount() {
    return _db
        .collection('reports')
        .snapshots()
        .map((snap) => snap.size)
        .handleError((Object error) {
      debugPrint('Error watching open reports count: $error');
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
        .handleError((Object error) {
      debugPrint('Error watching pending verifications count: $error');
      return 0;
    });
  }

  /// Returns all dashboard metrics at once
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
    } catch (e) {
      debugPrint('Error getting dashboard metrics: $e');
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

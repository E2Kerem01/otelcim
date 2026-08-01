import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';

class ReportService {
  ReportService(this._db);

  final FirebaseFirestore _db;

  /// Submits a new report to Firestore
  Future<void> submitReport(Report report) async {
    try {
      await _db.collection('reports').add(report.toMap());
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  /// Checks if a user has already reported a specific target
  /// Returns true if a report already exists, false otherwise
  Future<bool> hasUserReportedTarget({
    required String reporterId,
    required TargetType targetType,
    required String targetId,
  }) async {
    try {
      final targetTypeStr = targetType == TargetType.user ? 'user' : 'listing';
      final snap = await _db
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('targetType', isEqualTo: targetTypeStr)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking duplicate report: $e');
      return false;
    }
  }
}

final reportServiceProvider = Provider<ReportService>(
  (ref) => ReportService(FirebaseFirestore.instance),
);

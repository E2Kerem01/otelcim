import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';

class ReportService {
  ReportService(this._db);

  final FirebaseFirestore _db;

  Future<void> submitReport(Report report) async {
    try {
      await _db.collection('reports').add(report.toMap());
    } catch (e) {
      debugPrint('Error submitting report: $e');
      rethrow;
    }
  }

  Future<bool> hasAlreadyReported({
    required String reporterId,
    required String targetId,
  }) async {
    try {
      final snap = await _db
          .collection('reports')
          .where('reporterId', isEqualTo: reporterId)
          .where('targetId', isEqualTo: targetId)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking duplicate report: $e');
      return false;
    }
  }

  Future<bool> hasUserReportedTarget({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
  }) async {
    return hasAlreadyReported(reporterId: reporterId, targetId: targetId);
  }
}

final reportServiceProvider = Provider<ReportService>((ref) => ReportService(FirebaseFirestore.instance));

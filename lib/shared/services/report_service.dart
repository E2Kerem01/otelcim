import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_reporter.dart';
import '../models/report.dart';

class ReportService {
  ReportService(this._db);

  final FirebaseFirestore _db;

  Stream<List<Report>> watchPendingReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final status = doc.data()['status'] as String?;
              return status == null || status == 'pending';
            })
            .map(Report.fromDoc)
            .toList())
        .handleError((Object error, StackTrace stackTrace) {
      logError(error, stackTrace, context: 'ReportService.watchPendingReports');
      return <Report>[];
    });
  }

  Future<void> submitReport(Report report) async {
    try {
      await _db.collection('reports').add(report.toMap());
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'ReportService.submitReport');
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
    } catch (e, stackTrace) {
      logError(e, stackTrace, context: 'ReportService.hasAlreadyReported');
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

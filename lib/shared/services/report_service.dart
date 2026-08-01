import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';

class ReportService {
  ReportService(this._db);

  final FirebaseFirestore _db;

  Future<bool> hasAlreadyReported({
    required String reporterId,
    required String targetId,
  }) async {
    final snap = await _db
        .collection('reports')
        .where('reporterId', isEqualTo: reporterId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> submitReport(Report report) {
    return _db.collection('reports').add(report.toMap());
  }
}

final reportServiceProvider = Provider<ReportService>((ref) => ReportService(FirebaseFirestore.instance));

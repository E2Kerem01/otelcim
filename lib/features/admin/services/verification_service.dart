import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../domain/verification_request_model.dart';

class VerificationService {
  VerificationService(this._db);

  final FirebaseFirestore _db;

  /// Watch pending verification requests ordered by submission date
  Stream<List<VerificationRequest>> watchPendingVerifications() {
    return _db
        .collection('verification_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map(VerificationRequest.fromDoc).toList();
    }).handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.watchPendingVerifications',
      );
      return <VerificationRequest>[];
    });
  }

  /// Submit a new verification request
  Future<String> submitVerificationRequest(VerificationRequest request) async {
    try {
      final ref = await _db.collection('verification_requests').add(request.toMap());
      return ref.id;
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.submitVerificationRequest',
      );
      throw mapToFailure(error);
    }
  }

  /// Approve a verification request
  Future<void> approveVerification({
    required String verificationId,
    required String adminId,
  }) async {
    try {
      await _db.collection('verification_requests').doc(verificationId).update({
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      });
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.approveVerification',
      );
      throw mapToFailure(error);
    }
  }

  /// Reject a verification request
  Future<void> rejectVerification({
    required String verificationId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _db.collection('verification_requests').doc(verificationId).update({
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.rejectVerification',
      );
      throw mapToFailure(error);
    }
  }

  /// Get a specific verification request
  Future<VerificationRequest?> getVerificationRequest(String verificationId) async {
    try {
      final doc = await _db.collection('verification_requests').doc(verificationId).get();
      if (!doc.exists) return null;
      return VerificationRequest.fromDoc(doc);
    } catch (error, stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.getVerificationRequest',
      );
      return null;
    }
  }

  /// Watch all verification requests for an employer
  Stream<List<VerificationRequest>> watchEmployerVerifications(String employerId) {
    return _db
        .collection('verification_requests')
        .where('employerId', isEqualTo: employerId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map(VerificationRequest.fromDoc).toList();
    }).handleError((Object error, StackTrace stackTrace) {
      logError(
        error,
        stackTrace,
        context: 'VerificationService.watchEmployerVerifications',
      );
      return <VerificationRequest>[];
    });
  }
}

final verificationServiceProvider = Provider<VerificationService>(
  (ref) => VerificationService(FirebaseFirestore.instance),
);

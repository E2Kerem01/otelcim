import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../domain/verification_request_model.dart';

/// Ordered query used by the paged admin verification review queue.
Query<Map<String, dynamic>> adminVerificationQuery(
  FirebaseFirestore db, {
  required String filter,
}) {
  Query<Map<String, dynamic>> query = db.collection('verification_requests');
  if (filter != 'all') {
    query = query.where('status', isEqualTo: filter);
  }
  return query.orderBy('submittedAt', descending: true);
}

class VerificationService {
  VerificationService(this._db);

  final FirebaseFirestore _db;

  /// Watch pending verification requests ordered by submission date
  Stream<List<VerificationRequest>> watchPendingVerifications() {
    return adminVerificationQuery(_db, filter: 'pending')
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

  /// Writes the admin decision on the request and mirrors it onto the
  /// employer's profile in one transaction. Approving used to update only
  /// the request, so an approved employer never got the verified badge.
  Future<void> _decide(
    String verificationId,
    Map<String, dynamic> requestUpdate, {
    required Map<String, dynamic> profileUpdate,
  }) {
    final requestRef = _db.collection('verification_requests').doc(verificationId);
    return _db.runTransaction((transaction) async {
      final request = await transaction.get(requestRef);
      final data = request.data();
      final employerId = (data?['employerId'] ?? data?['userId']) as String?;
      final profileRef = employerId == null || employerId.isEmpty
          ? null
          : _db.collection('user_profiles').doc(employerId);
      // All transaction reads must happen before the first write.
      final profile = profileRef == null ? null : await transaction.get(profileRef);
      transaction.update(requestRef, requestUpdate);
      if (profileRef != null) {
        if (profile!.exists) {
          transaction.update(profileRef, profileUpdate);
        } else {
          transaction.set(profileRef, profileUpdate);
        }
      }
    });
  }

  /// Approve a verification request
  Future<void> approveVerification({
    required String verificationId,
    required String adminId,
  }) async {
    try {
      await _decide(verificationId, {
        'status': 'approved',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
      }, profileUpdate: {
        'isVerified': true,
        'verificationStatus': 'approved',
        // Millisecond precision on purpose (not serverTimestamp): the owner's
        // own profile edits write verifiedAt back via UserProfile.toFirestore,
        // and firestore.rules requires it unchanged - a microsecond server
        // timestamp would not survive the DateTime round trip on web.
        'verifiedAt': Timestamp.fromMillisecondsSinceEpoch(
          DateTime.now().millisecondsSinceEpoch,
        ),
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
      await _decide(verificationId, {
        'status': 'rejected',
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      }, profileUpdate: {
        'isVerified': false,
        'verificationStatus': 'rejected',
        'verifiedAt': null,
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

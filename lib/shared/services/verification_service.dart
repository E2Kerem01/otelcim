import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_reporter.dart';
import '../models/verification_request.dart';

/// Provider for the VerificationService instance
final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

/// Service for managing verification request CRUD operations in Firestore.
///
/// Handles creating, reading, and watching verification requests with
/// proper error handling and consistent data structure.
class VerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The Firestore collection name for verification requests
  static const String _collectionName = 'verification_requests';

  /// Submits a new verification request to Firestore.
  ///
  /// The request is stored with a generated document ID.
  /// If a request already exists for this user, it will NOT be overwritten.
  /// Use [getUserVerificationRequest] first to check for existing requests.
  ///
  /// Parameters:
  /// - [request]: The VerificationRequest to submit
  ///
  /// Throws the original error (logged via [logError] first) if the
  /// submission fails; callers map it to a user-facing message via
  /// `mapToFailure()`.
  Future<void> submitVerificationRequest(VerificationRequest request) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(request.id)
          .set(request.toFirestore());
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationService.submitVerificationRequest');
      rethrow;
    }
  }

  /// Retrieves a user's verification request from Firestore.
  ///
  /// Searches for a verification request where userId matches the provided ID.
  /// If multiple requests exist, returns the most recent one.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  ///
  /// Returns:
  /// A [Future<VerificationRequest?>] containing the user's verification request,
  /// or null if not found.
  ///
  /// Throws the original error (logged via [logError] first) if the fetch
  /// fails; callers map it to a user-facing message via `mapToFailure()`.
  Future<VerificationRequest?> getUserVerificationRequest(
      String userId) async {
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _firestore
              .collection(_collectionName)
              .where('employerId', isEqualTo: userId)
              .orderBy('submittedAt', descending: true)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        // Fallback for legacy records using 'userId'
        querySnapshot = await _firestore
            .collection(_collectionName)
            .where('userId', isEqualTo: userId)
            .orderBy('requestedAt', descending: true)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return VerificationRequest.fromFirestore(querySnapshot.docs.first);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationService.getUserVerificationRequest');
      rethrow;
    }
  }

  /// Watches a user's verification request for real-time updates.
  ///
  /// Returns a stream that emits the user's most recent verification request
  /// whenever it changes in Firestore. The stream emits null if no request exists.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  ///
  /// Returns:
  /// A [Stream<VerificationRequest?>] that emits verification request updates
  /// in real-time.
  ///
  /// The stream handles errors internally and may emit errors if Firestore
  /// operations fail.
  Stream<VerificationRequest?> watchVerificationRequest(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('employerId', isEqualTo: userId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      return VerificationRequest.fromFirestore(querySnapshot.docs.first);
    }).handleError((Object error, StackTrace stackTrace) {
      logError(error, stackTrace, context: 'VerificationService.watchVerificationRequest');
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}

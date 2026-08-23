import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_reporter.dart';
import '../models/user_profile.dart';

/// Provider for the ProfileService instance
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Service for managing user profile CRUD operations in Firestore.
///
/// Handles creating, reading, updating, and watching user profiles with
/// proper error handling and consistent data structure.
class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The Firestore collection name for user profiles
  static const String _collectionName = 'user_profiles';

  /// Cihazın güncel FCM token'ını kullanıcının profiline kaydeder.
  Future<void> updateFcmToken(String uid, String token) async {
    await _firestore.collection(_collectionName).doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Çıkış yapan kullanıcının eski cihaz token'ını profilden kaldırır.
  Future<void> clearFcmToken(String uid) async {
    await _firestore.collection(_collectionName).doc(uid).set({
      'fcmToken': FieldValue.delete(),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Retrieves a user's profile from Firestore.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  ///
  /// Returns:
  /// A [Future<UserProfile?>] containing the user's profile, or null if not found.
  ///
  /// Throws the original error (logged via [logError] first) if the fetch
  /// fails; callers map it to a user-facing message via `mapToFailure()`.
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserProfile.fromFirestore(doc);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProfileService.getUserProfile');
      rethrow;
    }
  }

  /// Creates a new user profile in Firestore.
  ///
  /// The profile is stored with the user's ID as the document ID.
  /// If a profile already exists for this user, it will be overwritten.
  ///
  /// Parameters:
  /// - [profile]: The UserProfile to create
  ///
  /// Throws the original error (logged via [logError] first) if the
  /// creation fails; callers map it to a user-facing message via
  /// `mapToFailure()`.
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(profile.id)
          .set(profile.toFirestore());
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProfileService.createUserProfile');
      rethrow;
    }
  }

  /// Updates an existing user profile in Firestore.
  ///
  /// Updates the profile with the user's ID as the document ID.
  /// The updatedAt timestamp should be set before calling this method.
  ///
  /// Parameters:
  /// - [profile]: The UserProfile with updated data
  ///
  /// Throws the original error (logged via [logError] first) if the
  /// update fails; callers map it to a user-facing message via
  /// `mapToFailure()`.
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(profile.id)
          .update(profile.toFirestore());
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProfileService.updateUserProfile');
      rethrow;
    }
  }

  /// Finds the uid of the user who owns the given referral [code].
  ///
  /// Returns `null` when no user profile has that referral code (including
  /// an empty/invalid [code]). `user_profiles` reads are already public per
  /// firestore.rules, so no additional permissions are required.
  Future<String?> findUserIdByReferralCode(String code) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.id;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'ProfileService.findUserIdByReferralCode');
      rethrow;
    }
  }

  /// Watches a user's profile for real-time updates.
  ///
  /// Returns a stream that emits the user's profile whenever it changes in Firestore.
  /// The stream emits null if the profile doesn't exist.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  ///
  /// Returns:
  /// A [Stream<UserProfile?>] that emits profile updates in real-time.
  ///
  /// The stream handles errors internally and may emit errors if Firestore
  /// operations fail.
  Stream<UserProfile?> watchUserProfile(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromFirestore(snapshot);
    }).handleError((Object error, StackTrace stackTrace) {
      logError(error, stackTrace, context: 'ProfileService.watchUserProfile');
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}

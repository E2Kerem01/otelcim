import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/storage_service.dart';

/// Provider for the ProfileService instance
///
/// Note: This re-exports the provider from ProfileService for convenient access.
/// The actual provider is defined in profile_service.dart.
export '../services/profile_service.dart' show profileServiceProvider;

/// Provider for the StorageService instance
///
/// Note: This re-exports the provider from StorageService for convenient access.
/// The actual provider is defined in storage_service.dart.
export '../services/storage_service.dart' show storageServiceProvider;

/// Provider that watches the current authenticated user's profile.
///
/// Returns a [StreamProvider] that:
/// - Emits null when the user is not authenticated
/// - Emits null when the user has no profile yet
/// - Emits the UserProfile when it exists
/// - Updates in real-time as the profile changes in Firestore
///
/// This provider automatically handles user authentication state changes.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) async* {
  // Watch the authentication state
  final authState = ref.watch(authStateProvider);

  // If not authenticated or loading, emit null
  final userId = authState.value?.uid;
  if (userId == null) {
    yield null;
    return;
  }

  // Watch the user's profile and forward all updates
  final profileService = ref.watch(profileServiceProvider);
  yield* profileService.watchUserProfile(userId);
});

/// Provider family that watches any user's profile by user ID.
///
/// Returns a [StreamProvider] that:
/// - Emits null when the profile doesn't exist
/// - Emits the UserProfile when it exists
/// - Updates in real-time as the profile changes in Firestore
///
/// Usage:
/// ```dart
/// final profile = ref.watch(userProfileProvider('userId123'));
/// ```
final userProfileProvider =
    StreamProvider.family<UserProfile?, String>((ref, userId) {
  final profileService = ref.watch(profileServiceProvider);
  return profileService.watchUserProfile(userId);
});

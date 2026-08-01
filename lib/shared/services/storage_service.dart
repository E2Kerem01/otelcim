import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the StorageService instance
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Service for managing file uploads to Firebase Storage.
///
/// Handles profile photo uploads and deletions with proper error handling
/// and consistent path structure.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a profile photo to Firebase Storage.
  ///
  /// The photo is stored at `profile_photos/{userId}/profile.jpg` in Firebase Storage.
  /// If a photo already exists at this path, it will be overwritten.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  /// - [imageFile]: The image file to upload
  ///
  /// Returns:
  /// A [Future<String>] containing the download URL of the uploaded photo.
  ///
  /// Throws:
  /// - [FirebaseException] if the upload fails
  /// - [Exception] for other errors during upload
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Define the storage path for the profile photo
      final String path = 'profile_photos/$userId/profile.jpg';
      final Reference ref = _storage.ref().child(path);

      // Set metadata for the file
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final TaskSnapshot uploadTask = await ref.putFile(imageFile, metadata);

      // Get and return the download URL
      final String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload profile photo: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during photo upload: $e');
    }
  }

  /// Deletes a user's profile photo from Firebase Storage.
  ///
  /// Removes the photo stored at `profile_photos/{userId}/profile.jpg`.
  /// If no photo exists at this path, the operation completes successfully.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user whose photo should be deleted
  ///
  /// Throws:
  /// - [FirebaseException] if the deletion fails (except for file-not-found errors)
  /// - [Exception] for other errors during deletion
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // Define the storage path for the profile photo
      final String path = 'profile_photos/$userId/profile.jpg';
      final Reference ref = _storage.ref().child(path);

      // Delete the file
      await ref.delete();
    } on FirebaseException catch (e) {
      // Ignore "object not found" errors - the photo is already gone
      if (e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete profile photo: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during photo deletion: $e');
    }
  }
}

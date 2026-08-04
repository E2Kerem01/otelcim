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

  /// Uploads a verification document to Firebase Storage.
  ///
  /// The document is stored at `verification_documents/{userId}/{timestamp}_{documentType}.{ext}` in Firebase Storage.
  /// This path structure ensures documents are organized by user and easily identifiable by type.
  ///
  /// Parameters:
  /// - [userId]: The unique identifier for the user
  /// - [documentFile]: The document file to upload (e.g., PDF, image)
  /// - [documentType]: The type of document (e.g., 'tax_id', 'tourism_license', 'hotel_registration')
  ///
  /// Returns:
  /// A [Future<String>] containing the download URL of the uploaded document.
  ///
  /// Throws:
  /// - [FirebaseException] if the upload fails
  /// - [Exception] for other errors during upload
  Future<String> uploadVerificationDocument(
    String userId,
    File documentFile,
    String documentType,
  ) async {
    try {
      // Get file extension from the file path
      final String filePath = documentFile.path;
      final String extension = filePath.substring(filePath.lastIndexOf('.'));

      // Create timestamp for unique file naming
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      // Define the storage path for the verification document
      final String path =
          'verification_documents/$userId/${timestamp}_$documentType$extension';
      final Reference ref = _storage.ref().child(path);

      // Determine content type based on file extension
      String contentType = 'application/octet-stream';
      if (extension.toLowerCase() == '.pdf') {
        contentType = 'application/pdf';
      } else if (['.jpg', '.jpeg'].contains(extension.toLowerCase())) {
        contentType = 'image/jpeg';
      } else if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      }

      // Set metadata for the file
      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': userId,
          'documentType': documentType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload the file
      final TaskSnapshot uploadTask = await ref.putFile(documentFile, metadata);

      // Get and return the download URL
      final String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload verification document: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during document upload: $e');
    }
  }

  /// Uploads a banner ad image to Firebase Storage.
  ///
  /// The image is stored at `banner_images/{timestamp}.jpg`.
  /// Returns the download URL string.
  Future<String> uploadBannerImage(File imageFile) async {
    try {
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String path = 'banner_images/$timestamp.jpg';
      final Reference ref = _storage.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final TaskSnapshot uploadTask = await ref.putFile(imageFile, metadata);
      final String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload banner image: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during banner image upload: $e');
    }
  }

  /// Uploads multiple images for a listing to Firebase Storage.
  ///
  /// The images are stored at `listing_images/{listingId}/{index}_{timestamp}.jpg`.
  /// Returns a list of download URL strings.
  Future<List<String>> uploadListingImages(
    String listingId,
    List<File> imageFiles,
  ) async {
    try {
      final List<String> downloadUrls = [];
      final int timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < imageFiles.length; i++) {
        final String path = 'listing_images/$listingId/${i}_$timestamp.jpg';
        final Reference ref = _storage.ref().child(path);

        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'listingId': listingId,
            'imageIndex': i.toString(),
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        );

        final TaskSnapshot uploadTask = await ref.putFile(
          imageFiles[i],
          metadata,
        );
        final String url = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(url);
      }

      return downloadUrls;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload listing images: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during listing image upload: $e');
    }
  }

  Future<List<String>> uploadHousingImages(
    String listingId,
    List<File> imageFiles,
  ) async {
    try {
      final urls = <String>[];
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (var i = 0; i < imageFiles.length; i++) {
        final ref = _storage.ref().child(
          'housing_images/$listingId/${i}_$timestamp.jpg',
        );
        final task = await ref.putFile(
          imageFiles[i],
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'listingId': listingId, 'imageIndex': '$i'},
          ),
        );
        urls.add(await task.ref.getDownloadURL());
      }
      return urls;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload housing images: ${e.message}');
    }
  }

  /// Uploads a jobseeker certificate file to Firebase Storage.
  /// Path: `certificates/{userId}/{certId}`
  Future<String> uploadCertificateFile({
    required String userId,
    required String certId,
    required File file,
  }) async {
    try {
      final String filePath = file.path;
      final String extension = filePath.contains('.')
          ? filePath.substring(filePath.lastIndexOf('.'))
          : '.jpg';

      final String path = 'certificates/$userId/$certId$extension';
      final Reference ref = _storage.ref().child(path);

      String contentType = 'application/octet-stream';
      final extLower = extension.toLowerCase();
      if (extLower == '.pdf') {
        contentType = 'application/pdf';
      } else if (['.jpg', '.jpeg'].contains(extLower)) {
        contentType = 'image/jpeg';
      } else if (extLower == '.png') {
        contentType = 'image/png';
      }

      final SettableMetadata metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': userId,
          'certId': certId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final TaskSnapshot uploadTask = await ref.putFile(file, metadata);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload certificate file: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during certificate upload: $e');
    }
  }

  /// Uploads a profile intro video to Firebase Storage.
  /// Path: `user_videos/{userId}/intro.mp4`
  Future<String> uploadIntroVideo(String userId, File videoFile) async {
    try {
      final String path = 'user_videos/$userId/intro.mp4';
      final Reference ref = _storage.ref().child(path);

      final SettableMetadata metadata = SettableMetadata(
        contentType: 'video/mp4',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final TaskSnapshot uploadTask = await ref.putFile(videoFile, metadata);
      final String downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Failed to upload intro video: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during intro video upload: $e');
    }
  }

  /// Deletes a profile intro video from Firebase Storage.
  Future<void> deleteIntroVideo(String userId) async {
    try {
      final String path = 'user_videos/$userId/intro.mp4';
      final Reference ref = _storage.ref().child(path);
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return;
      throw Exception('Failed to delete intro video: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during intro video deletion: $e');
    }
  }
}

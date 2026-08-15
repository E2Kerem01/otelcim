import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/providers/profile_provider.dart';

/// Widget for selecting and uploading a profile photo.
///
/// Allows users to pick a photo from camera or gallery using image_picker,
/// uploads it to Firebase Storage via StorageService, and displays the
/// current photo using cached_network_image.
///
/// Shows loading state during upload and provides error feedback.
class ProfilePhotoPicker extends ConsumerStatefulWidget {
  /// The current photo URL (if any)
  final String? photoUrl;

  /// The user ID for the photo upload
  final String userId;

  /// Callback when a new photo is successfully uploaded
  final void Function(String photoUrl) onPhotoUploaded;

  const ProfilePhotoPicker({
    super.key,
    this.photoUrl,
    required this.userId,
    required this.onPhotoUploaded,
  });

  @override
  ConsumerState<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends ConsumerState<ProfilePhotoPicker> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  /// Shows a bottom sheet with camera and gallery options
  Future<void> _showPhotoSourceOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickImage(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickImage(ImageSource.gallery));
              },
            ),
            if (widget.photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Fotoğrafı Kaldır',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(_removePhoto());
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Picks an image from the specified source and uploads it
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      await _uploadPhoto(image);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Uploads the selected photo to Firebase Storage
  Future<void> _uploadPhoto(XFile imageFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      final photoUrl = await storageService.uploadProfilePhoto(
        widget.userId,
        imageFile,
      );

      if (!mounted) return;

      widget.onPhotoUploaded(photoUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yüklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  /// Removes the current profile photo
  Future<void> _removePhoto() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteProfilePhoto(widget.userId);

      if (!mounted) return;

      widget.onPhotoUploaded(''); // Empty string indicates no photo

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı kaldırıldı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf kaldırılırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          // Profile photo or placeholder
          GestureDetector(
            onTap: _isUploading ? null : _showPhotoSourceOptions,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.photoUrl!)
                  : null,
              child: widget.photoUrl == null || widget.photoUrl!.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.grey)
                  : null,
            ),
          ),
          // Edit button overlay
          if (!_isUploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _showPhotoSourceOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          // Loading indicator
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

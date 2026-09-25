import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/error/error_mapper.dart';
import '../../../../shared/error/error_reporter.dart';
import '../../../../shared/providers/profile_provider.dart';
import '../../../../shared/widgets/video_player_dialog.dart';

/// Widget for picking, uploading, playing, and deleting a 15-30 second profile intro video.
class IntroVideoPicker extends ConsumerStatefulWidget {
  const IntroVideoPicker({
    super.key,
    this.videoUrl,
    required this.userId,
    required this.onVideoChanged,
  });

  final String? videoUrl;
  final String userId;
  final void Function(String? videoUrl) onVideoChanged;

  @override
  ConsumerState<IntroVideoPicker> createState() => _IntroVideoPickerState();
}

class _IntroVideoPickerState extends ConsumerState<IntroVideoPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  XFile? _localVideoFile;

  Future<void> _showVideoSourceOptions() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.videoCameraAction),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickAndUploadVideo(ImageSource.camera));
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(l10n.videoGalleryAction),
              onTap: () {
                Navigator.pop(context);
                unawaited(_pickAndUploadVideo(ImageSource.gallery));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 30),
      );

      if (pickedFile == null) return;

      // Validate video duration client-side. VideoPlayerController.file()
      // (dart:io) isn't supported on web; XFile.path there is a blob: URL
      // video_player_web can play via networkUrl().
      final tempController = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(pickedFile.path))
          : VideoPlayerController.file(File(pickedFile.path));
      await tempController.initialize();
      final duration = tempController.value.duration;
      await tempController.dispose();

      if (duration.inSeconds > 32) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.videoDurationSelected(duration.inSeconds),
            ),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }

      setState(() {
        _isUploading = true;
        _localVideoFile = pickedFile;
      });

      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadIntroVideo(
        widget.userId,
        pickedFile,
      );

      if (!mounted) return;

      widget.onVideoChanged(downloadUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.videoUploadSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'IntroVideoPicker._pickAndUploadVideo');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapToFailure(error, l10n).message),
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

  Future<void> _removeVideo() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeVideoAction),
        content: Text(l10n.videoRemoveConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.removeVideoAction),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final storageService = ref.read(storageServiceProvider);
      await storageService.deleteIntroVideo(widget.userId);

      if (!mounted) return;

      setState(() {
        _localVideoFile = null;
      });
      widget.onVideoChanged(null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.videoRemoveSuccess)),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'IntroVideoPicker._removeVideo');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapToFailure(error, l10n).message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _watchVideo() {
    final l10n = AppLocalizations.of(context)!;
    unawaited(VideoPlayerDialog.show(
      context,
      videoUrl: widget.videoUrl,
      videoFile: _localVideoFile,
      title: l10n.introVideoTitle,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasVideo = (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) || _localVideoFile != null;

    return Card(
      elevation: 0,
      color: Colors.blue.shade50.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.video_call_rounded, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.introVideoLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.introVideoHint,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (_isUploading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(l10n.videoProcessingLabel, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              )
            else if (hasVideo) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _watchVideo,
                    icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                    label: Text(l10n.watchIntroVideo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showVideoSourceOptions,
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(l10n.changeVideoAction),
                  ),
                  OutlinedButton.icon(
                    onPressed: _removeVideo,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    label: Text(l10n.removeVideoAction, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showVideoSourceOptions,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: Text(l10n.videoUploadButton),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

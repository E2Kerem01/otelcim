import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../domain/certificate_model.dart';
import '../services/certificate_service.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.certificateScreenTitle)),
        body: Center(child: Text(l10n.loginRequiredMessage)),
      );
    }

    final certificatesAsync = ref.watch(userCertificatesProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.certificateWalletTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context, ref, user.uid),
        icon: const Icon(Icons.upload_file_rounded),
        label: Text(l10n.certificateUploadAction),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userCertificatesProvider(user.uid));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withAlpha(80),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 36,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.certificateIntroTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            l10n.certificateIntroDescription,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.certificateUploadedSectionTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            certificatesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.certificateLoadError),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.certificateEmptyTitle,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.certificateEmptyDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cert = items[index];
                    return _CertificateItemCard(cert: cert);
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static void _showUploadSheet(BuildContext context, WidgetRef ref, String userId) {
    unawaited(showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UploadCertificateSheet(userId: userId),
    ));
  }
}

class _CertificateItemCard extends ConsumerWidget {
  const _CertificateItemCard({required this.cert});

  final Certificate cert;

  IconData _getIconForType(CertificateType type) {
    switch (type) {
      case CertificateType.hijyen:
        return Icons.clean_hands_outlined;
      case CertificateType.cankurtaran:
        return Icons.pool_outlined;
      case CertificateType.ehliyet:
        return Icons.drive_eta_outlined;
      case CertificateType.dil:
        return Icons.g_translate_outlined;
      case CertificateType.diger:
        return Icons.card_membership_outlined;
    }
  }

  Future<void> _openDocument(BuildContext context, String url) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.certificateOpenError)),
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.certificateDeleteTitle),
        content: Text(l10n.certificateDeleteConfirmation(
          cert.title ?? certificateTypeLabel(l10n, cert.type),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.certificateDeleteAction),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(certificateServiceProvider).deleteCertificate(certId: cert.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.certificateDeletedMessage)),
          );
        }
      } catch (error, stackTrace) {
        logError(error, stackTrace, context: 'CertificateItemCard._confirmDelete');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(mapToFailure(error, l10n).message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    IconData statusIcon;
    switch (cert.status) {
      case CertificateStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case CertificateStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case CertificateStatus.pending:
        statusColor = Colors.orange.shade800;
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
                  child: Icon(
                    _getIconForType(cert.type),
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title ?? certificateTypeLabel(l10n, cert.type),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        certificateTypeLabel(l10n, cert.type),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        certificateStatusLabel(l10n, cert.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.certificateUploadDate(
                DateFormat('dd.MM.yyyy HH:mm').format(cert.createdAt),
              ),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (cert.isRejected && cert.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.certificateRejectionReason(cert.rejectionReason!),
                        style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openDocument(context, cert.fileUrl),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: Text(l10n.certificateViewAction),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: l10n.certificateDeleteTitle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadCertificateSheet extends ConsumerStatefulWidget {
  const _UploadCertificateSheet({required this.userId});

  final String userId;

  @override
  ConsumerState<_UploadCertificateSheet> createState() =>
      __UploadCertificateSheetState();
}

class __UploadCertificateSheetState
    extends ConsumerState<_UploadCertificateSheet> {
  CertificateType _selectedType = CertificateType.hijyen;
  final _titleController = TextEditingController();
  XFile? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.certificateGalleryAction),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedFile = image;
                    _selectedFileName = image.name;
                    _error = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.certificateCameraAction),
              onTap: () async {
                Navigator.pop(context);
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedFile = image;
                    _selectedFileName = image.name;
                    _error = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(l10n.certificateFileAction),
              onTap: () async {
                Navigator.pop(context);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                  withData: true,
                );
                final picked = result?.files.single;
                final hasUsableData =
                    picked != null && (kIsWeb ? picked.bytes != null : true);
                if (hasUsableData) {
                  setState(() {
                    _selectedFile = picked.xFile;
                    _selectedFileName = picked.name;
                    _error = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedFile == null) {
      setState(() => _error = l10n.certificateSelectionRequired);
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final profile = ref.read(currentUserProfileProvider).value;
      final userName = profile?.displayName;
      final userEmail = profile?.email;

      await ref.read(certificateServiceProvider).uploadCertificate(
            userId: widget.userId,
            userName: userName,
            userEmail: userEmail,
            file: _selectedFile!,
            type: _selectedType,
            title: _titleController.text.trim().isEmpty
                ? null
                : _titleController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.certificateUploadSubmitted)),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'UploadCertificateSheet._upload');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _error = mapToFailure(error, l10n).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.certificateNewTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CertificateType>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: l10n.certificateTypeFieldLabel,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: CertificateType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(certificateTypeLabel(l10n, type)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedType = val);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.certificateTitleFieldLabel,
                hintText: certificateTypeLabel(l10n, _selectedType),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isUploading ? null : _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedFile != null
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade400,
                    width: _selectedFile != null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedFile != null
                      ? Theme.of(context).primaryColor.withAlpha(15)
                      : Colors.grey.shade50,
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedFile != null
                          ? Icons.check_circle_rounded
                          : Icons.cloud_upload_outlined,
                      size: 40,
                      color: _selectedFile != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName ?? l10n.certificateFilePickerPrompt,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedFile != null
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.certificateSupportedFormats,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isUploading ? null : _upload,
              icon: _isUploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isUploading ? l10n.uploadingAction : l10n.submitForReviewAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

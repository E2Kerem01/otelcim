import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/verification_request.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/services/verification_service.dart';

/// Screen for submitting employer verification requests.
///
/// Allows employers to:
/// - Enter hotel name and address
/// - Upload verification documents (tax ID, tourism license, etc.)
/// - Submit request for manual admin review
///
/// Uses Riverpod for state management and shows real-time upload progress.
class VerificationRequestScreen extends ConsumerStatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  ConsumerState<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState
    extends ConsumerState<VerificationRequestScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hotelNameController = TextEditingController();
  final TextEditingController _hotelAddressController = TextEditingController();

  bool _isSubmitting = false;
  bool _isUploading = false;
  final List<String> _documentUrls = [];
  final List<String> _documentNames = [];

  @override
  void dispose() {
    _hotelNameController.dispose();
    _hotelAddressController.dispose();
    super.dispose();
  }

  /// Shows a file picker for selecting verification documents
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final hasUsableData = kIsWeb ? file.bytes != null : true;
      if (!hasUsableData) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya seçilirken hata oluştu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _uploadDocument(file.xFile, file.name);
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationRequestScreen._pickDocument');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapToFailure(error).message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Uploads a document to Firebase Storage
  Future<void> _uploadDocument(XFile file, String fileName) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;

      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final storageService = ref.read(storageServiceProvider);
      final documentUrl = await storageService.uploadVerificationDocument(
        currentUser.uid,
        file,
        'verification_doc',
      );

      if (!mounted) return;

      setState(() {
        _documentUrls.add(documentUrl);
        _documentNames.add(fileName);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belge yüklendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationRequestScreen._uploadDocument');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapToFailure(error).message),
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

  /// Removes a document from the list
  void _removeDocument(int index) {
    setState(() {
      _documentUrls.removeAt(index);
      _documentNames.removeAt(index);
    });
  }

  /// Submits the verification request
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_documentUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir belge yüklemeniz gerekiyor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;

      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final verificationService = ref.read(verificationServiceProvider);
      final now = DateTime.now();

      // Create verification request
      final request = VerificationRequest(
        id: '${currentUser.uid}_${now.millisecondsSinceEpoch}',
        userId: currentUser.uid,
        userEmail: currentUser.email,
        hotelName: _hotelNameController.text.trim(),
        hotelAddress: _hotelAddressController.text.trim(),
        documentUrls: _documentUrls,
        status: 'pending',
        requestedAt: now,
      );

      await verificationService.submitVerificationRequest(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doğrulama talebi gönderildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back on successful submission
      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'VerificationRequestScreen._submitRequest');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapToFailure(error).message),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Otel Doğrulama'),
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _submitRequest,
              tooltip: 'Gönder',
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Profil yüklenirken hata oluştu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (profile) {
          // Pre-fill hotel name from profile if available
          if (_hotelNameController.text.isEmpty &&
              profile?.hotelName != null) {
            _hotelNameController.text = profile!.hotelName!;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Information card
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Doğrulama Hakkında',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Otelinizi doğrulamak için vergi kimlik belgesi, turizm işletme belgesi veya otel kayıt belgesi yüklemeniz gerekmektedir. '
                            'Yüklediğiniz belgeler güvenli bir şekilde saklanır ve sadece yöneticiler tarafından incelenebilir.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Hotel name field
                  TextFormField(
                    controller: _hotelNameController,
                    decoration: const InputDecoration(
                      labelText: 'Otel Adı',
                      hintText: 'Otelinizin resmi adını girin',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Otel adı gereklidir';
                      }
                      if (value.trim().length < 3) {
                        return 'Otel adı en az 3 karakter olmalıdır';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Hotel address field
                  TextFormField(
                    controller: _hotelAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Otel Adresi',
                      hintText: 'Otelinizin tam adresini girin',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Otel adresi gereklidir';
                      }
                      if (value.trim().length < 10) {
                        return 'Lütfen tam adres girin';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),

                  // Documents section
                  Text(
                    'Doğrulama Belgeleri',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vergi kimlik belgesi, turizm işletme belgesi veya otel kayıt belgesi yükleyin (PDF, JPG, PNG)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // Uploaded documents list
                  if (_documentNames.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _documentNames.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file,
                                color: Colors.blue),
                            title: Text(_documentNames[index]),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () => _removeDocument(index),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // Add document button
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickDocument,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isUploading ? 'Yükleniyor...' : 'Belge Ekle',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed:
                        (_isSubmitting || _isUploading) ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Doğrulama Talebini Gönder'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

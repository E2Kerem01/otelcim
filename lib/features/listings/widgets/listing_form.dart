import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/listing.dart';

/// A reusable form widget for creating and editing job listings.
///
/// This widget provides a complete form with validation for all listing fields:
/// - Title (required)
/// - Description (required)
/// - Category (required, dropdown selection)
/// - Location (required)
/// - Salary (required, numeric format)
/// - Images (optional, up to 5 images)
///
/// The form can be used in two modes:
/// 1. Create mode: Pass `null` for [initialListing]
/// 2. Edit mode: Pass an existing [Listing] to pre-fill the form
///
/// Example usage:
/// ```dart
/// ListingForm(
///   initialListing: existingListing, // or null for create mode
///   onSubmit: (data) async {
///     // Save the listing data
///   },
/// )
/// ```
class ListingForm extends StatefulWidget {
  /// Optional initial listing data for edit mode.
  /// If null, the form starts empty (create mode).
  final Listing? initialListing;

  /// Callback invoked when the form is submitted with valid data.
  /// The [data] map contains all form field values.
  final Future<void> Function(Map<String, dynamic> data) onSubmit;

  const ListingForm({
    super.key,
    this.initialListing,
    required this.onSubmit,
  });

  @override
  State<ListingForm> createState() => _ListingFormState();
}

class _ListingFormState extends State<ListingForm> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  // Form controllers
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _salaryController;

  // Selected category
  String? _selectedCategory;

  // Image management
  final List<String> _existingImageUrls = [];
  final List<File> _newImageFiles = [];
  bool _isSubmitting = false;

  /// Common job categories in the hospitality industry
  static const List<String> categories = [
    'Resepsiyon',
    'Kat Hizmetleri',
    'Mutfak',
    'Servis / Garson',
    'Bar',
    'Yönetim',
    'Muhasebe',
    'Güvenlik',
    'Teknik Servis',
    'SPA / Wellness',
    'Animasyon',
    'Satış / Pazarlama',
    'İnsan Kaynakları',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if in edit mode
    final initial = widget.initialListing;
    _titleController = TextEditingController(text: initial?.title ?? '');
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _locationController = TextEditingController(text: initial?.location ?? '');
    _salaryController = TextEditingController(text: initial?.salary ?? '');

    // Set initial category
    if (initial?.category != null && categories.contains(initial!.category)) {
      _selectedCategory = initial.category;
    }

    // Set initial images
    if (initial?.imageUrls != null) {
      _existingImageUrls.addAll(initial!.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  /// Validates that a field is not empty
  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  /// Validates salary format (must be a valid number or range)
  String? _salaryValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Maaş bilgisi gereklidir';
    }

    // Allow formats like: "15000", "15000-20000", "15.000 TL", etc.
    final cleanValue = value.replaceAll(RegExp(r'[^\d-]'), '');
    if (cleanValue.isEmpty) {
      return 'Geçerli bir maaş değeri giriniz';
    }

    return null;
  }

  /// Picks images from the gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isEmpty) return;

      setState(() {
        // Limit total images to 5
        final remainingSlots = 5 - _existingImageUrls.length - _newImageFiles.length;
        final imagesToAdd = images.take(remainingSlots).toList();

        for (final image in imagesToAdd) {
          _newImageFiles.add(File(image.path));
        }
      });

      if (images.length > 5 - _existingImageUrls.length - _newImageFiles.length) {
        _showSnackBar('Maksimum 5 fotoğraf ekleyebilirsiniz');
      }
    } catch (e) {
      _showSnackBar('Fotoğraf seçilirken hata oluştu: $e');
    }
  }

  /// Takes a photo using the camera
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) return;

      setState(() {
        if (_existingImageUrls.length + _newImageFiles.length < 5) {
          _newImageFiles.add(File(photo.path));
        } else {
          _showSnackBar('Maksimum 5 fotoğraf ekleyebilirsiniz');
        }
      });
    } catch (e) {
      _showSnackBar('Fotoğraf çekilirken hata oluştu: $e');
    }
  }

  /// Removes an existing image URL
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  /// Removes a new image file
  void _removeNewImage(int index) {
    setState(() {
      _newImageFiles.removeAt(index);
    });
  }

  /// Shows a snackbar message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Handles form submission
  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check that category is selected
    if (_selectedCategory == null) {
      _showSnackBar('Lütfen bir kategori seçiniz');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Prepare form data
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory!,
        'location': _locationController.text.trim(),
        'salary': _salaryController.text.trim(),
        'existingImageUrls': _existingImageUrls,
        'newImageFiles': _newImageFiles,
      };

      // Call the submit callback
      await widget.onSubmit(data);
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
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Title field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'İlan Başlığı *',
              hintText: 'örn: Deneyimli Resepsiyon Görevlisi',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _requiredValidator(value, 'İlan başlığı'),
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: 16),

          // Category dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Kategori *',
              border: OutlineInputBorder(),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
            validator: (value) => _requiredValidator(value, 'Kategori'),
          ),

          const SizedBox(height: 16),

          // Location field
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Lokasyon *',
              hintText: 'örn: Antalya - Belek',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _requiredValidator(value, 'Lokasyon'),
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: 16),

          // Salary field
          TextFormField(
            controller: _salaryController,
            decoration: const InputDecoration(
              labelText: 'Maaş *',
              hintText: 'örn: 15.000 TL veya 15.000-20.000 TL',
              border: OutlineInputBorder(),
              prefixText: '₺ ',
            ),
            keyboardType: TextInputType.text,
            validator: _salaryValidator,
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: 16),

          // Description field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'İş Tanımı *',
              hintText: 'İş tanımı, gereksinimler ve çalışma koşulları...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => _requiredValidator(value, 'İş tanımı'),
            enabled: !_isSubmitting,
          ),

          const SizedBox(height: 24),

          // Images section
          Text(
            'Fotoğraflar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Maksimum 5 fotoğraf ekleyebilirsiniz',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),

          // Display existing and new images
          if (_existingImageUrls.isNotEmpty || _newImageFiles.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _existingImageUrls.length + _newImageFiles.length,
                itemBuilder: (context, index) {
                  final isExisting = index < _existingImageUrls.length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        // Image preview
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isExisting
                                ? Image.network(
                                    _existingImageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(Icons.error),
                                      );
                                    },
                                  )
                                : Image.file(
                                    _newImageFiles[index - _existingImageUrls.length],
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        // Remove button
                        if (!_isSubmitting)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                if (isExisting) {
                                  _removeExistingImage(index);
                                } else {
                                  _removeNewImage(index - _existingImageUrls.length);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 12),

          // Image picker buttons
          if (_existingImageUrls.length + _newImageFiles.length < 5)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeriden Seç'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Fotoğraf Çek'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Submit button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.initialListing == null ? 'İlanı Yayınla' : 'Değişiklikleri Kaydet',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),

          const SizedBox(height: 16),

          // Required fields note
          const Text(
            '* Zorunlu alanlar',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

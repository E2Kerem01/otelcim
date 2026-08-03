import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/storage_service.dart';
import '../domain/listing_model.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  ListingCategory _selectedCategory = ListingCategory.resepsiyon;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _salaryController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final List<File> _selectedImageFiles = [];
  bool _submitting = false;
  String? _selectedCity;
  EmploymentType _employmentType = EmploymentType.fullTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _salaryController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 5 fotoğraf ekleyebilirsiniz.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      final availableSlots = 5 - _selectedImageFiles.length;
      final filesToAdd = pickedFiles
          .take(availableSlots)
          .map((xFile) => File(xFile.path))
          .toList();

      setState(() {
        _selectedImageFiles.addAll(filesToAdd);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan yayınlamak için lütfen giriş yapın.')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final listingId = await ref.read(listingServiceProvider).createListing(
            Listing(
              id: '',
              posterId: user.uid,
              posterName: user.email,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory.name,
              location: _locationController.text.trim(),
              salary: _salaryController.text.trim(),
              city: _selectedCity,
              minSalaryTl: int.tryParse(_minSalaryController.text.trim()),
              maxSalaryTl: int.tryParse(_maxSalaryController.text.trim()),
              employmentType: _employmentType,
              contactInfo: _contactController.text.trim(),
            ),
          );

      if (_selectedImageFiles.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        final imageUrls = await storageService.uploadListingImages(listingId, _selectedImageFiles);

        final existingListing = await ref.read(listingServiceProvider).getListing(listingId);
        if (existingListing != null) {
          await ref.read(listingServiceProvider).updateListing(
                Listing(
                  id: existingListing.id,
                  posterId: existingListing.posterId,
                  posterName: existingListing.posterName,
                  title: existingListing.title,
                  description: existingListing.description,
                  category: existingListing.category,
                  location: existingListing.location,
                  salary: existingListing.salary,
                  city: existingListing.city,
                  minSalaryTl: existingListing.minSalaryTl,
                  maxSalaryTl: existingListing.maxSalaryTl,
                  employmentType: existingListing.employmentType,
                  contactInfo: existingListing.contactInfo,
                  images: imageUrls,
                  status: existingListing.status,
                  createdAt: existingListing.createdAt,
                ),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlanınız başarıyla yayınlandı!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İlan Aç')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<ListingCategory>(
                initialValue: _selectedCategory,
                items: ListingCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(listingCategoryLabels[c]!)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('İlan Başlığı', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Örn. Bodrum Resort Resepsiyon Görevlisi'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Image Picker Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('İlan Fotoğrafları', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${_selectedImageFiles.length}/5',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImageFiles.length + (_selectedImageFiles.length < 5 ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == _selectedImageFiles.length) {
                      return InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              SizedBox(height: 4),
                              Text('Fotoğraf Ekle', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }

                    final file = _selectedImageFiles[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            file,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedImageFiles.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black60,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const Text('Konum (İl / İlçe)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(hintText: 'Örn. Muğla / Bodrum'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Konum gerekli' : null,
              ),
              const SizedBox(height: 16),
              const Text('Şehir', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                hint: const Text('Şehir seçin'),
                items: turkishTourismCities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                onChanged: (value) => setState(() => _selectedCity = value),
                validator: (value) => value == null ? 'Şehir seçmeniz gerekiyor' : null,
              ),
              const SizedBox(height: 16),
              const Text('Maaş', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(hintText: 'Örn. 35.000₺ + yemek'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Maaş bilgisi gerekli' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'En düşük maaş (TL)'),
                      validator: _salaryValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'En yüksek maaş (TL)'),
                      validator: _salaryValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Çalışma tipi', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<EmploymentType>(
                initialValue: _employmentType,
                items: EmploymentType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.label))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _employmentType = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('İletişim', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(hintText: 'Örn. 0555 123 4567'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'İletişim bilgisi gerekli' : null,
              ),
              const SizedBox(height: 16),
              const Text('İlan Açıklaması', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'İlanınızla ilgili tüm detayları açıklayın...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama gerekli' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('İlanı Yayınla'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _salaryValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Geçerli tutar girin';
    final min = int.tryParse(_minSalaryController.text.trim());
    final max = int.tryParse(_maxSalaryController.text.trim());
    if (min != null && max != null && min > max) return 'Aralığı kontrol edin';
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/xfile_preview_image.dart';
import '../domain/listing_model.dart';

class PositionFormData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController minSalaryController = TextEditingController();
  final TextEditingController maxSalaryController = TextEditingController();
  ListingCategory selectedCategory = ListingCategory.resepsiyon;
  EmploymentType employmentType = EmploymentType.fullTime;

  void dispose() {
    titleController.dispose();
    descController.dispose();
    salaryController.dispose();
    minSalaryController.dispose();
    maxSalaryController.dispose();
  }
}

class BatchCreateListingScreen extends ConsumerStatefulWidget {
  const BatchCreateListingScreen({super.key});

  @override
  ConsumerState<BatchCreateListingScreen> createState() => _BatchCreateListingScreenState();
}

class _BatchCreateListingScreenState extends ConsumerState<BatchCreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final List<XFile> _selectedImageFiles = [];
  final List<PositionFormData> _positions = [];
  String? _selectedCity;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _addPosition();
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    for (final pos in _positions) {
      pos.dispose();
    }
    super.dispose();
  }

  void _addPosition() {
    if (_positions.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 20 pozisyon ekleyebilirsiniz.')),
      );
      return;
    }
    setState(() {
      _positions.add(PositionFormData());
    });
  }

  void _removePosition(int index) {
    if (_positions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az 1 pozisyon bulunmalıdır.')),
      );
      return;
    }
    setState(() {
      final removed = _positions.removeAt(index);
      removed.dispose();
    });
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
      final filesToAdd = pickedFiles.take(availableSlots).toList();

      setState(() {
        _selectedImageFiles.addAll(filesToAdd);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm pozisyon ve otel bilgilerini eksiksiz doldurun.')),
      );
      return;
    }

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
      final hotelName = _hotelNameController.text.trim();
      final location = _locationController.text.trim();
      final contactInfo = _contactController.text.trim();

      List<String> imageUrls = [];
      var imageUploadFailed = false;
      if (_selectedImageFiles.isNotEmpty) {
        try {
          final storageService = ref.read(storageServiceProvider);
          final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
          imageUrls = await storageService.uploadListingImages(batchId, _selectedImageFiles);
        } catch (e) {
          debugPrint('Batch listing image upload failed, publishing without photos: $e');
          imageUploadFailed = true;
        }
      }

      final listingsToCreate = _positions.map((pos) {
        return Listing(
          id: '',
          posterId: user.uid,
          posterName: hotelName.isNotEmpty ? hotelName : (user.email ?? ''),
          title: pos.titleController.text.trim(),
          description: pos.descController.text.trim(),
          category: pos.selectedCategory.name,
          location: location,
          salary: pos.salaryController.text.trim(),
          city: _selectedCity,
          minSalaryTl: int.tryParse(pos.minSalaryController.text.trim()),
          maxSalaryTl: int.tryParse(pos.maxSalaryController.text.trim()),
          employmentType: pos.employmentType,
          contactInfo: contactInfo,
          images: imageUrls,
        );
      }).toList();

      await ref.read(listingServiceProvider).createBatchListings(listingsToCreate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageUploadFailed
                  ? '${listingsToCreate.length} adet ilan yayınlandı, ancak otel fotoğrafları yüklenemedi.'
                  : '${listingsToCreate.length} adet ilan başarıyla yayınlandı!',
            ),
            backgroundColor: imageUploadFailed ? Colors.orange.shade800 : null,
          ),
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
      appBar: AppBar(
        title: const Text('Toplu İlan Ver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hotel_rounded, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Otel / İşletme Bilgileri',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Otel / İşletme Adı', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _hotelNameController,
                        decoration: const InputDecoration(hintText: 'Örn. Grand Deluxe Hotel'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Otel adı gereklidir' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Konum (İl / İlçe)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(hintText: 'Örn. Muğla / Bodrum'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Konum gereklidir' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Şehir', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        hint: const Text('Şehir seçin'),
                        items: turkishTourismCities
                            .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCity = value),
                        validator: (value) => value == null ? 'Şehir seçmeniz gerekiyor' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('İletişim Bilgisi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactController,
                        decoration: const InputDecoration(hintText: 'Örn. 0555 123 4567 / ik@hotel.com'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'İletişim bilgisi gereklidir' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Otel Fotoğrafları', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${_selectedImageFiles.length}/5',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImageFiles.length + (_selectedImageFiles.length < 5 ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == _selectedImageFiles.length) {
                              return InkWell(
                                onTap: _pickImages,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 20),
                                      SizedBox(height: 4),
                                      Text('Ekle', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final file = _selectedImageFiles[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: XFilePreviewImage(
                                    file,
                                    width: 80,
                                    height: 80,
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
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Positions Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pozisyonlar (${_positions.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: _positions.length < 20 ? _addPosition : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Pozisyon Ekle'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Position Cards List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _positions.length,
                itemBuilder: (context, index) {
                  final pos = _positions[index];
                  return Container(
                    key: ValueKey(pos),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  avatar: CircleAvatar(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  label: Text('Pozisyon #${index + 1}'),
                                ),
                                if (_positions.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    tooltip: 'Pozisyonu Sil',
                                    onPressed: () => _removePosition(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<ListingCategory>(
                              initialValue: pos.selectedCategory,
                              items: ListingCategory.values
                                  .map((c) => DropdownMenuItem(value: c, child: Text(listingCategoryLabels[c]!)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => pos.selectedCategory = val);
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text('Pozisyon Başlığı', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.titleController,
                              decoration: const InputDecoration(hintText: 'Örn. Resepsiyonist / Garson / Aşçı'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gereklidir' : null,
                            ),
                            const SizedBox(height: 12),
                            const Text('Çalışma Tipi', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<EmploymentType>(
                              initialValue: pos.employmentType,
                              items: EmploymentType.values
                                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => pos.employmentType = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            const Text('Maaş Bilgisi', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.salaryController,
                              decoration: const InputDecoration(hintText: 'Örn. 35.000₺ + yemek + lojman'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Maaş bilgisi gereklidir' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: pos.minSalaryController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'En Düşük Maaş (TL)'),
                                    validator: (v) => _salaryRangeValidator(pos),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: pos.maxSalaryController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'En Yüksek Maaş (TL)'),
                                    validator: (v) => _salaryRangeValidator(pos),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Pozisyon Açıklaması', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.descController,
                              maxLines: 3,
                              decoration: const InputDecoration(hintText: 'Pozisyon detayları ve aranan nitelikler...'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama gereklidir' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Publish Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.rocket_launch_rounded),
                  label: Text(
                    _submitting
                        ? 'İlanlar Yayınlanıyor...'
                        : '${_positions.length} İlanı Atomik Yayınla',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String? _salaryRangeValidator(PositionFormData pos) {
    final minVal = int.tryParse(pos.minSalaryController.text.trim());
    final maxVal = int.tryParse(pos.maxSalaryController.text.trim());
    if (minVal != null && maxVal != null && minVal > maxVal) {
      return 'Aralığı kontrol edin';
    }
    return null;
  }
}

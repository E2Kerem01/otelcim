import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/constants/categories.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../domain/listing_model.dart';

final _editListingProvider = FutureProvider.family<Listing?, String>((ref, id) {
  return ref.watch(listingServiceProvider).getListing(id);
});

class EditListingScreen extends ConsumerStatefulWidget {
  final String listingId;

  const EditListingScreen({super.key, required this.listingId});

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  ListingCategory? _selectedCategory;
  bool _initialized = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _initializeForm(Listing listing) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = listing.title;
    _descController.text = listing.description;
    _salaryController.text = listing.salary;
    _locationController.text = listing.location;
    _contactController.text = listing.contactInfo;
    _selectedCategory = ListingCategory.values.firstWhere(
      (c) => c.name == listing.category,
      orElse: () => ListingCategory.diger,
    );
  }

  Future<void> _submit(Listing original) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await ref.read(listingServiceProvider).updateListing(
            Listing(
              id: original.id,
              posterId: original.posterId,
              posterName: original.posterName,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory!.name,
              location: _locationController.text.trim(),
              salary: _salaryController.text.trim(),
              contactInfo: _contactController.text.trim(),
              status: original.status,
              createdAt: original.createdAt,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan güncellendi.')),
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

  Future<void> _toggleStatus(Listing listing) async {
    setState(() => _submitting = true);
    try {
      final service = ref.read(listingServiceProvider);
      if (listing.status == ListingStatus.active) {
        await service.closeListing(listing.id);
      } else {
        await service.reactivateListing(listing.id);
      }
      ref.invalidate(_editListingProvider(widget.listingId));
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
    final listingAsync = ref.watch(_editListingProvider(widget.listingId));
    final currentUid = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('İlanı Düzenle')),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
        data: (listing) {
          if (listing == null) {
            return const Center(child: Text('İlan bulunamadı.'));
          }
          if (currentUid == null || listing.posterId != currentUid) {
            return const Center(child: Text('Bu ilanı düzenleme yetkiniz yok.'));
          }

          _initializeForm(listing);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Durum: ${listing.status == ListingStatus.active ? 'Aktif' : 'Kapalı'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : () => _toggleStatus(listing),
                        child: Text(listing.status == ListingStatus.active ? 'Kapat' : 'Tekrar Aktifleştir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Konum (İl / İlçe)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Konum gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('Maaş', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _salaryController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Maaş bilgisi gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('İletişim', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contactController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'İletişim bilgisi gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text('İlan Açıklaması', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Açıklama gerekli' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submit(listing),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Değişiklikleri Kaydet'),
                    ),
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

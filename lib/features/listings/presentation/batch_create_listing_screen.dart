import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/xfile_preview_image.dart';
import '../domain/listing_model.dart';
import 'listing_filter_labels.dart';
import 'widgets/listing_form_fields.dart';

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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.listingMaxPositions(20))),
      );
      return;
    }
    setState(() {
      _positions.add(PositionFormData());
    });
  }

  void _removePosition(int index) {
    if (_positions.length <= 1) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.listingMinPosition)),
      );
      return;
    }
    setState(() {
      final removed = _positions.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedImageFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.listingMaxPhotos(5))),
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
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.listingRequiredFields)),
      );
      return;
    }

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.listingPublishLoginRequired)),
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
      String? imageUploadFailureMessage;
      if (_selectedImageFiles.isNotEmpty) {
        try {
          final storageService = ref.read(storageServiceProvider);
          final batchId = 'batch_${DateTime.now().millisecondsSinceEpoch}';
          imageUrls = await storageService.uploadListingImages(user.uid, batchId, _selectedImageFiles);
        } catch (error, stackTrace) {
          logError(error, stackTrace, context: 'BatchCreateListingScreen._submit.imageUpload');
          imageUploadFailed = true;
          imageUploadFailureMessage = mapToFailure(error).message;
        }
      }

      final listingsToCreate = _positions.map((pos) {
        return Listing(
          id: '',
          posterId: user.uid,
          posterName: hotelName.isNotEmpty ? hotelName : user.email,
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
                  ? imageUploadFailureMessage!
                  : l10n.listingBatchPublished(listingsToCreate.length),
            ),
            backgroundColor: imageUploadFailed ? Colors.orange.shade800 : null,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: 'BatchCreateListingScreen._submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.listingBatchTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RequiredFieldsLegend(),
              const SizedBox(height: 12),
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
                          Text(
                            l10n.listingBatchHotelInfo,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListingFieldLabel(l10n.listingHotelNameLabel, isRequired: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _hotelNameController,
                        autofillHints: const <String>[],
                        decoration: InputDecoration(hintText: l10n.listingHotelNameHint),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingHotelNameRequired : null,
                      ),
                      const SizedBox(height: 16),
                      ListingFieldLabel(l10n.listingLocationLabel, isRequired: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        autofillHints: const <String>[],
                        decoration: InputDecoration(hintText: l10n.listingLocationHint),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingLocationRequired : null,
                      ),
                      const SizedBox(height: 16),
                      ListingFieldLabel(l10n.listingCityLabel, isRequired: true),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCity,
                        hint: Text(l10n.listingCitySelect),
                        items: turkishTourismCities
                            .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                            .toList(),
                        onChanged: (value) => setState(() => _selectedCity = value),
                        validator: (value) => value == null ? l10n.listingCityRequired : null,
                      ),
                      const SizedBox(height: 16),
                      ListingFieldLabel(l10n.listingContactInfoLabel, isRequired: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contactController,
                        autofillHints: const <String>[],
                        decoration: InputDecoration(hintText: l10n.listingContactHint),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingContactRequired : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.listingPhotosLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            l10n.listingPhotoCount(_selectedImageFiles.length),
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
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                                      Text(l10n.listingAddPhoto, style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                    l10n.listingBatchPositionCount(_positions.length),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  OutlinedButton.icon(
                    onPressed: _positions.length < 20 ? _addPosition : null,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.listingAddPosition),
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
                                  label: Text(l10n.listingPositionNumber(index + 1)),
                                ),
                                if (_positions.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    tooltip: l10n.listingDeletePosition,
                                    onPressed: () => _removePosition(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(l10n.listingCategoryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<ListingCategory>(
                              initialValue: pos.selectedCategory,
                              items: ListingCategory.values
                                  .map((c) => DropdownMenuItem(value: c, child: Text(listingCategoryLabelFor(l10n, c.name))))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => pos.selectedCategory = val);
                              },
                            ),
                            const SizedBox(height: 12),
                            ListingFieldLabel(l10n.listingBatchPositionLabel, isRequired: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.titleController,
                              autofillHints: const <String>[],
                              decoration: InputDecoration(hintText: l10n.listingBatchPositionHint),
                              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingBatchTitleRequired : null,
                            ),
                            const SizedBox(height: 12),
                            Text(l10n.listingEmploymentTypeLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<EmploymentType>(
                              initialValue: pos.employmentType,
                              items: EmploymentType.values
                                  .map((type) => DropdownMenuItem(value: type, child: Text(employmentTypeLabel(l10n, type))))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => pos.employmentType = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            ListingFieldLabel(l10n.listingSalaryInfoLabel, isRequired: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.salaryController,
                              autofillHints: const <String>[],
                              decoration: InputDecoration(hintText: l10n.listingBatchSalaryHint),
                              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingBatchSalaryRequired : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: pos.minSalaryController,
                                    autofillHints: const <String>[],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: l10n.listingMinSalaryInput),
                                    validator: (v) => _salaryRangeValidator(context, pos),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: pos.maxSalaryController,
                                    autofillHints: const <String>[],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(labelText: l10n.listingMaxSalaryInput),
                                    validator: (v) => _salaryRangeValidator(context, pos),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListingFieldLabel(l10n.listingBatchDescriptionLabel, isRequired: true),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: pos.descController,
                              autofillHints: const <String>[],
                              maxLines: 3,
                              decoration: InputDecoration(hintText: l10n.listingBatchDescriptionHint),
                              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.listingBatchDescriptionRequired : null,
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
                        ? l10n.listingBatchPublishLoading
                        : l10n.listingBatchPublishAction(_positions.length),
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

  String? _salaryRangeValidator(BuildContext context, PositionFormData pos) {
    final minVal = int.tryParse(pos.minSalaryController.text.trim());
    final maxVal = int.tryParse(pos.maxSalaryController.text.trim());
    if (minVal != null && maxVal != null && minVal > maxVal) {
      return AppLocalizations.of(context)!.listingSalaryRangeInvalid;
    }
    return null;
  }
}

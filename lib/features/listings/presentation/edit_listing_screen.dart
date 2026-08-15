import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/constants/categories.dart';
import '../../../shared/constants/listing_filters.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/listing_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../../shared/widgets/xfile_preview_image.dart';
import '../../boosts/presentation/widgets/boost_badge.dart';
import '../domain/listing_model.dart';
import 'season_utils.dart';
import 'widgets/listing_form_fields.dart';

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
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _staffShuttleRouteController = TextEditingController();
  ListingCategory? _selectedCategory;
  bool _initialized = false;
  bool _submitting = false;
  String? _selectedCity;
  String? _selectedRegion;
  EmploymentType? _employmentType;
  ExperienceLevel? _experienceLevel;
  EducationLevel? _educationLevel;
  String? _season;
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;
  List<String> _existingImageUrls = [];
  final List<XFile> _newImageFiles = [];
  List<String> _existingHousingImageUrls = [];
  final List<XFile> _newHousingImageFiles = [];
  String? _housingRoomType;
  bool _housingHasAc = false;
  bool _housingHasWifi = false;
  int? _housingMealsIncluded;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _salaryController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _staffShuttleRouteController.dispose();
    super.dispose();
  }

  void _initializeForm(Listing listing) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = listing.title;
    _descController.text = listing.description;
    _salaryController.text = listing.salary;
    _minSalaryController.text = listing.minSalaryTl?.toString() ?? '';
    _maxSalaryController.text = listing.maxSalaryTl?.toString() ?? '';
    _selectedCity = listing.city;
    _selectedRegion = listing.region;
    _employmentType = listing.employmentType;
    _experienceLevel = ExperienceLevel.fromName(listing.experienceLevel);
    _educationLevel = EducationLevel.fromName(listing.educationLevel);
    _season = listing.season;
    _contractStartDate = listing.contractStartDate;
    _contractEndDate = listing.contractEndDate;
    _locationController.text = listing.location;
    _contactController.text = listing.contactInfo;
    _staffShuttleRouteController.text = listing.staffShuttleRoute ?? '';
    _existingImageUrls = List<String>.from(listing.images);
    _existingHousingImageUrls = List<String>.from(listing.housingImages);
    _housingRoomType = listing.housingRoomType;
    _housingHasAc = listing.housingHasAc ?? false;
    _housingHasWifi = listing.housingHasWifi ?? false;
    _housingMealsIncluded = listing.housingMealsIncluded;
    _selectedCategory = ListingCategory.values.firstWhere(
      (c) => c.name == listing.category,
      orElse: () => ListingCategory.diger,
    );
  }

  Future<void> _pickNewImages() async {
    final totalCount = _existingImageUrls.length + _newImageFiles.length;
    if (totalCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En fazla 5 fotoğraf ekleyebilirsiniz.')),
      );
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      final availableSlots = 5 - totalCount;
      final filesToAdd = pickedFiles.take(availableSlots).toList();

      setState(() {
        _newImageFiles.addAll(filesToAdd);
      });
    }
  }

  Future<void> _pickHousingImages() async {
    final total =
        _existingHousingImageUrls.length + _newHousingImageFiles.length;
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (!mounted || picked.isEmpty) return;
    setState(
      () => _newHousingImageFiles.addAll(picked.take(5 - total)),
    );
  }

  Future<void> _submit(Listing original) async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    if (isSeasonalContract(_season) &&
        (_contractStartDate == null || _contractEndDate == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contractDatesRequired)));
      return;
    }
    if (_contractStartDate != null &&
        _contractEndDate != null &&
        _contractEndDate!.isBefore(_contractStartDate!)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contractDateRangeInvalid)));
      return;
    }

    setState(() => _submitting = true);
    try {
      List<String> finalImages = List<String>.from(_existingImageUrls);
      final housingImages = List<String>.from(_existingHousingImageUrls);

      if (_newImageFiles.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        final uploadedUrls = await storageService.uploadListingImages(
          original.posterId,
          original.id,
          _newImageFiles,
        );
        finalImages.addAll(uploadedUrls);
      }
      if (_newHousingImageFiles.isNotEmpty) {
        housingImages.addAll(
          await ref
              .read(storageServiceProvider)
              .uploadHousingImages(original.posterId, original.id, _newHousingImageFiles),
        );
      }

      await ref
          .read(listingServiceProvider)
          .updateListing(
            Listing(
              id: original.id,
              posterId: original.posterId,
              posterName: original.posterName,
              posterVerified: original.posterVerified,
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory!.name,
              location: _locationController.text.trim(),
              salary: _salaryController.text.trim(),
              city: _selectedCity,
              region: _selectedRegion,
              minSalaryTl: int.tryParse(_minSalaryController.text.trim()),
              maxSalaryTl: int.tryParse(_maxSalaryController.text.trim()),
              employmentType: _employmentType,
              experienceLevel: _experienceLevel?.name,
              educationLevel: _educationLevel?.name,
              season: _season,
              contractStartDate: _contractStartDate,
              contractEndDate: _contractEndDate,
              contactInfo: _contactController.text.trim(),
              images: finalImages,
              housingRoomType: _housingRoomType,
              housingHasAc: _housingRoomType == null ? null : _housingHasAc,
              housingHasWifi: _housingRoomType == null ? null : _housingHasWifi,
              housingMealsIncluded: _housingMealsIncluded,
              housingImages: housingImages,
              staffShuttleRoute:
                  _staffShuttleRouteController.text.trim().isEmpty
                  ? null
                  : _staffShuttleRouteController.text.trim(),
              status: original.status,
              createdAt: original.createdAt,
              updatedAt: original.updatedAt,
              isBoosted: original.isBoosted,
              boostExpiresAt: original.boostExpiresAt,
              boostType: original.boostType,
              boostPurchaseId: original.boostPurchaseId,
              viewCount: original.viewCount,
              messageCount: original.messageCount,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('İlan güncellendi.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
            return const Center(
              child: Text('Bu ilanı düzenleme yetkiniz yok.'),
            );
          }

          _initializeForm(listing);
          final isBoostedActive = BoostBadge.isBoostActive(listing);
          final totalImageCount =
              _existingImageUrls.length + _newImageFiles.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Boost Promotion Card
                  Card(
                    color: isBoostedActive
                        ? Colors.amber.shade50
                        : Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isBoostedActive
                            ? Colors.amber.shade300
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.rocket_launch_rounded,
                            size: 32,
                            color: isBoostedActive
                                ? Colors.amber.shade900
                                : Colors.orange.shade800,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isBoostedActive
                                          ? 'İlan Öne Çıkarıldı'
                                          : 'İlanınızı Öne Çıkarın',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isBoostedActive
                                            ? Colors.amber.shade900
                                            : Colors.orange.shade900,
                                      ),
                                    ),
                                    if (isBoostedActive) ...[
                                      const SizedBox(width: 6),
                                      const BoostBadge(isCompact: true),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isBoostedActive
                                      ? 'Bitiş Tarihi: ${listing.boostExpiresAt!.day}.${listing.boostExpiresAt!.month}.${listing.boostExpiresAt!.year}'
                                      : 'İlanınızı en üste taşıyarak daha fazla adaya ulaşın.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                context.push('/listing/${listing.id}/boost'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(isBoostedActive ? 'Uzat' : 'Öne Çıkar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Durum: ${switch (listing.status) {
                          ListingStatus.active => 'Aktif',
                          ListingStatus.closed => 'Kapalı',
                          ListingStatus.removed => 'Yönetici tarafından kaldırıldı',
                        }}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (listing.status != ListingStatus.removed)
                        TextButton(
                          onPressed: _submitting
                              ? null
                              : () => _toggleStatus(listing),
                          child: Text(
                            listing.status == ListingStatus.active
                                ? 'Kapat'
                                : 'Tekrar Aktifleştir',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kategori',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingCategoryDropdown(
                    value: _selectedCategory,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'İlan Başlığı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingTextFormField(
                    controller: _titleController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Başlık gerekli'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Image Picker & Management Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'İlan Fotoğrafları',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalImageCount/5',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          totalImageCount + (totalImageCount < 5 ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == totalImageCount) {
                          return InkWell(
                            onTap: _pickNewImages,
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
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fotoğraf Ekle',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Existing images first
                        if (index < _existingImageUrls.length) {
                          final url = _existingImageUrls[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: Colors.grey.shade200),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _existingImageUrls.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        // New picked local files
                        final localIndex = index - _existingImageUrls.length;
                        final file = _newImageFiles[localIndex];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: XFilePreviewImage(
                                file,
                                width: 90,
                                height: 90,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _newImageFiles.removeAt(localIndex);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Konum (İl / İlçe)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingTextFormField(
                    controller: _locationController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Konum gerekli'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.regionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TourismRegionDropdown(
                    value: _selectedRegion,
                    onChanged: (value) =>
                        setState(() => _selectedRegion = value),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şehir',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TourismCityDropdown(
                    value: _selectedCity,
                    onChanged: (value) => setState(() => _selectedCity = value),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Maaş',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingTextFormField(
                    controller: _salaryController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Maaş bilgisi gerekli'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  SalaryRangeFields(
                    minController: _minSalaryController,
                    maxController: _maxSalaryController,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Çalışma tipi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  EmploymentTypeDropdown(
                    value: _employmentType,
                    showHint: true,
                    onChanged: (value) =>
                        setState(() => _employmentType = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.experienceLevelLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ExperienceLevelDropdown(
                    value: _experienceLevel,
                    onChanged: (value) =>
                        setState(() => _experienceLevel = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.educationLevelLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  EducationLevelDropdown(
                    value: _educationLevel,
                    onChanged: (value) =>
                        setState(() => _educationLevel = value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.seasonLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SeasonAndContractDatesSection(
                    season: _season,
                    onSeasonChanged: (value) => setState(() {
                      _season = value;
                      if (!isSeasonalContract(value)) {
                        _contractStartDate = null;
                        _contractEndDate = null;
                      }
                    }),
                    contractStartDate: _contractStartDate,
                    contractEndDate: _contractEndDate,
                    onPickContractDate: _pickContractDate,
                  ),
                  const SizedBox(height: 16),
                  ListingHousingSection(
                    roomType: _housingRoomType,
                    onRoomTypeChanged: (value) =>
                        setState(() => _housingRoomType = value),
                    hasAc: _housingHasAc,
                    onHasAcChanged: (value) =>
                        setState(() => _housingHasAc = value),
                    hasWifi: _housingHasWifi,
                    onHasWifiChanged: (value) =>
                        setState(() => _housingHasWifi = value),
                    mealsIncludedInitialValue:
                        _housingMealsIncluded?.toString(),
                    onMealsIncludedChanged: (value) =>
                        _housingMealsIncluded = int.tryParse(value),
                    photoCount: _existingHousingImageUrls.length +
                        _newHousingImageFiles.length,
                    onAddPhotos:
                        _existingHousingImageUrls.length +
                                    _newHousingImageFiles.length <
                                5
                            ? _pickHousingImages
                            : null,
                  ),
                  const SizedBox(height: 16),
                  ListingTextFormField(
                    controller: _staffShuttleRouteController,
                    labelText: l10n.staffShuttleRouteLabel,
                    hintText: l10n.staffShuttleRouteHint,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'İletişim',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingTextFormField(
                    controller: _contactController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'İletişim bilgisi gerekli'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'İlan Açıklaması',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListingTextFormField(
                    controller: _descController,
                    maxLines: 4,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Açıklama gerekli'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ListingSubmitButton(
                    isSubmitting: _submitting,
                    label: 'Değişiklikleri Kaydet',
                    onPressed: () => _submit(listing),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickContractDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_contractStartDate ?? DateTime.now())
        : (_contractEndDate ?? _contractStartDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _contractStartDate = date;
      } else {
        _contractEndDate = date;
      }
    });
  }
}

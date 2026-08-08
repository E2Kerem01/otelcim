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
import '../../discovery/domain/tourism_region.dart';
import '../../nearby/services/location_service.dart';
import '../domain/listing_model.dart';
import 'listing_requirement_labels.dart';
import 'season_utils.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
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
  final _staffShuttleRouteController = TextEditingController();
  final List<XFile> _selectedImageFiles = [];
  final List<XFile> _housingImageFiles = [];
  String? _housingRoomType;
  bool _housingHasAc = false;
  bool _housingHasWifi = false;
  int? _housingMealsIncluded;
  bool _submitting = false;
  bool _isUrgent = false;
  String? _selectedCity;
  String? _selectedRegion;
  double? _lat;
  double? _lng;
  bool _addingLocation = false;
  EmploymentType _employmentType = EmploymentType.fullTime;
  ExperienceLevel? _experienceLevel;
  EducationLevel? _educationLevel;
  String? _season;
  DateTime? _contractStartDate;
  DateTime? _contractEndDate;

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

  Future<void> _pickHousingImages() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
    if (!mounted || picked.isEmpty) return;
    setState(
      () => _housingImageFiles.addAll(
        picked.take(5 - _housingImageFiles.length),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kırmızı ile işaretli alanları doldurun.')),
      );
      return;
    }
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
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlan yayınlamak için lütfen giriş yapın.'),
          ),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final listingService = ref.read(listingServiceProvider);
      final listingId = listingService.newListingId();

      // Upload images first (against the pre-generated ID) so the listing
      // document is only written once, fully formed. A failed upload no
      // longer blocks publishing entirely - it degrades to a photo-less
      // listing with a clear warning, since image uploads are the most
      // likely thing to fail (e.g. Storage not provisioned on the Firebase
      // project) and losing the whole listing over it is worse than
      // publishing without photos.
      final storageService = ref.read(storageServiceProvider);
      var imageUrls = <String>[];
      var housingImageUrls = <String>[];
      var imageUploadFailed = false;
      try {
        if (_selectedImageFiles.isNotEmpty) {
          imageUrls = await storageService.uploadListingImages(
            listingId,
            _selectedImageFiles,
          );
        }
        if (_housingImageFiles.isNotEmpty) {
          housingImageUrls = await storageService.uploadHousingImages(
            listingId,
            _housingImageFiles,
          );
        }
      } catch (e) {
        debugPrint('Listing image upload failed, publishing without photos: $e');
        imageUploadFailed = true;
      }

      await listingService.createListingWithId(
        listingId,
        Listing(
          id: listingId,
          posterId: user.uid,
          posterName: user.email,
          isUrgent: _isUrgent,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          category: _selectedCategory.name,
          location: _locationController.text.trim(),
          salary: _salaryController.text.trim(),
          city: _selectedCity,
          region: _selectedRegion,
          lat: _lat,
          lng: _lng,
          minSalaryTl: int.tryParse(_minSalaryController.text.trim()),
          maxSalaryTl: int.tryParse(_maxSalaryController.text.trim()),
          employmentType: _employmentType,
          experienceLevel: _experienceLevel?.name,
          educationLevel: _educationLevel?.name,
          season: _season,
          contractStartDate: _contractStartDate,
          contractEndDate: _contractEndDate,
          contactInfo: _contactController.text.trim(),
          images: imageUrls,
          housingRoomType: _housingRoomType,
          housingHasAc: _housingRoomType == null ? null : _housingHasAc,
          housingHasWifi: _housingRoomType == null ? null : _housingHasWifi,
          housingMealsIncluded: _housingMealsIncluded,
          housingImages: housingImageUrls,
          staffShuttleRoute:
              _staffShuttleRouteController.text.trim().isEmpty
              ? null
              : _staffShuttleRouteController.text.trim(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imageUploadFailed
                  ? 'İlanınız yayınlandı, ancak fotoğraflar yüklenemedi. Daha sonra düzenleyerek tekrar ekleyebilirsiniz.'
                  : 'İlanınız başarıyla yayınlandı!',
            ),
            backgroundColor: imageUploadFailed ? Colors.orange.shade800 : null,
          ),
        );
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

  Future<void> _addCurrentLocation() async {
    final l10n = AppLocalizations.of(context)!;
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.nearbyPermissionTitle),
        content: Text(l10n.nearbyPermissionExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
    if (!mounted || consent != true) return;
    setState(() => _addingLocation = true);
    final result = await ref.read(locationServiceProvider).currentPosition();
    if (!mounted) return;
    setState(() {
      _addingLocation = false;
      _lat = result.position?.latitude;
      _lng = result.position?.longitude;
    });
    final message = result.position != null
        ? l10n.listingLocationAdded
        : switch (result.failure) {
            LocationFailure.servicesDisabled => l10n.nearbyServicesDisabled,
            LocationFailure.denied => l10n.nearbyLocationDenied,
            LocationFailure.deniedForever => l10n.nearbyLocationDeniedForever,
            _ => l10n.nearbyLocationUnavailable,
          };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni İlan Aç')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).primaryColor.withAlpha(20),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor.withAlpha(80),
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.library_add_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: const Text(
                    'Birden fazla pozisyon mu gireceksiniz?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Tek otel bilgisiyle toplu ilan açabilirsiniz.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push('/batch-create-listing'),
                    child: const Text('Toplu İlan Ver'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ListingCategory>(
                initialValue: _selectedCategory,
                items: ListingCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(listingCategoryLabels[c]!),
                      ),
                    )
                    .toList(),
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Örn. Bodrum Resort Resepsiyon Görevlisi',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Image Picker Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'İlan Fotoğrafları',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  itemCount:
                      _selectedImageFiles.length +
                      (_selectedImageFiles.length < 5 ? 1 : 0),
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

                    final file = _selectedImageFiles[index];
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
                                _selectedImageFiles.removeAt(index);
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
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  hintText: 'Örn. Muğla / Bodrum',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Konum gerekli' : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _addingLocation
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _lat == null
                            ? Icons.add_location_alt_outlined
                            : Icons.location_on,
                      ),
                title: Text(AppLocalizations.of(context)!.addListingLocation),
                subtitle: Text(
                  _lat == null
                      ? AppLocalizations.of(
                          context,
                        )!.listingLocationOptionalHint
                      : AppLocalizations.of(context)!.listingLocationAdded,
                ),
                onTap: _addingLocation ? null : _addCurrentLocation,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.regionLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                hint: Text(AppLocalizations.of(context)!.regionSelectHint),
                items: tourismRegions
                    .map(
                      (region) => DropdownMenuItem(
                        value: region.id,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'en'
                              ? region.nameEn
                              : region.nameTr,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRegion = value),
                validator: (value) => value == null
                    ? AppLocalizations.of(context)!.regionRequired
                    : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.bolt, color: Colors.deepOrange.shade700),
                title: Text(l10n.urgentListingLabel),
                subtitle: Text(l10n.urgentListingHint),
                value: _isUrgent,
                onChanged: (value) => setState(() => _isUrgent = value),
              ),
              const SizedBox(height: 16),
              const Text(
                'Şehir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                hint: const Text('Şehir seçin'),
                items: turkishTourismCities
                    .map(
                      (city) =>
                          DropdownMenuItem(value: city, child: Text(city)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedCity = value),
                validator: (value) =>
                    value == null ? 'Şehir seçmeniz gerekiyor' : null,
              ),
              const SizedBox(height: 16),
              const Text('Maaş', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  hintText: 'Örn. 35.000₺ + yemek',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Maaş bilgisi gerekli'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'En düşük maaş (TL)',
                      ),
                      validator: _salaryValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxSalaryController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'En yüksek maaş (TL)',
                      ),
                      validator: _salaryValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Çalışma tipi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EmploymentType>(
                initialValue: _employmentType,
                items: EmploymentType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _employmentType = value);
                },
              ),
              const SizedBox(height: 16),
              Text(
                l10n.experienceLevelLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ExperienceLevel?>(
                initialValue: _experienceLevel,
                items: [
                  DropdownMenuItem<ExperienceLevel?>(
                    value: null,
                    child: Text(l10n.optionalNotSpecified),
                  ),
                  ...ExperienceLevel.values.map(
                    (level) => DropdownMenuItem<ExperienceLevel?>(
                      value: level,
                      child: Text(experienceLevelLabel(l10n, level)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _experienceLevel = value),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.educationLevelLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<EducationLevel?>(
                initialValue: _educationLevel,
                items: [
                  DropdownMenuItem<EducationLevel?>(
                    value: null,
                    child: Text(l10n.optionalNotSpecified),
                  ),
                  ...EducationLevel.values.map(
                    (level) => DropdownMenuItem<EducationLevel?>(
                      value: level,
                      child: Text(educationLevelLabel(l10n, level)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _educationLevel = value),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.seasonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _season,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.seasonNone),
                  ),
                  ...listingSeasonValues.map(
                    (season) => DropdownMenuItem<String?>(
                      value: season,
                      child: Text(listingSeasonLabel(l10n, season)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _season = value;
                  if (!isSeasonalContract(value)) {
                    _contractStartDate = null;
                    _contractEndDate = null;
                  }
                }),
              ),
              if (isSeasonalContract(_season)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickContractDate(isStart: true),
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          '${l10n.contractStartDateLabel}: ${formatContractDate(_contractStartDate, l10n)}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickContractDate(isStart: false),
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          '${l10n.contractEndDateLabel}: ${formatContractDate(_contractEndDate, l10n)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.housingAddTitle),
                leading: const Icon(Icons.home_work_outlined),
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: _housingRoomType,
                    decoration: InputDecoration(
                      labelText: l10n.housingRoomType,
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.optionalNotSpecified),
                      ),
                      DropdownMenuItem(
                        value: 'single',
                        child: Text(l10n.housingSingleRoom),
                      ),
                      DropdownMenuItem(
                        value: 'shared',
                        child: Text(l10n.housingSharedRoom),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _housingRoomType = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.housingHasAc),
                    value: _housingHasAc,
                    onChanged: (value) => setState(() => _housingHasAc = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.housingHasWifi),
                    value: _housingHasWifi,
                    onChanged: (value) =>
                        setState(() => _housingHasWifi = value),
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.housingMealsIncluded,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        _housingMealsIncluded = int.tryParse(value),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add_photo_alternate_outlined),
                    title: Text(l10n.housingPhotos),
                    subtitle: Text('${_housingImageFiles.length}/5'),
                    onTap: _housingImageFiles.length < 5
                        ? _pickHousingImages
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _staffShuttleRouteController,
                decoration: InputDecoration(
                  labelText: l10n.staffShuttleRouteLabel,
                  hintText: l10n.staffShuttleRouteHint,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              const Text(
                'İletişim',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  hintText: 'Örn. 0555 123 4567',
                ),
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
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'İlanınızla ilgili tüm detayları açıklayın...',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Açıklama gerekli' : null,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
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
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) return 'Geçerli tutar girin';
    final min = int.tryParse(_minSalaryController.text.trim());
    final max = int.tryParse(_maxSalaryController.text.trim());
    if (min != null && max != null && min > max) return 'Aralığı kontrol edin';
    return null;
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

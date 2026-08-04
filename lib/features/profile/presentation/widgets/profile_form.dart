import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/constants/listing_filters.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../discovery/domain/tourism_region.dart';

/// Form widget for editing user profile information.
///
/// Displays input fields for display name, phone number, bio, and
/// employer-specific fields (hotel name and position) when applicable.
///
/// Includes validation and provides callbacks when form data changes.
class ProfileForm extends StatefulWidget {
  /// The current user profile (if any)
  final UserProfile? profile;

  /// Callback when form data changes
  final void Function({
    String? displayName,
    String? phoneNumber,
    String? bio,
    String? hotelName,
    String? position,
    bool? availableImmediately,
    String? preferredExperienceLevel,
    String? preferredEducationLevel,
    String? preferredRegion,
  }) onChanged;

  /// The GlobalKey for the form (for validation from parent)
  final GlobalKey<FormState> formKey;

  const ProfileForm({
    super.key,
    this.profile,
    required this.onChanged,
    required this.formKey,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _bioController;
  late final TextEditingController _hotelNameController;
  late final TextEditingController _positionController;
  late bool _availableImmediately;
  ExperienceLevel? _preferredExperienceLevel;
  EducationLevel? _preferredEducationLevel;
  String? _preferredRegion;

  bool get _isEmployer => widget.profile?.userType == 'employer';

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profile?.displayName ?? '',
    );
    _phoneNumberController = TextEditingController(
      text: widget.profile?.phoneNumber ?? '',
    );
    _bioController = TextEditingController(
      text: widget.profile?.bio ?? '',
    );
    _hotelNameController = TextEditingController(
      text: widget.profile?.hotelName ?? '',
    );
    _positionController = TextEditingController(
      text: widget.profile?.position ?? '',
    );
    _availableImmediately = widget.profile?.availableImmediately ?? false;
    _preferredExperienceLevel = ExperienceLevel.fromName(
      widget.profile?.preferredExperienceLevel,
    );
    _preferredEducationLevel = EducationLevel.fromName(
      widget.profile?.preferredEducationLevel,
    );
    _preferredRegion = widget.profile?.preferredRegion;

    // Add listeners to notify parent of changes
    _displayNameController.addListener(_notifyChange);
    _phoneNumberController.addListener(_notifyChange);
    _bioController.addListener(_notifyChange);
    _hotelNameController.addListener(_notifyChange);
    _positionController.addListener(_notifyChange);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _bioController.dispose();
    _hotelNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  /// Notifies parent widget when any form field changes
  void _notifyChange() {
    widget.onChanged(
      displayName: _displayNameController.text,
      phoneNumber: _phoneNumberController.text,
      bio: _bioController.text,
      hotelName: _hotelNameController.text,
      position: _positionController.text,
      availableImmediately: _availableImmediately,
      preferredExperienceLevel: _preferredExperienceLevel?.name,
      preferredEducationLevel: _preferredEducationLevel?.name,
      preferredRegion: _preferredRegion,
    );
  }

  /// Validates that a required field is not empty
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  /// Validates phone number format (optional field)
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }

    // Basic phone number validation (digits, spaces, dashes, parentheses, plus)
    final phoneRegex = RegExp(r'^[\d\s\-\(\)\+]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Geçerli bir telefon numarası giriniz';
    }

    // Check minimum length (at least 10 digits)
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return 'Telefon numarası en az 10 haneli olmalıdır';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display Name (Required)
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Ad Soyad',
              hintText: 'Adınızı ve soyadınızı giriniz',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) => _validateRequired(value, 'Ad Soyad'),
          ),
          const SizedBox(height: 16),

          // Phone Number (Optional)
          TextFormField(
            controller: _phoneNumberController,
            decoration: const InputDecoration(
              labelText: 'Telefon Numarası',
              hintText: 'Telefon numaranızı giriniz',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: _validatePhoneNumber,
          ),
          const SizedBox(height: 16),

          // Bio (Optional, Multiline)
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Hakkında',
              hintText: 'Kendiniz hakkında kısa bir açıklama yazınız',
              prefixIcon: Icon(Icons.info_outline),
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),

          // Immediate Availability Toggle (SADECE iş arayanlar için)
          if (!_isEmployer) ...[
            DropdownButtonFormField<ExperienceLevel?>(
              initialValue: _preferredExperienceLevel,
              decoration: InputDecoration(
                labelText: l10n.myExperienceLevelLabel,
                prefixIcon: const Icon(Icons.work_history_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<ExperienceLevel?>(
                  value: null,
                  child: Text(l10n.optionalSelection),
                ),
                ...ExperienceLevel.values.map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(_experienceLabel(l10n, level)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _preferredExperienceLevel = value);
                _notifyChange();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<EducationLevel?>(
              initialValue: _preferredEducationLevel,
              decoration: InputDecoration(
                labelText: l10n.myEducationLevelLabel,
                prefixIcon: const Icon(Icons.school_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<EducationLevel?>(
                  value: null,
                  child: Text(l10n.optionalSelection),
                ),
                ...EducationLevel.values.map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(_educationLabel(l10n, level)),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _preferredEducationLevel = value);
                _notifyChange();
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _preferredRegion,
              decoration: InputDecoration(
                labelText: l10n.preferredRegionLabel,
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(l10n.optionalSelection),
                ),
                ...tourismRegions.map(
                  (region) => DropdownMenuItem(
                    value: region.id,
                    child: Text(isEnglish ? region.nameEn : region.nameTr),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _preferredRegion = value);
                _notifyChange();
              },
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color: _availableImmediately ? Colors.green.shade50 : Colors.grey.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: _availableImmediately ? Colors.green.shade300 : Colors.grey.shade300,
                ),
              ),
              child: SwitchListTile(
                value: _availableImmediately,
                onChanged: (val) {
                  setState(() {
                    _availableImmediately = val;
                  });
                  _notifyChange();
                },
                title: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: _availableImmediately ? Colors.green.shade700 : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Şu An Boşta / Hemen Başlayabilir',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Açık olduğunda işverenlerin sohbet ekranında yeşil "Hemen Başlayabilir" rozeti gösterilir.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                activeColor: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Employer-specific fields
          if (_isEmployer) ...[
            // Hotel Name (Required for employers)
            TextFormField(
              controller: _hotelNameController,
              decoration: const InputDecoration(
                labelText: 'Otel Adı',
                hintText: 'Çalıştığınız otelin adını giriniz',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateRequired(value, 'Otel Adı'),
            ),
            const SizedBox(height: 16),

            // Position (Required for employers)
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Pozisyon',
                hintText: 'Görevinizi giriniz (örn: İnsan Kaynakları Müdürü)',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validateRequired(value, 'Pozisyon'),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _experienceLabel(AppLocalizations l10n, ExperienceLevel level) =>
      switch (level) {
        ExperienceLevel.none => l10n.experienceNone,
        ExperienceLevel.underOneYear => l10n.experienceUnderOneYear,
        ExperienceLevel.oneToThreeYears => l10n.experienceOneToThreeYears,
        ExperienceLevel.threePlusYears => l10n.experienceThreePlusYears,
      };

  String _educationLabel(AppLocalizations l10n, EducationLevel level) =>
      switch (level) {
        EducationLevel.none => l10n.educationNone,
        EducationLevel.primary => l10n.educationPrimary,
        EducationLevel.highSchool => l10n.educationHighSchool,
        EducationLevel.university => l10n.educationUniversity,
      };
}

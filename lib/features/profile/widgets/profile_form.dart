import 'package:flutter/material.dart';

import '../../../shared/models/user_profile.dart';

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
}

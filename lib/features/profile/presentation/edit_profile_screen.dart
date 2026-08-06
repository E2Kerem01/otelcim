import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import 'verification_request_screen.dart';
import 'widgets/intro_video_picker.dart';
import 'widgets/profile_form.dart';
import 'widgets/profile_photo_picker.dart';

/// Screen for creating and editing user profiles.
///
/// Allows users to:
/// - Upload a profile photo (camera or gallery)
/// - Set display name, phone number, and bio
/// - Set hotel name and position (employer users only)
///
/// Automatically detects if creating a new profile or editing an existing one.
/// Shows real-time updates via Riverpod state management.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form field values
  String? _displayName;
  String? _phoneNumber;
  String? _bio;
  String? _hotelName;
  String? _position;
  String? _photoUrl;
  bool _availableImmediately = false;
  String? _preferredExperienceLevel;
  String? _preferredEducationLevel;
  String? _preferredRegion;
  String? _introVideoUrl;

  /// Handles the save button press
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final currentUser = authState.value;

      if (currentUser == null) {
        throw Exception('Kullanıcı oturum açmamış');
      }

      final profileService = ref.read(profileServiceProvider);
      final currentProfile = ref.read(currentUserProfileProvider).value;

      final now = DateTime.now();

      // Create or update profile
      final profile = UserProfile(
        id: currentUser.uid,
        email: currentUser.email ?? '',
        displayName: _displayName,
        phoneNumber: _phoneNumber,
        bio: _bio,
        photoUrl: _photoUrl,
        hotelName: _hotelName,
        position: _position,
        userType: currentProfile?.userType ?? 'jobseeker',
        availableImmediately: _availableImmediately,
        preferredExperienceLevel: _preferredExperienceLevel,
        preferredEducationLevel: _preferredEducationLevel,
        preferredRegion: _preferredRegion,
        introVideoUrl: _introVideoUrl,
        createdAt: currentProfile?.createdAt ?? now,
        updatedAt: now,
      );

      if (currentProfile == null) {
        await profileService.createUserProfile(profile);
      } else {
        await profileService.updateUserProfile(profile);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil başarıyla kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back if standalone route
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_isSaving)
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
              onPressed: _handleSave,
              tooltip: 'Kaydet',
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
          // Initialize form values from profile on first build
          if (_displayName == null && profile != null) {
            _displayName = profile.displayName;
            _phoneNumber = profile.phoneNumber;
            _bio = profile.bio;
            _hotelName = profile.hotelName;
            _position = profile.position;
            _photoUrl = profile.photoUrl;
            _availableImmediately = profile.availableImmediately;
            _preferredExperienceLevel = profile.preferredExperienceLevel;
            _preferredEducationLevel = profile.preferredEducationLevel;
            _preferredRegion = profile.preferredRegion;
            _introVideoUrl = profile.introVideoUrl;
          }

          final currentUser = authState.value;
          if (currentUser == null) {
            return const Center(
              child: Text('Kullanıcı oturum açmamış'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Photo Picker
                ProfilePhotoPicker(
                  photoUrl: _photoUrl,
                  userId: currentUser.uid,
                  onPhotoUploaded: (photoUrl) {
                    setState(() {
                      _photoUrl = photoUrl.isEmpty ? null : photoUrl;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Intro Video Picker (SADECE iş arayanlar için)
                if (profile?.userType != 'employer') ...[
                  IntroVideoPicker(
                    videoUrl: _introVideoUrl,
                    userId: currentUser.uid,
                    onVideoChanged: (newUrl) {
                      setState(() {
                        _introVideoUrl = newUrl;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Profile Form
                ProfileForm(
                  profile: profile,
                  formKey: _formKey,
                  onChanged: ({
                    String? displayName,
                    String? phoneNumber,
                    String? bio,
                    String? hotelName,
                    String? position,
                    bool? availableImmediately,
                    String? preferredExperienceLevel,
                    String? preferredEducationLevel,
                    String? preferredRegion,
                  }) {
                    setState(() {
                      _displayName = displayName;
                      _phoneNumber = phoneNumber;
                      _bio = bio;
                      _hotelName = hotelName;
                      _position = position;
                      if (availableImmediately != null) {
                        _availableImmediately = availableImmediately;
                      }
                      _preferredExperienceLevel = preferredExperienceLevel;
                      _preferredEducationLevel = preferredEducationLevel;
                      _preferredRegion = preferredRegion;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Verification button for employer users
                if (profile?.userType == 'employer')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const VerificationRequestScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.verified),
                        label: const Text('Otelinizi Doğrulayın'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Save Button (also available in AppBar)
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Profili Kaydet'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

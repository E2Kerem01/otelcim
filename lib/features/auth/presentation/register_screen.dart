import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/auth_error_mapper.dart';
import '../../../shared/utils/referral_code.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await ref.read(authServiceProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      await _createReferralProfileStub(user.uid, user.email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Writes a minimal but valid [UserProfile] stub right after registration
  /// so the referral code / referredBy fields are captured at signup time.
  ///
  /// This step must never block the registration flow: any failure (e.g. an
  /// invalid/unknown referral code, or a transient Firestore error) is
  /// swallowed and only logged via [debugPrint].
  Future<void> _createReferralProfileStub(String uid, String email) async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final enteredCode = _referralCodeController.text.trim();

      String? referredBy;
      if (enteredCode.isNotEmpty) {
        referredBy = await profileService.findUserIdByReferralCode(enteredCode);
      }

      final now = DateTime.now();
      await profileService.createUserProfile(
        UserProfile(
          id: uid,
          email: email,
          userType: 'jobseeker',
          referralCode: generateReferralCode(uid),
          referredBy: referredBy,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } catch (e) {
      debugPrint('Referans kodu işlenirken hata oluştu (kayıt akışı etkilenmedi): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n?.registerTitle ?? 'Kayıt Ol')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n?.emailLabel ?? 'E-posta',
                    hintText: l10n?.emailHint ?? 'ornek@eposta.com',
                  ),
                  validator: (value) {
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (value == null || value.trim().isEmpty || !emailRegex.hasMatch(value.trim())) {
                      return l10n?.emailValidation ?? 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n?.passwordLabel ?? 'Şifre'),
                  validator: (value) {
                    if (value == null || value.length < 8 || !RegExp(r'[0-9]').hasMatch(value)) {
                      return l10n?.passwordValidation ?? 'Şifre en az 8 karakter ve en az 1 rakam içermelidir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _referralCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: l10n?.referralCodeLabel ?? 'Referans Kodu (opsiyonel)',
                    hintText: l10n?.referralCodeHint ?? 'Arkadaşının kodu',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Kayıt Ol'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Zaten hesabın var mı? Giriş yap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

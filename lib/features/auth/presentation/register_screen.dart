import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/providers/profile_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/utils/referral_code.dart';
import '../../../shared/widgets/auth_brand_panel.dart';

/// The account type a new user picks at registration.
///
/// The [firestoreValue] strings must match what the rest of the app checks
/// for (`profile_form.dart`, `edit_profile_screen.dart`) and what the seed
/// data uses: `'jobseeker'` / `'employer'`.
enum RegistrationRole {
  jobseeker('jobseeker'),
  employer('employer');

  const RegistrationRole(this.firestoreValue);

  final String firestoreValue;
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _hotelNameController = TextEditingController();
  bool _loading = false;

  /// Chosen account type. Null until the user picks one; registration is
  /// blocked with an inline error while it stays null.
  RegistrationRole? _role;
  bool _showRoleError = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    _hotelNameController.dispose();
    super.dispose();
  }

  void _selectRole(RegistrationRole role) {
    setState(() {
      _role = role;
      _showRoleError = false;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    if (_role == null) {
      setState(() => _showRoleError = true);
    }
    if (!formValid || _role == null) return;

    setState(() => _loading = true);
    try {
      final user = await ref.read(authServiceProvider).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      try {
        await _createInitialProfile(user.uid, user.email, _role!);
      } catch (error, stackTrace) {
        // Auth account exists but its profile doc could not be written.
        // Don't leave the user stuck on a spinner - let them into the app;
        // the profile screen recreates a stub on first save.
        logError(
          error,
          stackTrace,
          context: '_RegisterScreenState._submit.createInitialProfile',
        );
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mapToFailure(error, l10n).message),
            ),
          );
        }
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_RegisterScreenState._submit');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapToFailure(error, l10n).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Writes a minimal but valid [UserProfile] right after registration so the
  /// account has its [UserProfile.userType] (job seeker vs employer) and the
  /// referral code / referredBy fields set from the moment it is created.
  ///
  /// Only the referral-code *lookup* is best-effort: an unknown code or a
  /// transient error there is swallowed (and logged) so it can't block
  /// registration. The profile write itself is intentionally allowed to
  /// propagate to [_submit]'s handler — losing the chosen role would leave
  /// the account silently defaulted to a job seeker with no way to fix it.
  Future<void> _createInitialProfile(
    String uid,
    String email,
    RegistrationRole role,
  ) async {
    final profileService = ref.read(profileServiceProvider);
    final enteredCode = _referralCodeController.text.trim();

    String? referredBy;
    if (enteredCode.isNotEmpty) {
      try {
        referredBy = await profileService.findUserIdByReferralCode(enteredCode);
      } catch (error, stackTrace) {
        logError(
          error,
          stackTrace,
          context: '_RegisterScreenState._createInitialProfile.resolveReferralCode',
        );
      }
    }

    final hotelName = role == RegistrationRole.employer
        ? _hotelNameController.text.trim()
        : null;
    final fullName = _fullNameController.text.trim();

    final now = DateTime.now();
    await profileService.createUserProfile(
      UserProfile(
        id: uid,
        email: email,
        userType: role.firestoreValue,
        displayName: fullName.isNotEmpty ? fullName : null,
        hotelName: (hotelName != null && hotelName.isNotEmpty) ? hotelName : null,
        referralCode: generateReferralCode(uid),
        referredBy: referredBy,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaWidth = MediaQuery.of(context).size.width;
    final isWide = mediaWidth > 840;

    final formContent = Padding(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.card_travel_rounded, size: 48, color: otelcimBlue),
            const SizedBox(height: 8),
            Text(
              l10n.registerTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            _RoleSelector(
              selected: _role,
              showError: _showRoleError,
              onSelect: _selectRole,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                hintText: l10n.emailHint,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (value == null || value.trim().isEmpty || !emailRegex.hasMatch(value.trim())) {
                  return l10n.emailValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.length < 8 || !RegExp(r'[0-9]').hasMatch(value)) {
                  return l10n.passwordValidation;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.coreFullNameLabel,
                hintText: l10n.coreFullNameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.coreFullNameRequired;
                }
                if (value.trim().length < 3) {
                  return l10n.coreFullNameValidation;
                }
                return null;
              },
            ),
            if (_role == RegistrationRole.employer) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _hotelNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.coreBusinessNameLabel,
                  hintText: l10n.coreBusinessNameHint,
                  prefixIcon: const Icon(Icons.business_outlined),
                ),
                validator: (value) {
                  if (_role != RegistrationRole.employer) return null;
                  if (value == null || value.trim().isEmpty) {
                    return l10n.coreBusinessNameRequired;
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _referralCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.referralCodeLabel,
                hintText: l10n.referralCodeHint,
                prefixIcon: const Icon(Icons.card_giftcard_outlined),
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
                  : Text(l10n.registerButton),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.coreAlreadyHaveAccountPrompt),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    l10n.loginButton,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: otelcimBlue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isWide) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: formContent),
                      const Expanded(child: AuthBrandPanel()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: formContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two stacked cards letting a new user pick their account type. Kept in
/// this file because it is only ever used by [RegisterScreen]; the
/// standalone onboarding [RoleSelectionScreen] is a separate, unwired flow.
class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selected,
    required this.showError,
    required this.onSelect,
  });

  final RegistrationRole? selected;
  final bool showError;
  final ValueChanged<RegistrationRole> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.coreAccountTypeLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _RoleCard(
          title: l10n.roleJobSeeker,
          description: l10n.coreRegisterJobSeekerShortDesc,
          icon: Icons.work_outline,
          isSelected: selected == RegistrationRole.jobseeker,
          onTap: () => onSelect(RegistrationRole.jobseeker),
        ),
        const SizedBox(height: 8),
        _RoleCard(
          title: l10n.roleEmployer,
          description: l10n.coreRegisterEmployerShortDesc,
          icon: Icons.business_outlined,
          isSelected: selected == RegistrationRole.employer,
          onTap: () => onSelect(RegistrationRole.employer),
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          Text(
            l10n.corePleaseSelectAccountType,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

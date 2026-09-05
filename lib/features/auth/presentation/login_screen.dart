import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/error/error_mapper.dart';
import '../../../shared/error/error_reporter.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/auth_brand_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();

  int _selectedTab = 0; // 0: Email, 1: Phone
  bool _rememberMe = true;
  bool _loading = false;

  // Phone auth state
  bool _phoneCodeSent = false;
  String? _verificationId;

  // Rate limiting state (5 consecutive failures -> 30s lock)
  int _failedAttempts = 0;
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _triggerRateLimitLockout() {
    setState(() {
      _lockoutSeconds = 30;
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _failedAttempts = 0;
        });
      } else {
        setState(() {
          _lockoutSeconds--;
        });
      }
    });
  }

  void _handleFailure(Object e) {
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _triggerRateLimitLockout();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapToFailure(e).message)),
      );
    }
  }

  String _normalizePhoneNumber(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.startsWith('90') && digitsOnly.length == 12) {
      return '+$digitsOnly';
    } else if (digitsOnly.length == 10 && digitsOnly.startsWith('5')) {
      return '+90$digitsOnly';
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('05')) {
      return '+90${digitsOnly.substring(1)}';
    }
    return raw.trim();
  }

  Future<void> _submitEmail() async {
    if (_lockoutSeconds > 0) return;
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      _failedAttempts = 0;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_LoginScreenState._submitEmail');
      _handleFailure(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendSmsCode() async {
    if (_lockoutSeconds > 0) return;
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final normalized = _normalizePhoneNumber(_phoneController.text);
      final verId = await ref.read(authServiceProvider).verifyPhoneNumber(
            phoneNumber: normalized,
          );
      setState(() {
        _verificationId = verId;
        _phoneCodeSent = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SMS doğrulama kodu gönderildi.')),
        );
      }
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_LoginScreenState._sendSmsCode');
      _handleFailure(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifySmsCode() async {
    if (_lockoutSeconds > 0) return;
    if (_verificationId == null) return;
    final code = _smsCodeController.text.trim();
    if (code.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen 6 haneli geçerli doğrulama kodunu girin.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithSmsCode(
            verificationId: _verificationId!,
            smsCode: code,
            rememberMe: _rememberMe,
          );
      _failedAttempts = 0;
    } catch (error, stackTrace) {
      logError(error, stackTrace, context: '_LoginScreenState._verifySmsCode');
      _handleFailure(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaWidth = MediaQuery.of(context).size.width;
    final isWide = mediaWidth > 840;

    final formContent = Padding(
      padding: EdgeInsets.all(isWide ? 32 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Logo & App Title
          const Icon(Icons.card_travel_rounded, size: 48, color: otelcimBlue),
          const SizedBox(height: 8),
          Text(
            l10n?.appName ?? 'Otelcim',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),

          // Email / Phone Tab Switch
          SegmentedButton<int>(
            segments: [
              ButtonSegment<int>(
                value: 0,
                label: Text(l10n?.loginWithEmail ?? 'E-posta ile Giriş'),
                icon: const Icon(Icons.email_outlined, size: 18),
              ),
              ButtonSegment<int>(
                value: 1,
                label: Text(l10n?.loginWithPhone ?? 'Telefon ile Giriş'),
                icon: const Icon(Icons.phone_android_outlined, size: 18),
              ),
            ],
            selected: {_selectedTab},
            onSelectionChanged: (newSelection) {
              setState(() {
                _selectedTab = newSelection.first;
                _phoneCodeSent = false;
                _verificationId = null;
              });
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: otelcimBlue.withValues(alpha: 0.12),
              selectedForegroundColor: otelcimBlue,
            ),
          ),
          const SizedBox(height: 24),

          // Lockout warning if rate limited
          if (_lockoutSeconds > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n?.tooManyAttempts(_lockoutSeconds) ??
                          'Çok fazla başarısız deneme. Lütfen $_lockoutSeconds saniye bekleyin.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Form Body
          if (_selectedTab == 0) _buildEmailForm(l10n) else _buildPhoneForm(l10n),

          const SizedBox(height: 16),

          // Remember Me Checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: _lockoutSeconds > 0
                    ? null
                    : (val) {
                        if (val != null) setState(() => _rememberMe = val);
                      },
                activeColor: otelcimBlue,
              ),
              Text(
                l10n?.rememberMe ?? 'Beni Hatırla',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Footer: Account registration prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n?.noAccountPrompt.split('?').first ?? 'Hesabın yok mu',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: Text(
                  l10n?.registerButton ?? 'Kayıt Ol',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: otelcimBlue),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildEmailForm(AppLocalizations? l10n) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l10n?.emailLabel ?? 'E-posta',
              hintText: l10n?.emailHint ?? 'ornek@eposta.com',
              prefixIcon: const Icon(Icons.email_outlined),
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
            decoration: InputDecoration(
              labelText: l10n?.passwordLabel ?? 'Şifre',
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.length < 8 || !RegExp(r'[0-9]').hasMatch(value)) {
                return l10n?.passwordValidation ?? 'Şifre en az 8 karakter ve en az 1 rakam içermelidir';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_loading || _lockoutSeconds > 0) ? null : _submitEmail,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(l10n?.loginButton ?? 'Giriş Yap'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneForm(AppLocalizations? l10n) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_phoneCodeSent && !_loading && _lockoutSeconds == 0,
            decoration: InputDecoration(
              labelText: l10n?.phoneLabel ?? 'Telefon Numarası',
              hintText: l10n?.phoneHint ?? '5XX XXX XX XX',
              prefixIcon: const Icon(Icons.phone_outlined),
              prefixText: '+90 ',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n?.phoneValidation ?? 'Geçerli bir telefon numarası girin';
              }
              final normalized = _normalizePhoneNumber(value);
              final phoneRegex = RegExp(r'^\+90[0-9]{10}$');
              if (!phoneRegex.hasMatch(normalized)) {
                return l10n?.phoneValidation ?? 'Geçerli bir telefon numarası girin (ör: 5551234567)';
              }
              return null;
            },
          ),
          if (_phoneCodeSent) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _smsCodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n?.smsCodeLabel ?? 'SMS Doğrulama Kodu',
                hintText: l10n?.smsCodeHint ?? '6 haneli kod',
                prefixIcon: const Icon(Icons.pin_outlined),
                counterText: '',
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (!_phoneCodeSent)
            ElevatedButton(
              onPressed: (_loading || _lockoutSeconds > 0) ? null : _sendSmsCode,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n?.sendSmsCode ?? 'Kod Gönder'),
            )
          else ...[
            ElevatedButton(
              onPressed: (_loading || _lockoutSeconds > 0) ? null : _verifySmsCode,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n?.verifySmsCode ?? 'Doğrula ve Giriş Yap'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: (_loading || _lockoutSeconds > 0)
                  ? null
                  : () {
                      setState(() {
                        _phoneCodeSent = false;
                        _smsCodeController.clear();
                      });
                    },
              child: const Text('Numarayı Değiştir / Tekrar Kod Gönder'),
            ),
          ],
        ],
      ),
    );
  }

}

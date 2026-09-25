import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';

String mapAuthError(Object error, [AppLocalizations? l10n]) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return l10n?.coreAuthErrorInvalidCredentials ??
            'E-posta veya şifre hatalı. Hesabınız yoksa lütfen aşağıdan Kayıt Ol butonuna basın.';
      case 'invalid-phone-number':
        return l10n?.coreAuthErrorInvalidPhoneNumber ??
            'Geçersiz telefon numarası. Lütfen kontrol edip tekrar deneyin.';
      case 'invalid-verification-code':
        return l10n?.coreAuthErrorInvalidVerificationCode ??
            'SMS doğrulama kodu hatalı veya süresi dolmuş.';
      case 'too-many-requests':
        return l10n?.coreAuthErrorTooManyRequests ??
            'Çok fazla başarısız deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'email-already-in-use':
        return l10n?.coreAuthErrorEmailAlreadyInUse ??
            'Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap butonunu kullanın.';
      case 'weak-password':
        return l10n?.coreAuthErrorWeakPassword ??
            'Şifre en az 8 karakter ve en az 1 rakam olmalı.';
      case 'invalid-email':
        return l10n?.coreAuthErrorInvalidEmail ??
            'Geçersiz e-posta adresi.';
      case 'operation-not-allowed':
        return l10n?.coreAuthErrorOperationNotAllowed ??
            'Firebase girişi henüz aktif değil.';
      case 'unauthorized-domain':
        return l10n?.coreAuthErrorUnauthorizedDomain ??
            'Bu web adresi (domain) Firebase izin listesinde ekli değil.';
      default:
        return error.message ??
            (l10n != null ? l10n.coreAuthErrorUnknownWithCode(error.code) : 'Giriş hatası: ${error.code}');
    }
  }
  return error.toString();
}

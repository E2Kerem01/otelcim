import 'package:firebase_auth/firebase_auth.dart';

String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı. Hesabınız yoksa lütfen aşağıdan Kayıt Ol butonuna basın.';
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası. Lütfen kontrol edip tekrar deneyin.';
      case 'invalid-verification-code':
        return 'SMS doğrulama kodu hatalı veya süresi dolmuş.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap butonunu kullanın.';
      case 'weak-password':
        return 'Şifre en az 8 karakter ve en az 1 rakam olmalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'operation-not-allowed':
        return 'Firebase girişi henüz aktif değil.';
      case 'unauthorized-domain':
        return 'Bu web adresi (domain) Firebase izin listesinde ekli değil.';
      default:
        return error.message ?? 'Giriş hatası: ${error.code}';
    }
  }
  return error.toString();
}

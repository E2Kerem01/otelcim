import 'package:firebase_auth/firebase_auth.dart';

String mapAuthError(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı. Hesabınız yoksa lütfen aşağıdan Kayıt Ol butonuna basın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kayıtlı. Lütfen Giriş Yap butonunu kullanın.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'operation-not-allowed':
        return 'Firebase E-posta/Şifre girişi henüz aktif değil.';
      case 'unauthorized-domain':
        return 'Bu web adresi (domain) Firebase izin listesinde ekli değil.';
      default:
        return error.message ?? 'Giriş hatası: ${error.code}';
    }
  }
  return error.toString();
}

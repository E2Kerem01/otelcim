import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/utils/auth_error_mapper.dart';

void main() {
  group('mapAuthError', () {
    test('maps invalid-phone-number to generic message', () {
      final exc = FirebaseAuthException(code: 'invalid-phone-number');
      final msg = mapAuthError(exc);
      expect(msg, contains('Geçersiz telefon numarası'));
    });

    test('maps invalid-verification-code to generic message', () {
      final exc = FirebaseAuthException(code: 'invalid-verification-code');
      final msg = mapAuthError(exc);
      expect(msg, contains('SMS doğrulama kodu hatalı'));
    });

    test('maps too-many-requests to generic message', () {
      final exc = FirebaseAuthException(code: 'too-many-requests');
      final msg = mapAuthError(exc);
      expect(msg, contains('Çok fazla başarısız deneme'));
    });

    test('maps user-not-found, wrong-password, invalid-credential to identical generic message', () {
      final msg1 = mapAuthError(FirebaseAuthException(code: 'user-not-found'));
      final msg2 = mapAuthError(FirebaseAuthException(code: 'wrong-password'));
      final msg3 = mapAuthError(FirebaseAuthException(code: 'invalid-credential'));

      expect(msg1, msg2);
      expect(msg2, msg3);
      expect(msg1, contains('E-posta veya şifre hatalı'));
    });
  });
}

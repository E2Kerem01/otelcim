import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/error/app_failure.dart';
import 'package:otelcim/shared/error/error_mapper.dart';

void main() {
  group('mapToFailure', () {
    test('maps permission-denied FirebaseException to a permission failure', () {
      final failure = mapToFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      expect(failure.kind, FailureKind.permission);
      expect(failure.code, 'permission-denied');
      expect(failure.message, isNotEmpty);
    });

    test('maps not-found FirebaseException to a notFound failure', () {
      final failure = mapToFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
      );
      expect(failure.kind, FailureKind.notFound);
    });

    test('maps unavailable FirebaseException to a network failure', () {
      final failure = mapToFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      expect(failure.kind, FailureKind.network);
    });

    test('maps resource-exhausted FirebaseException to a rateLimited failure', () {
      final failure = mapToFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'resource-exhausted'),
      );
      expect(failure.kind, FailureKind.rateLimited);
    });

    test('falls back to the exception message for unknown Firebase codes', () {
      final failure = mapToFailure(
        FirebaseException(plugin: 'cloud_firestore', code: 'some-new-code', message: 'boom'),
      );
      expect(failure.kind, FailureKind.unknown);
      expect(failure.message, 'boom');
    });

    test('maps FirebaseAuthException through the existing Turkish auth mapper', () {
      final failure = mapToFailure(
        FirebaseAuthException(code: 'wrong-password'),
      );
      expect(failure.kind, FailureKind.permission);
      expect(failure.message, contains('şifre'));
    });

    test('maps an arbitrary exception to an unknown failure with a generic message', () {
      final failure = mapToFailure(Exception('anything'));
      expect(failure.kind, FailureKind.unknown);
      expect(failure.cause, isA<Exception>());
    });
  });
}

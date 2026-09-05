import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../utils/auth_error_mapper.dart';
import 'app_failure.dart';

const _genericMessage = 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';
const _networkMessage = 'İnternet bağlantınızı kontrol edip tekrar deneyin.';

/// Converts a raw exception caught at a Firebase/HTTP/storage boundary into
/// a typed [AppFailure] carrying a Turkish, user-safe [AppFailure.message].
///
/// This is the one place that knows about provider-specific error shapes
/// (`FirebaseException` codes differ between Firestore, Storage and Auth) -
/// call it from a catch block instead of re-deriving a message inline.
AppFailure mapToFailure(Object error) {
  if (error is FirebaseAuthException) {
    return AppFailure(
      kind: FailureKind.permission,
      message: mapAuthError(error),
      code: error.code,
      cause: error,
    );
  }

  if (error is FirebaseException) {
    return _mapFirebaseException(error);
  }

  if (error is SocketException || error is HttpException) {
    return AppFailure(kind: FailureKind.network, message: _networkMessage, cause: error);
  }

  return AppFailure(kind: FailureKind.unknown, message: _genericMessage, cause: error);
}

AppFailure _mapFirebaseException(FirebaseException error) {
  switch (error.code) {
    case 'permission-denied':
    case 'unauthorized':
    case 'unauthenticated':
      return AppFailure(
        kind: FailureKind.permission,
        message: 'Bu işlem için yetkiniz yok.',
        code: error.code,
        cause: error,
      );
    case 'not-found':
    case 'object-not-found':
      return AppFailure(
        kind: FailureKind.notFound,
        message: 'Aradığınız kayıt bulunamadı.',
        code: error.code,
        cause: error,
      );
    case 'already-exists':
      return AppFailure(
        kind: FailureKind.conflict,
        message: 'Bu kayıt zaten mevcut.',
        code: error.code,
        cause: error,
      );
    case 'resource-exhausted':
      return AppFailure(
        kind: FailureKind.rateLimited,
        message: 'Çok fazla istek gönderildi. Lütfen biraz sonra tekrar deneyin.',
        code: error.code,
        cause: error,
      );
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
      return AppFailure(kind: FailureKind.network, message: _networkMessage, code: error.code, cause: error);
    case 'invalid-argument':
      return AppFailure(
        kind: FailureKind.validation,
        message: 'Girilen bilgiler geçersiz.',
        code: error.code,
        cause: error,
      );
    default:
      return AppFailure(
        kind: FailureKind.unknown,
        message: error.message ?? _genericMessage,
        code: error.code,
        cause: error,
      );
  }
}

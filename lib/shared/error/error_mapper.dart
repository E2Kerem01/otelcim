import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import '../../l10n/app_localizations.dart';
import '../utils/auth_error_mapper.dart';
import 'app_failure.dart';

const _genericMessage = 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';
const _networkMessage = 'İnternet bağlantınızı kontrol edip tekrar deneyin.';

/// Converts a raw exception caught at a Firebase/HTTP/storage boundary into
/// a typed [AppFailure] carrying a user-safe [AppFailure.message].
///
/// This is the one place that knows about provider-specific error shapes
/// (`FirebaseException` codes differ between Firestore, Storage and Auth) -
/// call it from a catch block instead of re-deriving a message inline.
AppFailure mapToFailure(Object error, [AppLocalizations? l10n]) {
  if (error is FirebaseAuthException) {
    return AppFailure(
      kind: FailureKind.permission,
      message: mapAuthError(error, l10n),
      code: error.code,
      cause: error,
    );
  }

  if (error is FirebaseException) {
    return _mapFirebaseException(error, l10n);
  }

  if (error is SocketException || error is HttpException) {
    return AppFailure(
      kind: FailureKind.network,
      message: l10n?.coreErrorNetwork ?? _networkMessage,
      cause: error,
    );
  }

  return AppFailure(
    kind: FailureKind.unknown,
    message: l10n?.coreErrorGeneric ?? _genericMessage,
    cause: error,
  );
}

AppFailure _mapFirebaseException(FirebaseException error, [AppLocalizations? l10n]) {
  switch (error.code) {
    case 'permission-denied':
    case 'unauthorized':
    case 'unauthenticated':
      return AppFailure(
        kind: FailureKind.permission,
        message: l10n?.coreErrorPermissionDenied ?? 'Bu işlem için yetkiniz yok.',
        code: error.code,
        cause: error,
      );
    case 'not-found':
    case 'object-not-found':
      return AppFailure(
        kind: FailureKind.notFound,
        message: l10n?.coreErrorNotFound ?? 'Aradığınız kayıt bulunamadı.',
        code: error.code,
        cause: error,
      );
    case 'already-exists':
      return AppFailure(
        kind: FailureKind.conflict,
        message: l10n?.coreErrorAlreadyExists ?? 'Bu kayıt zaten mevcut.',
        code: error.code,
        cause: error,
      );
    case 'resource-exhausted':
      return AppFailure(
        kind: FailureKind.rateLimited,
        message: l10n?.coreAuthErrorTooManyRequests ??
            'Çok fazla istek gönderildi. Lütfen biraz sonra tekrar deneyin.',
        code: error.code,
        cause: error,
      );
    case 'unavailable':
    case 'deadline-exceeded':
    case 'cancelled':
      return AppFailure(
        kind: FailureKind.network,
        message: l10n?.coreErrorNetwork ?? _networkMessage,
        code: error.code,
        cause: error,
      );
    case 'invalid-argument':
      return AppFailure(
        kind: FailureKind.validation,
        message: l10n?.coreErrorInvalidArgument ?? 'Girilen bilgiler geçersiz.',
        code: error.code,
        cause: error,
      );
    default:
      return AppFailure(
        kind: FailureKind.unknown,
        message: error.message ?? (l10n?.coreErrorGeneric ?? _genericMessage),
        code: error.code,
        cause: error,
      );
  }
}

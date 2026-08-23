/// Broad category for an [AppFailure], for callers that want to branch on
/// what kind of thing went wrong (e.g. offer a retry button only for
/// [network] failures) without inspecting provider-specific error codes.
enum FailureKind {
  network,
  permission,
  notFound,
  conflict,
  rateLimited,
  validation,
  unknown,
}

/// A typed, user-presentable error produced by [mapToFailure].
///
/// Replaces the previous pattern of catching a raw exception and either
/// discarding it (`catch (_)`) or hand-rolling a Turkish message inline at
/// each call site. [message] is always safe to show a user; [code] and
/// [cause] are for logging only.
class AppFailure {
  const AppFailure({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
  });

  final FailureKind kind;
  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'AppFailure(kind: $kind, code: $code, message: $message)';
}

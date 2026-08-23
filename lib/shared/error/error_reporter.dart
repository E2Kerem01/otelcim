import 'package:flutter/foundation.dart';

/// Single place errors caught at a service/UI boundary get logged.
///
/// Centralizing this - instead of the ad hoc `debugPrint('... error: $e')`
/// calls previously scattered across every catch block - means wiring in a
/// crash-reporting backend later is a one-file change instead of a
/// repo-wide one.
void logError(Object error, StackTrace stackTrace, {String? context}) {
  final label = context == null ? '' : '[$context] ';
  debugPrint('$label$error\n$stackTrace');
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/services/locale_service.dart';

/// Lets the user pick the app language. The choice is persisted
/// (SharedPreferences via [LocaleController]) and applied app-wide through
/// [MaterialApp.locale].
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.watch(localeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.languageSettingsTitle),
      ),
      body: ListView(
        children: [
          RadioGroup<String>(
            groupValue: current.languageCode,
            onChanged: (code) {
              if (code != null) {
                unawaited(
                  ref
                      .read(localeControllerProvider.notifier)
                      .setLocale(Locale(code)),
                );
              }
            },
            child: Column(
              children: [
                for (final locale in kSupportedAppLocales)
                  RadioListTile<String>(
                    value: locale.languageCode,
                    title: Text(kAppLanguageNames[locale.languageCode] ??
                        locale.languageCode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

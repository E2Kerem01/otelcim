import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/design_tokens.dart';
import '../../../core/responsive/max_width_container.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/services/locale_service.dart';

/// Lets the user pick the app language. The choice is persisted
/// (SharedPreferences via [LocaleController]) and applied app-wide through
/// [MaterialApp.locale]. Strings not yet translated for the chosen language
/// fall back to Turkish.
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(localeControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.languageSettingsTitle ?? 'Uygulama Dili'),
      ),
      body: MaxWidthContainer(
        maxWidth: AppBreakpoints.formMaxWidth,
        child: ListView(
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n?.languageSettingsSubtitle ??
                  'Bazı metinler henüz çevrilmedi; çevrilmeyen yerler Türkçe '
                      'gösterilir.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
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
      ),
    );
  }
}

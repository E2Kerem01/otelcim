import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.card_travel_rounded, size: 64, color: otelcimBlue),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.appName ?? 'Otelcim',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: otelcimBlue,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: otelcimBlue),
          ],
        ),
      ),
    );
  }
}

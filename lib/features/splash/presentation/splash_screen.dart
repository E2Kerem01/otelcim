import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.card_travel_rounded, size: 64, color: otelcimBlue),
            SizedBox(height: 16),
            Text('Otelcim', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: otelcimBlue)),
            SizedBox(height: 24),
            CircularProgressIndicator(color: otelcimBlue),
          ],
        ),
      ),
    );
  }
}

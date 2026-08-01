import 'package:flutter/material.dart';

import '../../../../shared/models/onboarding_slide_data.dart';

/// Reusable widget for displaying a single onboarding slide
///
/// Displays an onboarding slide with:
/// - Large icon at the top
/// - Title text below the icon
/// - Description text at the bottom
///
/// Uses Material Design 3 styling and follows Otelcim's design system.
class OnboardingSlide extends StatelessWidget {
  /// The data for this slide
  final OnboardingSlideData slideData;

  /// Creates an OnboardingSlide widget
  const OnboardingSlide({
    super.key,
    required this.slideData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon container with circular background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slideData.icon,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            slideData.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            slideData.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

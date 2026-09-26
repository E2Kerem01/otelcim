import 'package:flutter/material.dart';

/// Shared visual decisions for the Otelcim application.
///
/// Tokens are intentionally small and immutable. Screens should consume these
/// values through the theme or directly when a layout needs a stable spacing,
/// radius, breakpoint, or semantic colour.
abstract final class AppColors {
  // Brand colours retain the existing Otelcim blue hue while adding a deeper
  // primary for stronger hierarchy and a Mediterranean teal secondary.
  static const primary = Color(0xFF0F52BA);
  static const primaryHover = Color(0xFF0B3F91);
  static const primaryDark = Color(0xFF8AB4F8);
  static const primaryContainer = Color(0xFFEBF2FD);
  static const onPrimaryContainer = Color(0xFF0B2F6B);
  static const secondary = Color(0xFF0D9488);
  static const secondaryDark = Color(0xFF5EEAD4);
  static const secondaryContainer = Color(0xFFCCFBF1);
  static const onSecondaryContainer = Color(0xFF064E49);

  // Slate neutrals are shared by both themes and provide predictable borders,
  // surfaces, and text without relying on framework grey shades.
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);

  static const surfaceLight = Colors.white;
  static const backgroundLight = neutral50;
  static const surfaceDark = neutral800;
  static const backgroundDark = neutral900;
  static const borderLight = neutral200;
  static const borderDark = neutral700;

  // These text pairs are chosen to remain AA-readable on their respective
  // light/dark surfaces. Disabled text is intentionally not a reading colour.
  static const textPrimaryLight = neutral900;
  static const textSecondaryLight = neutral600;
  static const textPrimaryDark = neutral50;
  static const textSecondaryDark = neutral300;
  static const textDisabledLight = neutral500;
  static const textDisabledDark = neutral400;

  // Strong semantic colours are suitable for filled badges and actions with
  // white foregrounds. Their pale containers are intended for tinted surfaces.
  static const success = Color(0xFF047857);
  static const successContainer = Color(0xFFDCFCE7);
  static const onSuccessContainer = Color(0xFF14532D);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFFEDD5);
  static const onWarningContainer = Color(0xFF7C2D12);
  static const error = Color(0xFFB91C1C);
  static const errorContainer = Color(0xFFFEE2E2);
  static const onErrorContainer = Color(0xFF7F1D1D);
  static const info = Color(0xFF0369A1);
  static const infoContainer = Color(0xFFE0F2FE);
  static const onInfoContainer = Color(0xFF0C4A6E);

  static const shadow = Color(0x0A000000);
  static const shadowMedium = Color(0x0F000000);
  static const shadowOverlay = Color(0x1A000000);
}

/// Four-point spacing scale used by page layouts and components.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Standard corner radii. Use [pill] only for fully rounded controls.
abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const pill = 999.0;
}

/// Soft web elevation values and their reusable shadow recipes.
abstract final class AppElevation {
  static const soft = 1.0;
  static const medium = 4.0;
  static const overlay = 12.0;

  static const softShadow = <BoxShadow>[
    BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const mediumShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
  static const overlayShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowOverlay,
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}

/// Responsive layout thresholds. A width belongs to the next tier at its
/// threshold: mobile < 600, tablet < 1024, desktop >= 1024, wide >= 1440.
abstract final class AppBreakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  static const desktop = 1024.0;
  static const wide = 1440.0;

  static const contentMaxWidth = 1200.0;
  static const formMaxWidth = 720.0;
}

/// Type scale for dense, readable web interfaces.
abstract final class AppTypography {
  static const displaySize = 32.0;
  static const displayLineHeight = 40.0;
  static const displayWeight = FontWeight.w700;

  static const headlineSize = 24.0;
  static const headlineLineHeight = 32.0;
  static const headlineWeight = FontWeight.w600;

  static const titleLargeSize = 18.0;
  static const titleLargeLineHeight = 26.0;
  static const titleLargeWeight = FontWeight.w600;

  static const titleMediumSize = 15.0;
  static const titleMediumLineHeight = 22.0;
  static const titleMediumWeight = FontWeight.w500;

  static const bodyLargeSize = 14.0;
  static const bodyLargeLineHeight = 20.0;
  static const bodyLargeWeight = FontWeight.w400;

  static const bodySmallSize = 12.0;
  static const bodySmallLineHeight = 16.0;
  static const bodySmallWeight = FontWeight.w400;

  static const labelSmallSize = 11.0;
  static const labelSmallLineHeight = 14.0;
  static const labelSmallWeight = FontWeight.w700;
}

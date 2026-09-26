import 'package:flutter/material.dart';

import 'design_tokens.dart';

// Compatibility aliases. Existing screens still import these names while
// new code should consume AppColors directly.
const Color otelcimBlue = AppColors.primary;
const Color otelcimPrimary = AppColors.primary;
const Color otelcimSecondary = AppColors.secondary;
const Color otelcimSecondaryGrey = AppColors.textSecondaryLight;
const Color otelcimSecondaryGreyDark = AppColors.textSecondaryDark;

TextTheme _textTheme({
  required Color primary,
  required Color secondary,
}) {
  return TextTheme(
    displayLarge: TextStyle(
      color: primary,
      fontSize: AppTypography.displaySize,
      height: AppTypography.displayLineHeight / AppTypography.displaySize,
      fontWeight: AppTypography.displayWeight,
    ),
    headlineMedium: TextStyle(
      color: primary,
      fontSize: AppTypography.headlineSize,
      height: AppTypography.headlineLineHeight / AppTypography.headlineSize,
      fontWeight: AppTypography.headlineWeight,
    ),
    titleLarge: TextStyle(
      color: primary,
      fontSize: AppTypography.titleLargeSize,
      height: AppTypography.titleLargeLineHeight / AppTypography.titleLargeSize,
      fontWeight: AppTypography.titleLargeWeight,
    ),
    titleMedium: TextStyle(
      color: primary,
      fontSize: AppTypography.titleMediumSize,
      height: AppTypography.titleMediumLineHeight / AppTypography.titleMediumSize,
      fontWeight: AppTypography.titleMediumWeight,
    ),
    titleSmall: TextStyle(
      color: primary,
      fontSize: AppTypography.titleMediumSize,
      height: AppTypography.titleMediumLineHeight / AppTypography.titleMediumSize,
      fontWeight: AppTypography.titleMediumWeight,
    ),
    bodyLarge: TextStyle(
      color: primary,
      fontSize: AppTypography.bodyLargeSize,
      height: AppTypography.bodyLargeLineHeight / AppTypography.bodyLargeSize,
      fontWeight: AppTypography.bodyLargeWeight,
    ),
    bodyMedium: TextStyle(
      color: primary,
      fontSize: AppTypography.bodyLargeSize,
      height: AppTypography.bodyLargeLineHeight / AppTypography.bodyLargeSize,
      fontWeight: AppTypography.bodyLargeWeight,
    ),
    bodySmall: TextStyle(
      color: secondary,
      fontSize: AppTypography.bodySmallSize,
      height: AppTypography.bodySmallLineHeight / AppTypography.bodySmallSize,
      fontWeight: AppTypography.bodySmallWeight,
    ),
    labelLarge: TextStyle(
      color: primary,
      fontSize: AppTypography.titleMediumSize,
      height: AppTypography.titleMediumLineHeight / AppTypography.titleMediumSize,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      color: secondary,
      fontSize: AppTypography.bodySmallSize,
      height: AppTypography.bodySmallLineHeight / AppTypography.bodySmallSize,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: TextStyle(
      color: secondary,
      fontSize: AppTypography.labelSmallSize,
      height: AppTypography.labelSmallLineHeight / AppTypography.labelSmallSize,
      fontWeight: AppTypography.labelSmallWeight,
    ),
  );
}

ColorScheme _lightColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.neutral900,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.info,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.infoContainer,
    onTertiaryContainer: AppColors.onInfoContainer,
    error: AppColors.error,
    onError: Colors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.neutral400,
    outlineVariant: AppColors.borderLight,
    surfaceTint: AppColors.primary,
  );
}

ColorScheme _darkColorScheme() {
  return ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.primaryDark,
    onPrimary: AppColors.neutral900,
    primaryContainer: AppColors.primaryHover,
    onPrimaryContainer: AppColors.neutral50,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.neutral900,
    secondaryContainer: AppColors.onSecondaryContainer,
    onSecondaryContainer: AppColors.neutral50,
    tertiary: const Color(0xFFFFB86B),
    onTertiary: AppColors.neutral900,
    tertiaryContainer: AppColors.warningContainer,
    onTertiaryContainer: AppColors.onWarningContainer,
    error: const Color(0xFFFCA5A5),
    onError: AppColors.neutral900,
    errorContainer: AppColors.onErrorContainer,
    onErrorContainer: AppColors.neutral50,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.neutral500,
    outlineVariant: AppColors.borderDark,
    surfaceTint: AppColors.primaryDark,
  );
}

ButtonStyle _filledButtonStyle(ColorScheme colors) {
  return FilledButton.styleFrom(
    backgroundColor: colors.primary,
    foregroundColor: colors.onPrimary,
    disabledBackgroundColor: colors.surfaceContainerHighest,
    disabledForegroundColor: colors.onSurfaceVariant,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    textStyle: const TextStyle(
      fontSize: AppTypography.titleMediumSize,
      fontWeight: FontWeight.w600,
    ),
    elevation: 0,
  );
}

ButtonStyle _outlinedButtonStyle(ColorScheme colors) {
  return OutlinedButton.styleFrom(
    foregroundColor: colors.primary,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    side: BorderSide(color: colors.outline),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    textStyle: const TextStyle(
      fontSize: AppTypography.titleMediumSize,
      fontWeight: FontWeight.w600,
    ),
  );
}

ButtonStyle _textButtonStyle(ColorScheme colors) {
  return TextButton.styleFrom(
    foregroundColor: colors.primary,
    minimumSize: const Size(64, 48),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    tapTargetSize: MaterialTapTargetSize.padded,
    textStyle: const TextStyle(
      fontSize: AppTypography.titleMediumSize,
      fontWeight: FontWeight.w600,
    ),
  );
}

ThemeData _buildTheme({
  required ColorScheme colors,
  required Brightness brightness,
}) {
  final isLight = brightness == Brightness.light;
  final surface = colors.surface;
  final primaryText = isLight
      ? AppColors.textPrimaryLight
      : AppColors.textPrimaryDark;
  final secondaryText = isLight
      ? AppColors.textSecondaryLight
      : AppColors.textSecondaryDark;
  final border = isLight ? AppColors.borderLight : AppColors.borderDark;
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: border),
  );
  final focusedInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
    borderSide: BorderSide(color: colors.primary, width: 2),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor:
        isLight ? AppColors.backgroundLight : AppColors.backgroundDark,
    canvasColor: surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: _textTheme(primary: primaryText, secondary: secondaryText),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: AppTypography.titleLargeSize,
        height: AppTypography.titleLargeLineHeight /
            AppTypography.titleLargeSize,
        fontWeight: AppTypography.titleLargeWeight,
      ),
      iconTheme: IconThemeData(color: primaryText),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.soft,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: focusedInputBorder,
      errorBorder: inputBorder.copyWith(
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: focusedInputBorder.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      disabledBorder: inputBorder,
      labelStyle: TextStyle(color: secondaryText),
      floatingLabelStyle: TextStyle(color: colors.primary),
      hintStyle: TextStyle(color: secondaryText),
      errorStyle: TextStyle(color: colors.error, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _filledButtonStyle(colors),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _filledButtonStyle(colors),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: _outlinedButtonStyle(colors),
    ),
    textButtonTheme: TextButtonThemeData(
      style: _textButtonStyle(colors),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isLight ? AppColors.neutral100 : AppColors.neutral700,
      selectedColor: colors.primaryContainer,
      disabledColor: isLight ? AppColors.neutral100 : AppColors.neutral800,
      secondarySelectedColor: colors.secondaryContainer,
      showCheckmark: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      side: BorderSide(color: border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      labelStyle: TextStyle(
        color: primaryText,
        fontSize: AppTypography.bodySmallSize,
        fontWeight: FontWeight.w500,
      ),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.overlay,
      shadowColor: AppColors.shadowOverlay,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: AppTypography.titleLargeSize,
        height: AppTypography.titleLargeLineHeight /
            AppTypography.titleLargeSize,
        fontWeight: AppTypography.titleLargeWeight,
      ),
      contentTextStyle: TextStyle(
        color: secondaryText,
        fontSize: AppTypography.bodyLargeSize,
        height: AppTypography.bodyLargeLineHeight /
            AppTypography.bodyLargeSize,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: AppElevation.overlay,
      modalElevation: AppElevation.overlay,
      shadowColor: AppColors.shadowOverlay,
      showDragHandle: true,
      dragHandleColor: secondaryText,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: AppElevation.soft,
      shadowColor: AppColors.shadow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.primaryContainer,
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: primaryText,
          fontSize: AppTypography.bodySmallSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surface,
      elevation: AppElevation.soft,
      indicatorColor: colors.primaryContainer,
      selectedIconTheme: IconThemeData(color: colors.primary),
      unselectedIconTheme: IconThemeData(color: secondaryText),
      selectedLabelTextStyle: TextStyle(
        color: colors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: TextStyle(color: secondaryText),
      minWidth: 80,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isLight ? AppColors.neutral800 : AppColors.neutral100,
      contentTextStyle: TextStyle(
        color: isLight ? AppColors.neutral50 : AppColors.neutral900,
        fontSize: AppTypography.bodyLargeSize,
      ),
      actionTextColor: isLight ? AppColors.primaryDark : AppColors.primary,
      behavior: SnackBarBehavior.floating,
      elevation: AppElevation.medium,
      showCloseIcon: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
    ),
    dividerTheme: DividerThemeData(
      color: border,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minVerticalPadding: AppSpacing.sm,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      iconColor: secondaryText,
      textColor: primaryText,
      titleTextStyle: TextStyle(
        color: primaryText,
        fontSize: AppTypography.bodyLargeSize,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        color: secondaryText,
        fontSize: AppTypography.bodySmallSize,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: secondaryText,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      indicatorColor: colors.primary,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: border,
      dividerHeight: 1,
    ),
  );
}

/// Canonical light Material 3 theme.
final ThemeData otelcimLightTheme = _buildTheme(
  colors: _lightColorScheme(),
  brightness: Brightness.light,
);

/// Canonical dark Material 3 theme, ready for a later theme-mode rollout.
final ThemeData otelcimDarkTheme = _buildTheme(
  colors: _darkColorScheme(),
  brightness: Brightness.dark,
);

/// Backwards-compatible name used by existing screens and tests.
final ThemeData otelcimTheme = otelcimLightTheme;

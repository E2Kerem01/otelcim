import 'package:flutter/material.dart';

const Color otelcimBlue = Color(0xFF1976D2);
const Color otelcimSecondaryGrey = Color(0xFF495057);
const Color otelcimSecondaryGreyDark = Color(0xFFCFD8DC);

final ThemeData otelcimTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: otelcimBlue,
    primary: otelcimBlue,
    onPrimary: Colors.white,
    secondary: const Color(0xFF0288D1),
    surface: const Color(0xFFF8F9FA),
    onSurface: const Color(0xFF212529),
    onSurfaceVariant: otelcimSecondaryGrey,
  ),
  scaffoldBackgroundColor: const Color(0xFFF4F5F7),
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: otelcimSecondaryGrey, fontSize: 12),
    bodyMedium: TextStyle(color: Color(0xFF212529), fontSize: 14),
    labelSmall: TextStyle(color: otelcimSecondaryGrey, fontSize: 12),
    labelMedium: TextStyle(color: otelcimSecondaryGrey, fontSize: 12),
    titleSmall: TextStyle(color: Color(0xFF212529), fontSize: 14, fontWeight: FontWeight.w600),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: otelcimBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE9ECEF), width: 1),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: otelcimBlue, width: 2),
    ),
    hintStyle: const TextStyle(color: otelcimSecondaryGrey, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: otelcimBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: otelcimBlue,
    unselectedItemColor: otelcimSecondaryGrey,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontSize: 12),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);

final ThemeData otelcimDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: otelcimBlue,
    brightness: Brightness.dark,
    primary: otelcimBlue,
    onPrimary: Colors.white,
    secondary: const Color(0xFF29B6F6),
    surface: const Color(0xFF172A3A),
    onSurface: const Color(0xFFECEFF1),
    onSurfaceVariant: otelcimSecondaryGreyDark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0F1E2B),
  textTheme: const TextTheme(
    bodySmall: TextStyle(color: otelcimSecondaryGreyDark, fontSize: 12),
    bodyMedium: TextStyle(color: Color(0xFFECEFF1), fontSize: 14),
    labelSmall: TextStyle(color: otelcimSecondaryGreyDark, fontSize: 12),
    labelMedium: TextStyle(color: otelcimSecondaryGreyDark, fontSize: 12),
    titleSmall: TextStyle(color: Color(0xFFECEFF1), fontSize: 14, fontWeight: FontWeight.w600),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF172A3A),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF172A3A),
    elevation: 1,
    shadowColor: Colors.black38,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF2B3644), width: 1),
    ),
    margin: EdgeInsets.zero,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF172A3A),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF2B3644)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF2B3644)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: otelcimBlue, width: 2),
    ),
    hintStyle: const TextStyle(color: otelcimSecondaryGreyDark, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: otelcimBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF172A3A),
    selectedItemColor: Color(0xFF29B6F6),
    unselectedItemColor: otelcimSecondaryGreyDark,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    unselectedLabelStyle: TextStyle(fontSize: 12),
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
);


import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:otelcim/l10n/app_localizations.dart';

/// Goldens are opt-in; see the guard at the top of each golden test's main().
const bool runGoldens = bool.fromEnvironment('RUN_GOLDENS');

const goldenLocales = <Locale>[
  Locale('tr'),
  Locale('en'),
  Locale('ar'),
];

void configureGoldenViewport(
  WidgetTester tester, {
  Size physicalSize = const Size(1440, 2400),
}) {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Ahem's fixed-width glyphs can create false-positive overflows at 1x.
/// Keep every other Flutter error visible to the test framework.
void ignoreRenderFlexOverflowErrors() {
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    previousOnError?.call(details);
  };
  addTearDown(() {
    FlutterError.onError = previousOnError;
  });
}

Widget localizedGoldenApp({
  required Widget home,
  required Locale locale,
  double textScale = 1.0,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      colorSchemeSeed: Colors.blue,
      useMaterial3: true,
    ),
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: home,
  );
}

String goldenLocaleName(Locale locale) => locale.languageCode;

String goldenScaleName(double scale) => scale == 1.0 ? '1x' : '2x';

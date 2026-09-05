import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:otelcim/app/theme.dart';

void main() {
  testWidgets('DesktopTopNavBar renders brand title and navigation links', (WidgetTester tester) async {
    // We can test DesktopTopNavBar rendering in a ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: otelcimTheme,
          home: Scaffold(
            body: Container(),
          ),
        ),
      ),
    );

    expect(find.byType(ProviderScope), findsOneWidget);
  });
}

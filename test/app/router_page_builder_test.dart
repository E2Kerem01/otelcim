import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otelcim/app/router.dart';

class MockGoRouterState extends Fake implements GoRouterState {
  @override
  ValueKey<String> get pageKey => const ValueKey('/test');
  @override
  String? get name => null;
  @override
  String get path => '/test';
  @override
  Map<String, String> get pathParameters => const {};
}

void main() {
  group('buildAppPage', () {
    testWidgets('returns CupertinoPage on iOS platform', (tester) async {
      late Page<dynamic> page;
      final state = MockGoRouterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Builder(
            builder: (context) {
              page = buildAppPage(
                context: context,
                state: state,
                child: const Text('Test'),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(page, isA<CupertinoPage<dynamic>>());
    });

    testWidgets('returns MaterialPage on Android platform', (tester) async {
      late Page<dynamic> page;
      final state = MockGoRouterState();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Builder(
            builder: (context) {
              page = buildAppPage(
                context: context,
                state: state,
                child: const Text('Text'),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(page, isA<MaterialPage<dynamic>>());
    });
  });
}

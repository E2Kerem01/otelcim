import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/core/responsive/max_width_container.dart';
import 'package:otelcim/core/responsive/responsive_layout.dart';

void main() {
  Widget buildTestableWidget({
    required Size screenSize,
    required Widget child,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('ResponsiveLayout Widget', () {
    testWidgets('renders mobile layout when width < 600', (tester) async {
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(599, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('renders tablet layout when 600 <= width < 1024', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Test lower boundary 600px
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(600, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Mobile Layout'), findsNothing);

      // Test mid-tablet size
      tester.view.physicalSize = const Size(800, 800);
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(800, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Tablet Layout'), findsOneWidget);
    });

    testWidgets('renders desktop layout when width >= 1024', (tester) async {
      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Test boundary 1024px
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(1024, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);

      // Test wide desktop 1441px
      tester.view.physicalSize = const Size(1441, 800);
      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(1441, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Layout'),
            desktop: (context, constraints) => const Text('Desktop Layout'),
          ),
        ),
      );

      expect(find.text('Desktop Layout'), findsOneWidget);
    });

    testWidgets('falls back to mobile when tablet and desktop are null', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(1200, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Fallback'),
          ),
        ),
      );

      expect(find.text('Mobile Fallback'), findsOneWidget);
    });

    testWidgets('falls back to tablet when desktop is null on desktop screens', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          screenSize: const Size(1200, 800),
          child: ResponsiveLayout(
            mobile: (context, constraints) => const Text('Mobile Layout'),
            tablet: (context, constraints) => const Text('Tablet Fallback'),
          ),
        ),
      );

      expect(find.text('Tablet Fallback'), findsOneWidget);
    });
  });

  group('BuildContext Extensions', () {
    testWidgets('correctly evaluates extension properties across breakpoints', (tester) async {
      late bool isMobile;
      late bool isTablet;
      late bool isDesktop;
      late bool isWideDesktop;

      Widget buildTestWidget() {
        return Builder(
          builder: (context) {
            isMobile = context.isMobile;
            isTablet = context.isTablet;
            isDesktop = context.isDesktop;
            isWideDesktop = context.isWideDesktop;
            return const SizedBox();
          },
        );
      }

      // Mobile (< 600)
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget(
        screenSize: const Size(599, 800),
        child: buildTestWidget(),
      ));
      expect(isMobile, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
      expect(isWideDesktop, isFalse);

      // Tablet boundary (600)
      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpWidget(buildTestableWidget(
        screenSize: const Size(600, 800),
        child: buildTestWidget(),
      ));
      expect(isMobile, isFalse);
      expect(isTablet, isTrue);
      expect(isDesktop, isFalse);
      expect(isWideDesktop, isFalse);

      // Desktop boundary (1024)
      tester.view.physicalSize = const Size(1024, 800);
      await tester.pumpWidget(buildTestableWidget(
        screenSize: const Size(1024, 800),
        child: buildTestWidget(),
      ));
      expect(isMobile, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
      expect(isWideDesktop, isFalse);

      // Desktop upper boundary (1440)
      tester.view.physicalSize = const Size(1440, 800);
      await tester.pumpWidget(buildTestableWidget(
        screenSize: const Size(1440, 800),
        child: buildTestWidget(),
      ));
      expect(isMobile, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
      expect(isWideDesktop, isFalse);

      // Wide Desktop (> 1440)
      tester.view.physicalSize = const Size(1441, 800);
      await tester.pumpWidget(buildTestableWidget(
        screenSize: const Size(1441, 800),
        child: buildTestWidget(),
      ));
      expect(isMobile, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
      expect(isWideDesktop, isTrue);
    });
  });

  group('MaxWidthContainer Widget', () {
    testWidgets('renders child within constrained box', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaxWidthContainer(
              maxWidth: 1000,
              child: const Text('Constrained Content'),
            ),
          ),
        ),
      );

      expect(find.text('Constrained Content'), findsOneWidget);
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(MaxWidthContainer),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(constrainedBox.constraints.maxWidth, equals(1000));
    });
  });
}

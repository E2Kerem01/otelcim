import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/boosts/presentation/widgets/boost_badge.dart';

import 't3_helpers.dart';

void main() {
  group('BoostBadge.isBoostActive', () {
    test('null listing is not boosted', () {
      expect(BoostBadge.isBoostActive(null), isFalse);
    });

    test('isBoosted=false wins even with a future expiry', () {
      final listing = makeListing(
        isBoosted: false,
        boostExpiresAt: DateTime.now().add(const Duration(days: 5)),
      );
      expect(BoostBadge.isBoostActive(listing), isFalse);
    });

    test('isBoosted=true without an expiry is treated as not active', () {
      expect(BoostBadge.isBoostActive(makeListing(isBoosted: true)), isFalse);
    });

    test('expiry one second in the future is active', () {
      final listing = makeListing(
        isBoosted: true,
        boostExpiresAt: DateTime.now().add(const Duration(seconds: 1)),
      );
      expect(BoostBadge.isBoostActive(listing), isTrue);
    });

    test('expiry one second in the past is expired even though isBoosted is still true', () {
      // No scheduled job ever flips isBoosted back, so the timestamp is the
      // only thing that ends a boost on the client.
      final listing = makeListing(
        isBoosted: true,
        boostExpiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(BoostBadge.isBoostActive(listing), isFalse);
    });

    test('expiry exactly "now" is already expired (strict isAfter)', () {
      final listing = makeListing(isBoosted: true, boostExpiresAt: DateTime.now());
      expect(BoostBadge.isBoostActive(listing), isFalse);
    });

    test('UTC expiry is compared as an instant, not wall-clock', () {
      final listing = makeListing(
        isBoosted: true,
        boostExpiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
      );
      expect(BoostBadge.isBoostActive(listing), isTrue);
    });
  });

  group('BoostBadge widget', () {
    Future<void> pumpBadge(WidgetTester tester, BoostBadge badge, {TextDirection dir = TextDirection.ltr}) {
      return tester.pumpWidget(
        MaterialApp(home: Directionality(textDirection: dir, child: Scaffold(body: Center(child: badge)))),
      );
    }

    testWidgets('renders nothing for a listing whose boost expired', (tester) async {
      await pumpBadge(
        tester,
        BoostBadge(
          listing: makeListing(
            isBoosted: true,
            boostExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ),
      );
      expect(find.text('Öne Çıkarılan İlan'), findsNothing);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('full badge for an active boost shows rocket icon and long label', (tester) async {
      await pumpBadge(
        tester,
        BoostBadge(
          listing: makeListing(
            isBoosted: true,
            boostExpiresAt: DateTime.now().add(const Duration(days: 1)),
          ),
        ),
      );
      expect(find.text('Öne Çıkarılan İlan'), findsOneWidget);
      expect(find.byIcon(Icons.rocket_launch_rounded), findsOneWidget);
    });

    testWidgets('compact badge without a listing always renders (caller decides)', (tester) async {
      await pumpBadge(tester, const BoostBadge(isCompact: true));
      expect(find.text('Öne Çıkan'), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    });

    testWidgets('customText overrides the default label', (tester) async {
      await pumpBadge(tester, const BoostBadge(customText: 'مميز'));
      expect(find.text('مميز'), findsOneWidget);
    });

    testWidgets('renders in RTL without layout exceptions', (tester) async {
      await pumpBadge(tester, const BoostBadge(customText: 'إعلان مميز'), dir: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      expect(find.text('إعلان مميز'), findsOneWidget);
    });
  });
}

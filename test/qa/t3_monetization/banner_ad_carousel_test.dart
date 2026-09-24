import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/presentation/widgets/banner_ad_carousel.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';

import 't3_helpers.dart';

const _launcherChannel = MethodChannel('plugins.flutter.io/url_launcher');

BannerAd _ad(String id, {String targetUrl = '', String advertiser = 'Jolly Tur'}) => BannerAd(
      id: id,
      title: 'Kampanya $id',
      advertiserName: advertiser,
      // Empty image -> built-in gradient fallback, no network in tests.
      imageUrl: '',
      targetUrl: targetUrl,
    );

void main() {
  final launched = <String>[];
  bool launchResult = true;

  setUp(() {
    launched.clear();
    launchResult = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      _launcherChannel,
      (call) async {
        if (call.method == 'launch') {
          launched.add((call.arguments as Map)['url'] as String);
          return launchResult;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_launcherChannel, null);
  });

  Future<void> pumpCarousel(
    WidgetTester tester,
    Stream<List<BannerAd>> banners, {
    TextDirection dir = TextDirection.ltr,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [activeBannerAdsProvider.overrideWith((ref) => banners)],
        child: MaterialApp(
          home: Directionality(
            textDirection: dir,
            child: const Scaffold(
              body: Column(children: [BannerAdCarousel(), Text('FEED')]),
            ),
          ),
        ),
      ),
    );
  }

  double? currentPage(WidgetTester tester) => tester.widget<PageView>(find.byType(PageView)).controller?.page;

  group('BannerAdCarousel — empty / loading / error take no space', () {
    testWidgets('empty list renders nothing', (tester) async {
      await pumpCarousel(tester, Stream.value(const []));
      await tester.pump();
      expect(find.byType(PageView), findsNothing);
      expect(tester.getSize(find.byType(BannerAdCarousel)), Size.zero);
    });

    testWidgets('while loading, the feed is not pushed down', (tester) async {
      await pumpCarousel(tester, const Stream.empty());
      await tester.pump();
      expect(tester.getSize(find.byType(BannerAdCarousel)), Size.zero);
      expect(find.text('FEED'), findsOneWidget);
    });

    testWidgets('stream error renders nothing instead of an error box', (tester) async {
      await pumpCarousel(tester, Stream.error(Exception('permission-denied')));
      await tester.pump();
      expect(find.byType(PageView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('BannerAdCarousel — autoplay', () {
    testWidgets('single banner: no page dots and it never auto-scrolls', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1')]));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsNothing);
      await tester.pump(const Duration(seconds: 11));
      expect(currentPage(tester), 0);
    });

    testWidgets('three banners: one dot each, advances every 5 s and wraps to the first', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1'), _ad('2'), _ad('3')]));
      await tester.pump();
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
      expect(find.text('Sponsorlu'), findsOneWidget);

      Future<void> tick() async {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }

      await tick();
      expect(currentPage(tester), 1);
      await tick();
      expect(currentPage(tester), 2);
      await tick();
      expect(currentPage(tester), 0);
    });

    testWidgets('removing the carousel cancels the autoplay timer', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1'), _ad('2')]));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 12));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a live update that drops banners keeps a valid dot highlighted', (tester) async {
      final controller = StreamController<List<BannerAd>>();
      addTearDown(controller.close);
      await pumpCarousel(tester, controller.stream);
      controller.add([_ad('1'), _ad('2'), _ad('3')]);
      await tester.pump();
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
      expect(currentPage(tester), 2);

      // Admin deactivates two banners while the user sits on page 3.
      controller.add([_ad('1')]);
      await tester.pumpAndSettle();
      expect(find.text('Kampanya 1'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('BannerAdCarousel — tapping a banner', () {
    Future<void> tapBanner(WidgetTester tester) async {
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();
    }

    testWidgets('opens the target URL externally', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1', targetUrl: 'https://www.jollytur.com/kampanya')]));
      await tester.pump();
      await tapBanner(tester);
      expect(launched, ['https://www.jollytur.com/kampanya']);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('empty / whitespace target URL does nothing', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1', targetUrl: '   ')]));
      await tester.pump();
      await tapBanner(tester);
      expect(launched, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('platform refusing to open the link shows "Bağlantı açılamadı."', (tester) async {
      launchResult = false;
      await pumpCarousel(tester, Stream.value([_ad('1', targetUrl: 'https://example.com')]));
      await tester.pump();
      await tapBanner(tester);
      expect(find.text('Bağlantı açılamadı.'), findsOneWidget);
    });

    testWidgets('malformed URL is reported to the user instead of crashing', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1', targetUrl: 'http://[::1')]));
      await tester.pump();
      await tapBanner(tester);
      expect(launched, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BannerAdCarousel — text rendering', () {
    testWidgets('[BUG-t3-16] advertiser name is upper-cased with Turkish rules (i -> İ)', (tester) async {
      await pumpCarousel(tester, Stream.value([_ad('1', advertiser: 'Kaşif Turizm')]));
      await tester.pump();
      // String.toUpperCase() is locale-independent: "Kaşif" -> "KAŞIF".
      expect(find.text('KAŞİF TURİZM'), findsOneWidget);
    }, skip: widgetBug('BUG-t3-16: advertiserName.toUpperCase() gives "KAŞIF TURIZM" (dotless I) for Turkish names'));

    testWidgets('Arabic banner in RTL renders without layout errors', (tester) async {
      await pumpCarousel(
        tester,
        Stream.value([
          const BannerAd(
            id: 'ar',
            title: 'عروض الصيف في أنطاليا',
            advertiserName: 'جولي تور',
            imageUrl: '',
            targetUrl: '',
          ),
        ]),
        dir: TextDirection.rtl,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('جولي تور'), findsOneWidget);
    });
  });
}

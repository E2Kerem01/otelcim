import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/presentation/admin_banner_ads_screen.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('AdminBannerAdsScreen Widget Tests', () {
    late MockBannerAdService mockBannerAdService;

    setUp(() {
      mockBannerAdService = MockBannerAdService();
    });

    Widget buildBannerAdsScreen({
      required Stream<List<BannerAd>> bannersStream,
    }) {
      return createAdminTestApp(
        overrides: [
          bannerAdServiceProvider.overrideWith((ref) => mockBannerAdService),
          allBannerAdsProvider.overrideWith((ref) => bannersStream),
        ],
        child: const AdminBannerAdsScreen(),
      );
    }

    testWidgets('displays loading indicator while banners are loading', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<BannerAd>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when stream emits error', (tester) async {
      await configureTestScreenSize(tester);

      final errorStream = Stream<List<BannerAd>>.error(Exception('Firestore banner load failed'));

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: errorStream));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hata:'), findsOneWidget);
    });

    testWidgets('displays empty state with add button when no banner ads exist', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text("Henüz Reklam Banner'ı Yok"), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, "İlk Banner'ı Ekle"), findsOneWidget);
    });

    testWidgets('renders list of banner ad cards with titles and active switches', (tester) async {
      await configureTestScreenSize(tester);

      final banners = [
        createDummyBannerAd(
          id: 'banner_1',
          title: 'Erken Rezervasyon Kampanyası',
          advertiserName: 'Antalya Turizm',
          targetUrl: 'https://antalyaturizm.com',
          order: 1,
          isActive: true,
        ),
        createDummyBannerAd(
          id: 'banner_2',
          title: 'Kış Sezonu İndirimi',
          advertiserName: 'Uludağ Resort',
          targetUrl: 'https://uludagresort.com',
          order: 2,
          isActive: false,
        ),
      ];

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value(banners)));
      await tester.pumpAndSettle();

      expect(find.text('Erken Rezervasyon Kampanyası'), findsOneWidget);
      expect(find.text('Sponsor: Antalya Turizm'), findsOneWidget);
      expect(find.text('Hedef: https://antalyaturizm.com'), findsOneWidget);
      expect(find.text('Sıra: 1'), findsOneWidget);

      expect(find.text('Kış Sezonu İndirimi'), findsOneWidget);
      expect(find.text('Sponsor: Uludağ Resort'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));
      expect(tester.widget<Switch>(switches.at(0)).value, isTrue);
      expect(tester.widget<Switch>(switches.at(1)).value, isFalse);
    });

    testWidgets('toggles banner active switch and calls service toggleActive', (tester) async {
      await configureTestScreenSize(tester);

      final banner = createDummyBannerAd(
        id: 'banner_toggle_test',
        title: 'Aktiflik Testi',
        isActive: true,
      );

      when(() => mockBannerAdService.toggleActive(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([banner])));
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      verify(() => mockBannerAdService.toggleActive('banner_toggle_test', false)).called(1);
    });

    testWidgets('deletes banner upon confirmation dialog', (tester) async {
      await configureTestScreenSize(tester);

      final banner = createDummyBannerAd(
        id: 'banner_delete_me',
        title: 'Silinecek Reklam',
      );

      when(() => mockBannerAdService.deleteBannerAd(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([banner])));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();

      expect(find.text('Banner Silinsin mi?'), findsOneWidget);
      expect(find.text('"Silinecek Reklam" reklam banner\'ı tamamen silinecek.'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sil'));
      await tester.pumpAndSettle();

      verify(() => mockBannerAdService.deleteBannerAd('banner_delete_me')).called(1);
      expect(find.text('Banner silindi.'), findsOneWidget);
    });

    testWidgets('cancelling delete dialog does not call deleteBannerAd', (tester) async {
      await configureTestScreenSize(tester);

      final banner = createDummyBannerAd(
        id: 'banner_keep_me',
        title: 'Kalacak Reklam',
      );

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([banner])));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => mockBannerAdService.deleteBannerAd(any()));
    });

    testWidgets('floating action button opens new banner bottom sheet form', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Yeni Banner'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Reklam Banner\'ı'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Banner Başlığı *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Hedef URL *'), findsOneWidget);
    });

    testWidgets('edit button opens bottom sheet with existing banner data prefilled', (tester) async {
      await configureTestScreenSize(tester);

      final banner = createDummyBannerAd(
        id: 'banner_edit_test',
        title: 'Mevcut Kampanya Başlığı',
        advertiserName: 'Otel A',
        targetUrl: 'https://target.com',
      );

      await tester.pumpWidget(buildBannerAdsScreen(bannersStream: Stream.value([banner])));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Düzenle'));
      await tester.pumpAndSettle();

      expect(find.text('Banner Düzenle'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Mevcut Kampanya Başlığı'), findsOneWidget);
    });
  });
}

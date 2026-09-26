import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/presentation/admin_banner_ads_screen.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/shared/providers/firestore_provider.dart';

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
      required FirebaseFirestore db,
    }) {
      when(() => mockBannerAdService.adminQuery(filter: any(named: 'filter')))
          .thenAnswer((invocation) {
        final filter = invocation.namedArguments[#filter] as String;
        return adminBannerAdsQuery(db, filter: filter);
      });

      return createAdminTestApp(
        overrides: [
          firestoreProvider.overrideWithValue(db),
          bannerAdServiceProvider.overrideWith((ref) => mockBannerAdService),
        ],
        child: const AdminBannerAdsScreen(),
      );
    }

    Future<void> seedBanner(FakeFirebaseFirestore db, BannerAd banner) {
      return db.collection('banner_ads').doc(banner.id).set(banner.toMap());
    }

    testWidgets('displays loading indicator while banners are loading', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(buildBannerAdsScreen(db: db));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when stream emits error', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await db.collection('banner_ads').doc('invalid_banner').set({
        'title': 'Bozuk Banner',
        'advertiserName': 'Test',
        'imageUrl': 'https://example.com/banner.png',
        'targetUrl': 'https://example.com',
        'order': 'not-an-int',
        'isActive': true,
        'createdAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
      });

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      expect(find.text('Kayıtlar yüklenemedi.'), findsOneWidget);
    });

    testWidgets('displays empty state with add button when no banner ads exist', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtreyle banner bulunamadı.'), findsOneWidget);
      expect(find.widgetWithText(FloatingActionButton, 'Yeni Banner'), findsOneWidget);
    });

    testWidgets('renders list of banner ad cards with titles and active switches', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await seedBanner(
        db,
        createDummyBannerAd(
          id: 'banner_1',
          title: 'Erken Rezervasyon Kampanyası',
          advertiserName: 'Antalya Turizm',
          targetUrl: 'https://antalyaturizm.com',
          order: 1,
          isActive: true,
        ),
      );
      await seedBanner(
        db,
        createDummyBannerAd(
          id: 'banner_2',
          title: 'Kış Sezonu İndirimi',
          advertiserName: 'Uludağ Resort',
          targetUrl: 'https://uludagresort.com',
          order: 2,
          isActive: false,
        ),
      );

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Tümü'));
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

      final db = FakeFirebaseFirestore();
      await seedBanner(db, banner);

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
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

      final db = FakeFirebaseFirestore();
      await seedBanner(db, banner);

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();

      expect(find.text('Banner silinsin mi?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('"Silinecek Reklam" reklam bannerı tamamen silinecek.'),
        ),
        findsOneWidget,
      );

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

      final db = FakeFirebaseFirestore();
      await seedBanner(db, banner);

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Sil'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'İptal'));
      await tester.pumpAndSettle();

      verifyNever(() => mockBannerAdService.deleteBannerAd(any()));
    });

    testWidgets('floating action button opens new banner bottom sheet form', (tester) async {
      await configureTestScreenSize(tester);

      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FloatingActionButton, 'Yeni Banner'));
      await tester.pumpAndSettle();

      expect(find.text('Yeni Banner Ekle'), findsOneWidget);
      expect(find.text('Banner Başlığı *'), findsOneWidget);
      expect(find.text('Hedef Bağlantı (URL) *'), findsOneWidget);
    });

    testWidgets('edit button opens bottom sheet with existing banner data prefilled', (tester) async {
      await configureTestScreenSize(tester);

      final banner = createDummyBannerAd(
        id: 'banner_edit_test',
        title: 'Mevcut Kampanya Başlığı',
        advertiserName: 'Otel A',
        targetUrl: 'https://target.com',
      );

      final db = FakeFirebaseFirestore();
      await seedBanner(db, banner);

      await tester.pumpWidget(buildBannerAdsScreen(db: db));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Düzenle'));
      await tester.pumpAndSettle();

      expect(find.text('Banner Düzenle'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField).first).controller?.text,
        'Mevcut Kampanya Başlığı',
      );
    });
  });
}

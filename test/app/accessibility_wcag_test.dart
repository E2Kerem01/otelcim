import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/app/theme.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/chat/presentation/widgets/chat_detail_widgets.dart';
import 'package:otelcim/features/home/presentation/home_screen.dart';
import 'package:otelcim/features/home/presentation/widgets/home_screen_widgets.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/models/user_profile.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';

double _srgbToLinear(double channel) {
  if (channel <= 0.04045) {
    return channel / 12.92;
  }
  return pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

double _relativeLuminance(Color color) {
  final r = _srgbToLinear(color.r);
  final g = _srgbToLinear(color.g);
  final b = _srgbToLinear(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color c1, Color c2) {
  final lum1 = _relativeLuminance(c1);
  final lum2 = _relativeLuminance(c2);
  final lighter = max(lum1, lum2);
  final darker = min(lum1, lum2);
  return (lighter + 0.05) / (darker + 0.05);
}

class _MockPaginatedListingsNotifier extends StateNotifier<PaginatedListingsState>
    implements PaginatedListingsNotifier {
  _MockPaginatedListingsNotifier()
      : super(
          PaginatedListingsState(
            listings: [
              Listing(
                id: 'l1',
                posterId: 'p1',
                posterName: 'Grand Hotel',
                title: 'Resepsiyonist',
                description: 'Deneyimli',
                category: 'resepsiyon',
                location: 'Antalya',
                salary: '35.000 TL',
                contactInfo: '05320000000',
              ),
            ],
            hasMore: false,
            isLoading: false,
          ),
        );

  @override
  PaginationParams get params => (
        category: null,
        searchQuery: '',
        city: null,
        region: null,
        minSalaryTl: null,
        maxSalaryTl: null,
        dateFilter: ListingDateFilter.all,
        employmentType: null,
        sortOrder: ListingSortOrder.newest,
        season: null,
      );

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> refresh() async {}
}

class _FakeNotificationService implements NotificationService {
  @override
  Future<void> selectRegion(String regionId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeListingService implements ListingService {
  @override
  Future<void> seedSampleListings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('D33 - WCAG Contrast & Accessibility Tests', () {
    test('Secondary grey text meets WCAG 4.5:1 on light theme surfaces', () {
      final whiteContrast = _contrastRatio(otelcimSecondaryGrey, Colors.white);
      expect(whiteContrast, greaterThanOrEqualTo(4.5),
          reason: 'Secondary grey on white must reach >= 4.5:1');

      final surfaceContrast = _contrastRatio(
        otelcimSecondaryGrey,
        otelcimTheme.colorScheme.surface,
      );
      expect(surfaceContrast, greaterThanOrEqualTo(4.5),
          reason: 'Secondary grey on light surface must reach >= 4.5:1');

      final scaffoldContrast = _contrastRatio(
        otelcimSecondaryGrey,
        otelcimTheme.scaffoldBackgroundColor,
      );
      expect(scaffoldContrast, greaterThanOrEqualTo(4.5),
          reason: 'Secondary grey on light scaffold must reach >= 4.5:1');

      expect(otelcimTheme.colorScheme.onSurfaceVariant, otelcimSecondaryGrey);
    });

    test('Secondary grey text meets WCAG 4.5:1 on dark theme surfaces', () {
      final surfaceContrast = _contrastRatio(
        otelcimSecondaryGreyDark,
        otelcimDarkTheme.colorScheme.surface,
      );
      expect(surfaceContrast, greaterThanOrEqualTo(4.5),
          reason: 'Dark secondary grey on dark surface must reach >= 4.5:1');

      final scaffoldContrast = _contrastRatio(
        otelcimSecondaryGreyDark,
        otelcimDarkTheme.scaffoldBackgroundColor,
      );
      expect(scaffoldContrast, greaterThanOrEqualTo(4.5),
          reason: 'Dark secondary grey on dark scaffold must reach >= 4.5:1');

      expect(otelcimDarkTheme.colorScheme.onSurfaceVariant, otelcimSecondaryGreyDark);
    });

    testWidgets('ChatMessageComposer send button has >= 48x48 min size and tooltip/semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageComposer(
              controller: TextEditingController(),
              onSend: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final sendIconFinder = find.byIcon(Icons.send_rounded);
      expect(sendIconFinder, findsOneWidget);

      final iconButtonFinder = find.ancestor(
        of: sendIconFinder,
        matching: find.byType(IconButton),
      );
      expect(iconButtonFinder, findsOneWidget);

      final iconButton = tester.widget<IconButton>(iconButtonFinder);
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, isNotEmpty);
      expect(iconButton.constraints?.minWidth, greaterThanOrEqualTo(48.0));
      expect(iconButton.constraints?.minHeight, greaterThanOrEqualTo(48.0));

      // Check rendered size is at least 48x48
      final buttonSize = tester.getSize(iconButtonFinder);
      expect(buttonSize.width, greaterThanOrEqualTo(48.0));
      expect(buttonSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Home feed table view toggle button has >= 48x48 min hit area and tooltip/semantics', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paginatedListingsProvider.overrideWith(
              (ref, params) => _MockPaginatedListingsNotifier(),
            ),
            activeBannerAdsProvider.overrideWith((ref) => Stream.value([])),
            notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
            listingServiceProvider.overrideWithValue(_FakeListingService()),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            locale: Locale('tr', ''),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('tr', '')],
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final tableToggleFinder = find.byKey(const Key('grid_col_table'));
      expect(tableToggleFinder, findsOneWidget);

      final size = tester.getSize(tableToggleFinder);
      expect(size.width, greaterThanOrEqualTo(48.0));
      expect(size.height, greaterThanOrEqualTo(48.0));

      // Verify Tooltip exists on the toggle
      final tooltipFinder = find.ancestor(
        of: tableToggleFinder,
        matching: find.byType(Tooltip),
      );
      expect(tooltipFinder, findsOneWidget);
      final tooltip = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltip.message, 'Tablo Görünümü');
    });

    testWidgets('ChatAppBarTitle badges have font size >= 12pt on solid background', (tester) async {
      final testProfile = UserProfile(
        id: 'user_123',
        email: 'candidate@test.com',
        userType: 'jobseeker',
        availableImmediately: true,
        introVideoUrl: 'https://example.com/video.mp4',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              title: ChatAppBarTitle(otherProfile: testProfile),
            ),
          ),
        ),
      );
      await tester.pump();

      // Check "Hemen Başlayabilir" badge text
      final availableTextFinder = find.text('Hemen Başlayabilir');
      expect(availableTextFinder, findsOneWidget);
      final availableText = tester.widget<Text>(availableTextFinder);
      expect(availableText.style?.fontSize, greaterThanOrEqualTo(12.0));
      expect(availableText.style?.color, Colors.white);

      // Check "Tanıtım Videosu" badge text
      final videoTextFinder = find.text('Tanıtım Videosu');
      expect(videoTextFinder, findsOneWidget);
      final videoText = tester.widget<Text>(videoTextFinder);
      expect(videoText.style?.fontSize, greaterThanOrEqualTo(12.0));
      expect(videoText.style?.color, Colors.white);
    });

    testWidgets('ListingCard badges have font size >= 12pt on solid background', (tester) async {
      final listing = Listing(
        id: 'l1',
        posterId: 'p1',
        posterName: 'Grand Hotel',
        title: 'Resepsiyonist',
        description: 'Deneyimli',
        category: 'resepsiyon',
        location: 'Antalya',
        salary: '35.000 TL',
        contactInfo: '05320000000',
        isUrgent: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: MaterialApp(
            locale: const Locale('tr', ''),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: Scaffold(
              body: ListingCard(listing: listing, columnCount: 1),
            ),
          ),
        ),
      );
      await tester.pump();

      // Category badge
      final catFinder = find.text('Resepsiyon');
      expect(catFinder, findsOneWidget);
      final catText = tester.widget<Text>(catFinder);
      expect(catText.style?.fontSize, greaterThanOrEqualTo(12.0));
      expect(catText.style?.color, Colors.white);

      // Urgent badge
      final urgentFinder = find.text('ACİL');
      expect(urgentFinder, findsOneWidget);
      final urgentText = tester.widget<Text>(urgentFinder);
      expect(urgentText.style?.fontSize, greaterThanOrEqualTo(12.0));
      expect(urgentText.style?.color, Colors.white);
    });
  });
}

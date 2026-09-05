import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/home/presentation/home_screen.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';

class MockPaginatedListingsNotifier extends StateNotifier<PaginatedListingsState>
    implements PaginatedListingsNotifier {
  MockPaginatedListingsNotifier(List<Listing> listings)
      : super(
          PaginatedListingsState(
            listings: listings,
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

class FakeNotificationService implements NotificationService {
  @override
  Future<void> selectRegion(String regionId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeListingService implements ListingService {
  @override
  Future<void> seedSampleListings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleListing = Listing(
    id: 'l1',
    posterId: 'p1',
    posterName: 'Grand Hotel',
    title: 'Resepsiyon Görevlisi',
    description: 'Deneyimli resepsiyonist aranıyor',
    category: 'resepsiyon',
    location: 'Antalya',
    salary: '35.000 TL',
    contactInfo: '05320000000',
  );

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        paginatedListingsProvider.overrideWith(
          (ref, params) => MockPaginatedListingsNotifier([sampleListing]),
        ),
        activeBannerAdsProvider.overrideWith(
          (ref) => Stream.value([]),
        ),
        notificationServiceProvider.overrideWithValue(FakeNotificationService()),
        listingServiceProvider.overrideWithValue(FakeListingService()),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('tr', ''),
          Locale('en', ''),
        ],
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen Grid & Search Tests', () {
    testWidgets('renders search bar with hint and interactive clear button', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Verify search field exists with hint
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      expect(find.text('İş ilanı ara...'), findsOneWidget);

      // Enter text into search bar
      await tester.enterText(searchField, 'Resepsiyonist');
      await tester.pump(const Duration(milliseconds: 300));

      // Clear button should be visible when search text is non-empty
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Search field should be empty
      expect(find.text('Resepsiyonist'), findsNothing);
    });

    testWidgets('renders grid column selector buttons (1, 2, 3, 4 columns)', (tester) async {
      tester.view.physicalSize = const Size(1200, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Check column toggle keys exist for 1, 2, 3, and 4 columns
      for (int i = 1; i <= 4; i++) {
        final colFinder = find.byKey(Key('grid_col_$i'));
        expect(colFinder, findsOneWidget);

        // Tap column toggle button
        await tester.tap(colFinder);
        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });
}

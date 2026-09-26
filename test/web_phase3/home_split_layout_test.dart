import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/home/presentation/home_screen.dart';
import 'package:otelcim/features/home/presentation/widgets/listing_feed_card.dart';
import 'package:otelcim/features/home/presentation/widgets/listing_filters_panel.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/widgets/listing_preview_pane.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';

class _FakePaginatedListingsNotifier
    extends StateNotifier<PaginatedListingsState>
    implements PaginatedListingsNotifier {
  _FakePaginatedListingsNotifier(List<Listing> listings)
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

class _FakeNotificationService implements NotificationService {
  @override
  Future<void> selectRegion(String regionId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeListingService implements ListingService {
  @override
  Future<int> countActiveListings({String? region, String? season}) async => 0;

  @override
  Future<void> seedSampleListings() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Listing _listing(String id) => Listing(
      id: id,
      posterId: 'poster-$id',
      posterName: 'Otel $id',
      title: 'Resepsiyonist $id',
      description: 'İlan açıklaması',
      category: 'resepsiyon',
      location: 'Antalya',
      salary: '35.000 TL',
      contactInfo: '05000000000',
    );

Widget _home(List<Listing> listings) {
  return ProviderScope(
    overrides: [
      paginatedListingsProvider.overrideWith(
        (ref, params) => _FakePaginatedListingsNotifier(listings),
      ),
      singleListingProvider('listing-1').overrideWith(
        (ref) => Future.value(listings[0]),
      ),
      singleListingProvider('listing-2').overrideWith(
        (ref) => Future.value(listings[1]),
      ),
      activeBannerAdsProvider.overrideWith((ref) => Stream.value([])),
      notificationServiceProvider.overrideWithValue(_FakeNotificationService()),
      listingServiceProvider.overrideWithValue(_FakeListingService()),
      authStateProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: const MaterialApp(
      locale: Locale('tr'),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('tr'), Locale('en')],
      home: HomeScreen(),
    ),
  );
}

Future<void> _pumpAtWidth(
  WidgetTester tester,
  double width,
  List<Listing> listings,
) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_home(listings));
  await tester.pump();
}

void main() {
  final listings = [_listing('listing-1'), _listing('listing-2')];

  testWidgets('390px keeps the mobile filter button and has no sidebar', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 390, listings);

    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byType(ListingFiltersPanel), findsNothing);
  });

  testWidgets('1100px shows the filter sidebar without a preview', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 1100, listings);

    expect(find.byType(ListingFiltersPanel), findsOneWidget);
    expect(find.byType(ListingPreviewPane), findsNothing);
  });

  testWidgets('1400px shows preview and selecting a card changes its listing', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 1400, listings);

    expect(find.byType(ListingFiltersPanel), findsOneWidget);
    final previewFinder = find.byType(ListingPreviewPane);
    expect(previewFinder, findsOneWidget);
    expect(
      tester.widget<ListingPreviewPane>(previewFinder).listingId,
      'listing-1',
    );

    await tester.tap(find.byType(ListingFeedCard).at(1));
    await tester.pump();

    expect(
      tester.widget<ListingPreviewPane>(previewFinder).listingId,
      'listing-2',
    );
  });
}

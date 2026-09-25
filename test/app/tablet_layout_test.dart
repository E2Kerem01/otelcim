import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/home/presentation/home_screen.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/providers/paginated_listings_provider.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';
import 'package:otelcim/shared/widgets/desktop_top_nav_bar.dart';

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

class FakeStatefulNavigationShell extends Fake
    implements StatefulNavigationShell {
  @override
  int get currentIndex => 0;

  @override
  void goBranch(int index, {bool initialLocation = false}) {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeStatefulNavigationShell';
}

class _SignedOutAuthService extends Mock implements AuthService {
  @override
  AppUser? get currentUser => null;
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

  Widget buildHomeTestableWidget() {
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
        locale: Locale('tr', ''),
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

  group('D32 - Tablet layout & responsive shell tests', () {
    testWidgets('DesktopTopNavBar wraps its content in SafeArea with bottom: false', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            authServiceProvider.overrideWith((ref) => _SignedOutAuthService()),
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
              body: DesktopTopNavBar(
                navigationShell: FakeStatefulNavigationShell(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Find SafeArea inside DesktopTopNavBar
      final safeAreaFinder = find.descendant(
        of: find.byType(DesktopTopNavBar),
        matching: find.byType(SafeArea),
      );
      expect(safeAreaFinder, findsOneWidget);

      final safeArea = tester.widget<SafeArea>(safeAreaFinder);
      expect(safeArea.bottom, isFalse);
    });

    testWidgets('HomeScreen hides mobile AppBar on tablet width (800dp >= 768dp)', (tester) async {
      // 800dp wide tablet screen (e.g. 1600x2560 at 2.0 devicePixelRatio)
      tester.view.physicalSize = const Size(800, 1280);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeTestableWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // No double header: mobile AppBar should NOT be present on tablet layout
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('HomeScreen shows mobile AppBar on phone width (400dp < 768dp)', (tester) async {
      // Standard mobile phone screen
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildHomeTestableWidget());
      await tester.pump(const Duration(milliseconds: 300));

      // Mobile AppBar should be present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Otelcim'), findsOneWidget);
    });
  });
}

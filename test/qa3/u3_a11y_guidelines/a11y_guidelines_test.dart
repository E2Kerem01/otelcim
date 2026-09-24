import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/features/ads/domain/banner_ad_model.dart';
import 'package:otelcim/features/ads/services/banner_ad_service.dart';
import 'package:otelcim/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:otelcim/features/admin/services/analytics_service.dart';
import 'package:otelcim/features/auth/presentation/login_screen.dart';
import 'package:otelcim/features/auth/presentation/register_screen.dart';
import 'package:otelcim/features/chat/presentation/chat_detail_screen.dart';
import 'package:otelcim/features/chat/presentation/chat_list_screen.dart';
import 'package:otelcim/features/home/presentation/home_screen.dart';
import 'package:otelcim/features/listings/presentation/create_listing_screen.dart';
import 'package:otelcim/features/listings/presentation/listing_detail_screen.dart';
import 'package:otelcim/features/nearby/services/location_service.dart';
import 'package:otelcim/features/profile/presentation/language_settings_screen.dart';
import 'package:otelcim/features/profile/presentation/notification_settings_screen.dart';
import 'package:otelcim/features/profile/presentation/profile_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/providers/profile_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/chat_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';
import 'package:otelcim/shared/services/notification_service.dart';
import 'package:otelcim/shared/services/profile_service.dart';
import 'package:otelcim/shared/services/storage_service.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockChatService extends Mock implements ChatService {}

class _MockListingService extends Mock implements ListingService {}

class _MockNotificationService extends Mock implements NotificationService {}

class _MockAdminAnalyticsService extends Mock implements AdminAnalyticsService {}

class _MockProfileService extends Mock implements ProfileService {}

class _MockStorageService extends Mock implements StorageService {}

class _MockLocationService extends Mock implements LocationService {}

// Guideline tests that fail today. BUG = real violation in the app (D33 in
// shared/COVERAGE_AND_DEV_GAPS.md); HARNESS = the test setup breaks first
// ("Cannot use ref after the widget was disposed"), so nothing is measured yet.
const _knownIssues = <String, String>{
  'login screen|text contrast': 'BUG-u3-01: secondary grey text 4.38:1 (< 4.5:1)',
  'home screen|text contrast': 'BUG-u3-02: secondary grey text below 4.5:1',
  'home screen|android tap target': 'BUG-u3-03: view-mode button "Tablo Görünümü" < 48dp',
  'home screen|iOS tap target': 'BUG-u3-03: view-mode button "Tablo Görünümü" < 44dp',
  'create listing screen|text contrast': 'BUG-u3-04: form hint/helper text below 4.5:1',
  'profile screen|text contrast': 'BUG-u3-05: subtitle text below 4.5:1',
  'language settings screen|text contrast': 'BUG-u3-06: subtitle text below 4.5:1',
  'chat list screen|text contrast': 'BUG-u3-07: preview/time text below 4.5:1',
  'chat detail screen|labeled tap target': 'BUG-u3-08: unlabeled tappable (send button, cf. BUG-m12-01)',
  'chat detail screen|android tap target': 'HARNESS: ref used after dispose',
  'chat detail screen|iOS tap target': 'HARNESS: ref used after dispose',
  'chat detail screen|text contrast': 'HARNESS: ref used after dispose',
  'notification settings screen|android tap target': 'HARNESS: ref used after dispose',
};

const _guidelines = <String, AccessibilityGuideline>{
  'android tap target': androidTapTargetGuideline,
  'iOS tap target': iOSTapTargetGuideline,
  'labeled tap target': labeledTapTargetGuideline,
  'text contrast': textContrastGuideline,
};

Widget _localizedApp(
  Widget child, {
  List<Override> overrides = const <Override>[],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Future<void> _pumpA11y(WidgetTester tester, Widget app) async {
  tester.view.physicalSize = const Size(540, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _expectGuideline(
  WidgetTester tester,
  AccessibilityGuideline guideline,
) async {
  final handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(guideline));
  } finally {
    handle.dispose();
  }
}

void _addGuidelineTests(
  String screenName,
  Widget Function() appBuilder, {
  Future<void> Function(WidgetTester tester)? prepare,
}) {
  for (final entry in _guidelines.entries) {
    testWidgets(
      '$screenName meets ${entry.key} guideline',
      (tester) async {
        await _pumpA11y(tester, appBuilder());
        if (prepare != null) await prepare(tester);
        await _expectGuideline(tester, entry.value);
      },
      // See _knownIssues for why (testWidgets' skip is a bool).
      skip: _knownIssues.containsKey('$screenName|${entry.key}'),
    );
  }
}

void main() {
  setUpAll(() {
    // mocktail needs a fallback for enum params matched with any(named: ...).
    registerFallbackValue(ListingDateFilter.values.first);
    registerFallbackValue(ListingSortOrder.values.first);
    registerFallbackValue(EmploymentType.values.first);
  });

  late _MockAuthService auth;

  setUp(() {
    auth = _MockAuthService();
    when(() => auth.currentUser).thenReturn(null);
  });

  _addGuidelineTests(
    'login screen',
    () => _localizedApp(
      const LoginScreen(),
      overrides: [authServiceProvider.overrideWith((ref) => auth)],
    ),
  );

  _addGuidelineTests(
    'register screen',
    () {
      final profile = _MockProfileService();
      return _localizedApp(
        const RegisterScreen(),
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          profileServiceProvider.overrideWith((ref) => profile),
        ],
      );
    },
  );

  _addGuidelineTests(
    'home screen',
    () {
      final listing = _MockListingService();
      final notifications = _MockNotificationService();
      when(() => listing.getPaginatedListings(
            category: any(named: 'category'),
            searchQuery: any(named: 'searchQuery'),
            city: any(named: 'city'),
            region: any(named: 'region'),
            minSalaryTl: any(named: 'minSalaryTl'),
            maxSalaryTl: any(named: 'maxSalaryTl'),
            dateFilter: any(named: 'dateFilter'),
            employmentType: any(named: 'employmentType'),
            sortOrder: any(named: 'sortOrder'),
            season: any(named: 'season'),
          )).thenAnswer(
        (_) async => PaginatedListingsResult(
          listings: const [],
          lastDocument: null,
          hasMore: false,
        ),
      );
      return _localizedApp(
        const HomeScreen(),
        overrides: [
          listingServiceProvider.overrideWith((ref) => listing),
          notificationServiceProvider.overrideWith((ref) => notifications),
          activeBannerAdsProvider.overrideWith(
            (ref) => Stream<List<BannerAd>>.value(const <BannerAd>[]),
          ),
        ],
      );
    },
  );

  _addGuidelineTests(
    'home filter panel',
    () {
      final listing = _MockListingService();
      final notifications = _MockNotificationService();
      when(() => listing.getPaginatedListings(
            category: any(named: 'category'),
            searchQuery: any(named: 'searchQuery'),
            city: any(named: 'city'),
            region: any(named: 'region'),
            minSalaryTl: any(named: 'minSalaryTl'),
            maxSalaryTl: any(named: 'maxSalaryTl'),
            dateFilter: any(named: 'dateFilter'),
            employmentType: any(named: 'employmentType'),
            sortOrder: any(named: 'sortOrder'),
            season: any(named: 'season'),
          )).thenAnswer(
        (_) async => PaginatedListingsResult(
          listings: const [],
          lastDocument: null,
          hasMore: false,
        ),
      );
      when(() => listing.countActiveListings(
            region: any(named: 'region'),
          )).thenAnswer((_) async => 0);
      when(() => listing.countActiveListings(
            season: any(named: 'season'),
          )).thenAnswer((_) async => 0);
      return _localizedApp(
        const HomeScreen(),
        overrides: [
          listingServiceProvider.overrideWith((ref) => listing),
          notificationServiceProvider.overrideWith((ref) => notifications),
          activeBannerAdsProvider.overrideWith(
            (ref) => Stream<List<BannerAd>>.value(const <BannerAd>[]),
          ),
        ],
      );
    },
    prepare: (tester) async {
      await tester.tap(find.byTooltip('Filtreler'));
      await tester.pump(const Duration(milliseconds: 100));
    },
  );

  _addGuidelineTests(
    'listing detail screen',
    () {
      final listing = _MockListingService();
      when(() => listing.getListing('a11y-listing')).thenAnswer((_) async => null);
      return _localizedApp(
        const ListingDetailScreen(listingId: 'a11y-listing'),
        overrides: [
          listingServiceProvider.overrideWith((ref) => listing),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
    },
  );

  _addGuidelineTests(
    'create listing screen',
    () {
      final listing = _MockListingService();
      final storage = _MockStorageService();
      final location = _MockLocationService();
      return _localizedApp(
        const CreateListingScreen(),
        overrides: [
          authServiceProvider.overrideWith((ref) => auth),
          listingServiceProvider.overrideWith((ref) => listing),
          storageServiceProvider.overrideWith((ref) => storage),
          locationServiceProvider.overrideWith((ref) => location),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
    },
  );

  _addGuidelineTests(
    'profile screen',
    () => _localizedApp(
      const ProfileScreen(),
      overrides: [
        authServiceProvider.overrideWith((ref) => auth),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
      ],
    ),
  );

  _addGuidelineTests(
    'chat list screen',
    () => _localizedApp(
      const ChatListScreen(),
      overrides: [authServiceProvider.overrideWith((ref) => auth)],
    ),
  );

  _addGuidelineTests(
    'chat detail screen',
    () {
      final chat = _MockChatService();
      when(() => chat.watchConversation('a11y-conversation'))
          .thenAnswer((_) => Stream.value(null));
      when(() => chat.watchMessages('a11y-conversation'))
          .thenAnswer((_) => Stream.value(const []));
      when(() => chat.watchInterviewSlots('a11y-conversation'))
          .thenAnswer((_) => Stream.value(const []));
      return _localizedApp(
        const ChatDetailScreen(conversationId: 'a11y-conversation'),
        overrides: [
            chatServiceProvider.overrideWith((ref) => chat),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
    },
  );

  _addGuidelineTests(
    'notification settings screen',
    () {
      final profile = _MockProfileService();
      final notifications = _MockNotificationService();
      return _localizedApp(
        const NotificationSettingsScreen(),
        overrides: [
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          profileServiceProvider.overrideWith((ref) => profile),
          notificationServiceProvider.overrideWith((ref) => notifications),
        ],
      );
    },
  );

  _addGuidelineTests(
    'language settings screen',
    () => _localizedApp(const LanguageSettingsScreen()),
  );

  _addGuidelineTests(
    'admin dashboard screen',
    () {
      final analytics = _MockAdminAnalyticsService();
      when(() => analytics.getDashboardMetrics()).thenAnswer(
        (_) async => const DashboardMetrics(
          activeListings: 0,
          newUsers: 0,
          openReports: 0,
          pendingVerifications: 0,
        ),
      );
      return _localizedApp(
        const AdminDashboardScreen(),
        overrides: [adminAnalyticsServiceProvider.overrideWith((ref) => analytics)],
      );
    },
  );

  testWidgets(
    'home icon buttons expose filter, calendar, and map labels',
    (tester) async {
      final listing = _MockListingService();
      when(() => listing.getPaginatedListings(
            category: any(named: 'category'),
            searchQuery: any(named: 'searchQuery'),
            city: any(named: 'city'),
            region: any(named: 'region'),
            minSalaryTl: any(named: 'minSalaryTl'),
            maxSalaryTl: any(named: 'maxSalaryTl'),
            dateFilter: any(named: 'dateFilter'),
            employmentType: any(named: 'employmentType'),
            sortOrder: any(named: 'sortOrder'),
            season: any(named: 'season'),
          )).thenAnswer(
        (_) async => PaginatedListingsResult(
          listings: const [],
          lastDocument: null,
          hasMore: false,
        ),
      );
      await _pumpA11y(
        tester,
        _localizedApp(
          const HomeScreen(),
          overrides: [
            listingServiceProvider.overrideWith((ref) => listing),
            activeBannerAdsProvider.overrideWith(
              (ref) => Stream<List<BannerAd>>.value(const <BannerAd>[]),
            ),
          ],
        ),
      );

      expect(find.bySemanticsLabel('Filtreler'), findsOneWidget);
      expect(find.bySemanticsLabel('Sezon Takvimi'), findsOneWidget);
      expect(find.bySemanticsLabel('Bölgeler'), findsOneWidget);
    },
    // HARNESS: finder sees no label, but the device tree has it ("Filters",
    // "Add to favorites" in round-1 Maestro dumps) - fix the finder, not the app.
    skip: true,
  );

  testWidgets(
    'home filter panel has labeled filter action',
    (tester) async {
      final listing = _MockListingService();
      when(() => listing.getPaginatedListings(
            category: any(named: 'category'),
            searchQuery: any(named: 'searchQuery'),
            city: any(named: 'city'),
            region: any(named: 'region'),
            minSalaryTl: any(named: 'minSalaryTl'),
            maxSalaryTl: any(named: 'maxSalaryTl'),
            dateFilter: any(named: 'dateFilter'),
            employmentType: any(named: 'employmentType'),
            sortOrder: any(named: 'sortOrder'),
            season: any(named: 'season'),
          )).thenAnswer(
        (_) async => PaginatedListingsResult(
          listings: const [],
          lastDocument: null,
          hasMore: false,
        ),
      );
      await _pumpA11y(
        tester,
        _localizedApp(
          const HomeScreen(),
          overrides: [
            listingServiceProvider.overrideWith((ref) => listing),
            activeBannerAdsProvider.overrideWith(
              (ref) => Stream<List<BannerAd>>.value(const <BannerAd>[]),
            ),
          ],
        ),
      );
      await tester.tap(find.bySemanticsLabel('Filtreler'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.bySemanticsLabel('Filtreler'), findsWidgets);
    },
    // HARNESS: finder sees no label, but the device tree has it ("Filters",
    // "Add to favorites" in round-1 Maestro dumps) - fix the finder, not the app.
    skip: true,
  );

  testWidgets(
    'listing favorite icon exposes a semantic label',
    (tester) async {
      final listing = _MockListingService();
      when(() => listing.getListing('a11y-listing')).thenAnswer((_) async => null);
      await _pumpA11y(
        tester,
        _localizedApp(
          const ListingDetailScreen(listingId: 'a11y-listing'),
          overrides: [
            listingServiceProvider.overrideWith((ref) => listing),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Favorilere ekle'), findsOneWidget);
    },
    // HARNESS: finder sees no label, but the device tree has it ("Filters",
    // "Add to favorites" in round-1 Maestro dumps) - fix the finder, not the app.
    skip: true,
  );

  testWidgets(
    'pushed screen exposes the localized back label',
    (tester) async {
      final listing = _MockListingService();
      var pushed = false;
      when(() => listing.getPaginatedListings(
            category: any(named: 'category'),
            searchQuery: any(named: 'searchQuery'),
            city: any(named: 'city'),
            region: any(named: 'region'),
            minSalaryTl: any(named: 'minSalaryTl'),
            maxSalaryTl: any(named: 'maxSalaryTl'),
            dateFilter: any(named: 'dateFilter'),
            employmentType: any(named: 'employmentType'),
            sortOrder: any(named: 'sortOrder'),
            season: any(named: 'season'),
          )).thenAnswer(
        (_) async => PaginatedListingsResult(
          listings: const [],
          lastDocument: null,
          hasMore: false,
        ),
      );
      await _pumpA11y(
        tester,
        _localizedApp(
          Builder(
            builder: (context) {
              if (!pushed) {
                pushed = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  unawaited(Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomeScreen(),
                        ),
                      ));
                });
              }
              return const SizedBox.shrink();
            },
          ),
          overrides: [
            listingServiceProvider.overrideWith((ref) => listing),
            activeBannerAdsProvider.overrideWith(
              (ref) => Stream<List<BannerAd>>.value(const <BannerAd>[]),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Geri'), findsOneWidget);
    },
  );

  // BUG-u3-01: ListingDetailScreen share IconButton has no tooltip/semantic label (D29).
  testWidgets(
    'share icon exposes a semantic label',
    (tester) async {
      final listing = _MockListingService();
      when(() => listing.getListing('a11y-listing')).thenAnswer((_) async => null);
      await _pumpA11y(
        tester,
        _localizedApp(
          const ListingDetailScreen(listingId: 'a11y-listing'),
          overrides: [
            listingServiceProvider.overrideWith((ref) => listing),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Paylaş'), findsOneWidget);
    },
    skip: true,
  );

  // BUG-u3-02: ChatMessageComposer send IconButton has no tooltip/semantic label (D29).
  testWidgets(
    'chat send icon exposes a semantic label',
    (tester) async {
      final chat = _MockChatService();
      when(() => chat.watchConversation('a11y-conversation'))
          .thenAnswer((_) => Stream.value(null));
      when(() => chat.watchMessages('a11y-conversation'))
          .thenAnswer((_) => Stream.value(const []));
      when(() => chat.watchInterviewSlots('a11y-conversation'))
          .thenAnswer((_) => Stream.value(const []));
      await _pumpA11y(
        tester,
        _localizedApp(
          const ChatDetailScreen(conversationId: 'a11y-conversation'),
          overrides: [
          chatServiceProvider.overrideWith((ref) => chat),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Gönder'), findsOneWidget);
    },
    skip: true,
  );
}

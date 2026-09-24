import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/admin/domain/admin_action_model.dart';
import 'package:otelcim/features/admin/presentation/listing_management_screen.dart';
import 'package:otelcim/features/admin/services/admin_service.dart';
import 'package:otelcim/features/admin/services/moderation_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(() {
    registerAdminFallbackValues();
  });

  group('ListingManagementScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockListingService mockListingService;
    late MockModerationService mockModerationService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockListingService = MockListingService();
      mockModerationService = MockModerationService();
      mockAdminService = MockAdminService();

      final adminUser = createDummyAdminUser(uid: 'admin_uid_1');
      when(() => mockAuthService.currentUser).thenReturn(adminUser);
      when(() => mockAdminService.logAdminAction(any())).thenAnswer((_) async => 'log_listing_1');
    });

    Widget buildListingManagementScreen({
      required Stream<List<Listing>> listingsStream,
      List<String>? navigatedRoutes,
    }) {
      when(() => mockListingService.watchRecentListingsForAdmin(limit: any(named: 'limit')))
          .thenAnswer((_) => listingsStream);

      final router = GoRouter(
        initialLocation: '/admin/listings',
        routes: [
          GoRoute(
            path: '/admin/listings',
            builder: (context, state) => const ListingManagementScreen(),
          ),
          GoRoute(
            path: '/listing/:id',
            builder: (context, state) {
              navigatedRoutes?.add('/listing/${state.pathParameters['id']}');
              return Scaffold(body: Text('Listing Detail ${state.pathParameters['id']}'));
            },
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          listingServiceProvider.overrideWith((ref) => mockListingService),
          moderationServiceProvider.overrideWith((ref) => mockModerationService),
          adminServiceProvider.overrideWith((ref) => mockAdminService),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('tr'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr', ''), Locale('en', '')],
        ),
      );
    }

    testWidgets('displays loading indicator while listings are loading', (tester) async {
      await configureTestScreenSize(tester);

      final controller = StreamController<List<Listing>>();
      addTearDown(controller.close);

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: controller.stream));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when watchRecentListingsForAdmin throws', (tester) async {
      await configureTestScreenSize(tester);

      final errorStream = Stream<List<Listing>>.error(Exception('Listings load failed'));

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: errorStream));
      await tester.pumpAndSettle();

      expect(find.text('İlanlar yüklenemedi.'), findsOneWidget);
    });

    testWidgets('displays empty state when no listings exist', (tester) async {
      await configureTestScreenSize(tester);

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.text('Henüz ilan yok.'), findsOneWidget);
    });

    testWidgets('renders listings with titles, category labels and status chips', (tester) async {
      await configureTestScreenSize(tester);

      final listings = [
        createDummyListing(
          id: 'list_active',
          title: 'Resepsiyonist Aranıyor',
          posterName: 'Grand Resort',
          category: 'resepsiyon',
          location: 'Antalya',
          status: ListingStatus.active,
        ),
        createDummyListing(
          id: 'list_removed',
          title: 'Garson Aranıyor',
          posterName: 'Beach Cafe',
          category: 'servis',
          location: 'İzmir',
          status: ListingStatus.removed,
        ),
      ];

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: Stream.value(listings)));
      await tester.pumpAndSettle();

      expect(find.text('Resepsiyonist Aranıyor'), findsOneWidget);
      expect(find.text('Aktif'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Kaldır'), findsOneWidget);

      expect(find.text('Garson Aranıyor'), findsOneWidget);
      expect(find.text('Kaldırıldı'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Geri Yükle'), findsOneWidget);
    });

    testWidgets('removes listing with reason dialog and logs action', (tester) async {
      await configureTestScreenSize(tester);

      final listing = createDummyListing(
        id: 'list_to_remove',
        title: 'Gece Müdürü',
        status: ListingStatus.active,
      );
      when(() => mockModerationService.removeListing(
            listingId: any(named: 'listingId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: Stream.value([listing])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır'));
      await tester.pumpAndSettle();

      expect(find.text('İlanı Kaldır'), findsOneWidget);
      expect(find.text('"Gece Müdürü" ilanı kaldırılacak.'), findsOneWidget);

      // Attempt to submit with empty reason (reason is required)
      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır'));
      await tester.pumpAndSettle();

      expect(find.text('Sebep girmeniz gerekiyor.'), findsOneWidget);

      // Enter reason and confirm
      await tester.enterText(find.byType(TextField).last, 'Kural dışı çalışma şartları');
      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.removeListing(
            listingId: 'list_to_remove',
            adminId: 'admin_uid_1',
            reason: 'Kural dışı çalışma şartları',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.removeListing)
                .having((a) => a.targetId, 'targetId', 'list_to_remove'),
          ))).called(1);

      expect(find.text('İlan kaldırıldı.'), findsOneWidget);
    });

    testWidgets('restores removed listing and logs restore action', (tester) async {
      await configureTestScreenSize(tester);

      final listing = createDummyListing(
        id: 'list_to_restore',
        title: 'Bulaşıkçı',
        status: ListingStatus.removed,
      );
      when(() => mockModerationService.restoreListing(
            listingId: any(named: 'listingId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: Stream.value([listing])));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Geri Yükle'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.restoreListing(
            listingId: 'list_to_restore',
            adminId: 'admin_uid_1',
          )).called(1);

      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType', AdminActionType.restoreListing)
                .having((a) => a.targetId, 'targetId', 'list_to_restore'),
          ))).called(1);

      expect(find.text('İlan geri yüklendi.'), findsOneWidget);
    });

    testWidgets('navigates to listing detail screen when clicking İlanı Aç', (tester) async {
      await configureTestScreenSize(tester);

      final navigatedRoutes = <String>[];
      final listing = createDummyListing(
        id: 'listing_detail_target_99',
        title: 'Barmen Aranıyor',
      );

      await tester.pumpWidget(
        buildListingManagementScreen(
          listingsStream: Stream.value([listing]),
          navigatedRoutes: navigatedRoutes,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'İlanı Aç'));
      await tester.pumpAndSettle();

      expect(navigatedRoutes, contains('/listing/listing_detail_target_99'));
      expect(find.text('Listing Detail listing_detail_target_99'), findsOneWidget);
    });

    testWidgets('searches listings by title and handles empty search results', (tester) async {
      await configureTestScreenSize(tester);

      final searchResults = [
        createDummyListing(
          id: 'search_l1',
          title: 'Aşçı Yardımcısı',
        ),
      ];

      when(() => mockListingService.searchListingsForAdmin('Aşçı'))
          .thenAnswer((_) async => searchResults);
      when(() => mockListingService.searchListingsForAdmin('Bulunamadı'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(buildListingManagementScreen(listingsStream: Stream.value([])));
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(TextField, 'İlan başlığıyla ara');
      await tester.enterText(searchField, 'Aşçı');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Aşçı Yardımcısı'), findsOneWidget);

      // Search non-existent
      await tester.enterText(searchField, 'Bulunamadı');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Sonuç bulunamadı.'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Henüz ilan yok.'), findsOneWidget);
    });
  });
}

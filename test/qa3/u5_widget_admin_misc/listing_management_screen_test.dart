import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
import 'package:otelcim/shared/providers/firestore_provider.dart';
import 'package:otelcim/shared/services/auth_service.dart';

import 'admin_test_helper.dart';

void main() {
  setUpAll(registerAdminFallbackValues);

  group('ListingManagementScreen Widget Tests', () {
    late MockAuthService mockAuthService;
    late MockModerationService mockModerationService;
    late MockAdminService mockAdminService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockModerationService = MockModerationService();
      mockAdminService = MockAdminService();

      when(() => mockAuthService.currentUser)
          .thenReturn(createDummyAdminUser(uid: 'admin_uid_1'));
      when(() => mockAdminService.logAdminAction(any()))
          .thenAnswer((_) async => 'log_listing_1');
    });

    Future<void> configureWideScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    Future<void> seedListing(
      FakeFirebaseFirestore db,
      Listing listing, {
      DateTime? createdAt,
    }) {
      final data = listing.toMap();
      data['createdAt'] = Timestamp.fromDate(
        createdAt ?? listing.createdAt ?? DateTime(2026, 6, 1),
      );
      data['updatedAt'] = data['createdAt'];
      return db.collection('listings').doc(listing.id).set(data);
    }

    Widget buildListingManagementScreen(FirebaseFirestore db) {
      final router = GoRouter(
        initialLocation: '/admin/listings',
        routes: [
          GoRoute(
            path: '/admin/listings',
            builder: (context, state) => const ListingManagementScreen(),
          ),
          GoRoute(
            path: '/listing/:id',
            builder: (context, state) => Scaffold(
              body: Text('Listing Detail ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          firestoreProvider.overrideWithValue(db),
          moderationServiceProvider
              .overrideWith((ref) => mockModerationService),
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

    testWidgets('displays loading indicator while the first page loads',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();

      await tester.pumpWidget(buildListingManagementScreen(db));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays the current paged empty state', (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Bu filtreyle ilan bulunamadı.'), findsOneWidget);
    });

    testWidgets('renders the filter tabs and paged listing table',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'list_active',
          title: 'Resepsiyonist Aranıyor',
          posterName: 'Grand Resort',
          location: 'Antalya',
          status: ListingStatus.active,
        ),
        createdAt: DateTime(2026, 6, 2),
      );
      await seedListing(
        db,
        createDummyListing(
          id: 'list_removed',
          title: 'Garson Aranıyor',
          posterName: 'Beach Cafe',
          location: 'İzmir',
          status: ListingStatus.removed,
        ),
        createdAt: DateTime(2026, 6, 1),
      );

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();

      expect(find.text('Aktif'), findsNWidgets(2));
      expect(find.text('Kapalı'), findsOneWidget);
      expect(find.text('Kaldırılmış'), findsNWidgets(2));
      expect(find.text('Acil'), findsOneWidget);
      expect(find.text('Öne çıkan'), findsOneWidget);
      expect(find.text('Başlık'), findsOneWidget);
      expect(find.text('İşveren'), findsOneWidget);
      expect(find.text('Konum'), findsOneWidget);
      expect(find.text('Durum'), findsOneWidget);
      expect(find.text('Resepsiyonist Aranıyor'), findsOneWidget);
      expect(find.text('Grand Resort'), findsOneWidget);
      expect(find.text('Garson Aranıyor'), findsOneWidget);
      expect(find.text('2 kayıt'), findsOneWidget);
    });

    testWidgets('switches listing filter tabs before loading the next page',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'active_listing',
          title: 'Aktif İlan',
          status: ListingStatus.active,
        ),
      );
      await seedListing(
        db,
        createDummyListing(
          id: 'closed_listing',
          title: 'Kapalı İlan',
          status: ListingStatus.closed,
        ),
      );

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();

      // The screen starts on the unfiltered "Tümü" tab. Select the active
      // query before asserting the first page, then switch to the closed
      // query to verify that the old page is replaced.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Aktif'));
      await tester.pumpAndSettle();
      expect(find.text('Aktif İlan'), findsOneWidget);
      expect(find.text('Kapalı İlan'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Kapalı'));
      await tester.pumpAndSettle();

      expect(find.text('Kapalı İlan'), findsOneWidget);
      expect(find.text('Aktif İlan'), findsNothing);
    });

    testWidgets('removes listing from the row action card and logs action',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'list_to_remove',
          title: 'Gece Müdürü',
          status: ListingStatus.active,
        ),
      );
      when(() => mockModerationService.removeListing(
            listingId: any(named: 'listingId'),
            adminId: any(named: 'adminId'),
            reason: any(named: 'reason'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gece Müdürü'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır').last);
      await tester.pumpAndSettle();

      expect(find.text('İlanı Kaldır'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır').last);
      await tester.pumpAndSettle();
      expect(find.text('Sebep girmeniz gerekiyor.'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField).last,
        'Kural dışı çalışma şartları',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Kaldır').last);
      await tester.pumpAndSettle();

      verify(() => mockModerationService.removeListing(
            listingId: 'list_to_remove',
            adminId: 'admin_uid_1',
            reason: 'Kural dışı çalışma şartları',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.removeListing)
                .having((a) => a.targetId, 'targetId', 'list_to_remove'),
          ))).called(1);
      expect(find.text('İlan kaldırıldı.'), findsOneWidget);
    });

    testWidgets('restores a removed listing and logs the restore action',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'list_to_restore',
          title: 'Bulaşıkçı',
          status: ListingStatus.removed,
        ),
      );
      when(() => mockModerationService.restoreListing(
            listingId: any(named: 'listingId'),
            adminId: any(named: 'adminId'),
          )).thenAnswer((_) async {});

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bulaşıkçı'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Geri Yükle'));
      await tester.pumpAndSettle();

      verify(() => mockModerationService.restoreListing(
            listingId: 'list_to_restore',
            adminId: 'admin_uid_1',
          )).called(1);
      verify(() => mockAdminService.logAdminAction(any(
            that: isA<AdminAction>()
                .having((a) => a.actionType, 'actionType',
                    AdminActionType.restoreListing)
                .having((a) => a.targetId, 'targetId', 'list_to_restore'),
          ))).called(1);
      expect(find.text('İlan geri yüklendi.'), findsOneWidget);
    });

    testWidgets('opens listing detail from the current row action card',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'listing_detail_target_99',
          title: 'Barmen Aranıyor',
        ),
      );

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barmen Aranıyor'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'İlanı Aç'));
      await tester.pumpAndSettle();

      expect(find.text('Listing Detail listing_detail_target_99'), findsOneWidget);
    });

    testWidgets('searches the paged query and handles empty results',
        (tester) async {
      await configureWideScreen(tester);

      final db = FakeFirebaseFirestore();
      await seedListing(
        db,
        createDummyListing(
          id: 'search_l1',
          title: 'Aşçı Yardımcısı',
        ),
      );
      await seedListing(
        db,
        createDummyListing(
          id: 'other_l1',
          title: 'Resepsiyonist',
        ),
      );

      await tester.pumpWidget(buildListingManagementScreen(db));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Aşçı');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Aşçı Yardımcısı'), findsOneWidget);
      expect(find.text('Resepsiyonist'), findsNothing);

      await tester.enterText(searchField, 'Bulunamadı');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('Bu filtreyle ilan bulunamadı.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Aşçı Yardımcısı'), findsOneWidget);
      expect(find.text('Resepsiyonist'), findsOneWidget);
    });
  });
}

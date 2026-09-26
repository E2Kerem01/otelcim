import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/favorites/services/favorite_service.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/widgets/listing_preview_pane.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

void main() {
  const testListing = Listing(
    id: 'listing-123',
    posterId: 'employer-456',
    posterName: 'Antalya Resort Hotel',
    title: 'Resepsiyon Görevlisi',
    description:
        '5 yıldızlı otelimizde görevlendirilmek üzere tecrübeli resepsiyonist arıyoruz.',
    category: 'resepsiyon',
    location: 'Antalya, Muratpaşa',
    salary: '32.000 TL',
    contactInfo: '05551234567',
    status: ListingStatus.active,
  );

  Widget buildTestHarness({
    required String listingId,
    VoidCallback? onClose,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListingPreviewPane(
            listingId: listingId,
            onClose: onClose,
          ),
        ),
      ),
    );
  }

  group('ListingPreviewPane', () {
    testWidgets('displays loading indicator when listing is loading', (
      tester,
    ) async {
      final completer = Completer<Listing?>();

      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-123',
          overrides: [
            singleListingProvider('listing-123').overrideWith(
              (ref) => completer.future,
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );

      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'displays title and open full page button when listing is loaded',
      (tester) async {
        await tester.pumpWidget(
          buildTestHarness(
            listingId: 'listing-123',
            overrides: [
              singleListingProvider('listing-123').overrideWith(
                (ref) => Future.value(testListing),
              ),
              authStateProvider.overrideWith((ref) => Stream.value(null)),
            ],
          ),
        );

        await tester.pumpAndSettle();

        // Listing title is visible
        expect(find.text('Resepsiyon Görevlisi'), findsWidgets);
        // Company name is visible
        expect(find.text('Antalya Resort Hotel'), findsWidgets);
        // "Open full page" button is present
        expect(
          find.byKey(const Key('listing_preview_open_full_page_button')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      },
    );

    testWidgets('displays not-found state when listing does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-missing',
          overrides: [
            singleListingProvider('listing-missing').overrideWith(
              (ref) => Future.value(null),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('İlan bulunamadı'), findsWidgets);
    });

    testWidgets('calls onClose callback when close button is tapped', (
      tester,
    ) async {
      var closed = false;

      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-123',
          onClose: () => closed = true,
          overrides: [
            singleListingProvider('listing-123').overrideWith(
              (ref) => Future.value(testListing),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final closeButton = find.byKey(const Key('listing_preview_close_button'));
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      expect(closed, isTrue);
    });

    testWidgets('shows prompt to log in when user is unauthenticated', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-123',
          overrides: [
            singleListingProvider('listing-123').overrideWith(
              (ref) => Future.value(testListing),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('İletişime geçmek için giriş yapın'), findsOneWidget);
    });

    testWidgets('shows edit listing action for listing owner', (tester) async {
      const owner = AppUser(uid: 'employer-456', email: 'owner@example.com');

      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-123',
          overrides: [
            singleListingProvider('listing-123').overrideWith(
              (ref) => Future.value(testListing),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(owner)),
            favoriteIdsProvider('employer-456').overrideWith(
              (ref) => Stream.value({}),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('İlanı Düzenle'), findsOneWidget);
    });

    testWidgets('shows message action for job seeker user', (tester) async {
      const seeker = AppUser(uid: 'seeker-789', email: 'seeker@example.com');

      await tester.pumpWidget(
        buildTestHarness(
          listingId: 'listing-123',
          overrides: [
            singleListingProvider('listing-123').overrideWith(
              (ref) => Future.value(testListing),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(seeker)),
            favoriteIdsProvider('seeker-789').overrideWith(
              (ref) => Stream.value({}),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mesaj Gönder'), findsOneWidget);
    });
  });
}

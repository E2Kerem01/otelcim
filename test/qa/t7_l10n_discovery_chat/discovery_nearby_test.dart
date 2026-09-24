import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:otelcim/features/categories/presentation/categories_screen.dart';
import 'package:otelcim/features/discovery/domain/tourism_region.dart';
import 'package:otelcim/features/discovery/presentation/regions_screen.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/nearby/domain/nearby_listing.dart';
import 'package:otelcim/features/nearby/services/location_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/constants/categories.dart';

void main() {
  group('Discovery & Nearby Unit & Widget Tests', () {
    test('tourismRegions contains exactly 10 defined regions with valid coordinates', () {
      expect(tourismRegions.length, equals(10));

      for (final region in tourismRegions) {
        expect(region.id, isNotEmpty);
        expect(region.nameTr, isNotEmpty);
        expect(region.nameEn, isNotEmpty);
        expect(region.latitude, inInclusiveRange(-90.0, 90.0));
        expect(region.longitude, inInclusiveRange(-180.0, 180.0));
      }
    });

    test('tourismRegionById lookup returns correct region or null', () {
      expect(tourismRegionById('antalya')?.nameTr, equals('Antalya'));
      expect(tourismRegionById('bodrum')?.nameEn, equals('Bodrum'));
      expect(tourismRegionById('kapadokya')?.nameEn, equals('Cappadocia'));
      expect(tourismRegionById('nonexistent_id'), isNull);
      expect(tourismRegionById(null), isNull);
    });

    test('calculateDistanceKm Haversine formula calculation', () {
      // 1. Same point should be exactly 0 km
      final zeroDist = calculateDistanceKm(
        fromLat: 36.8969,
        fromLng: 30.7133,
        toLat: 36.8969,
        toLng: 30.7133,
      );
      expect(zeroDist, equals(0.0));

      // 2. Antalya to Bodrum is approximately 292 km
      final antalyaToBodrum = calculateDistanceKm(
        fromLat: 36.8969,
        fromLng: 30.7133,
        toLat: 37.0344,
        toLng: 27.4305,
      );
      expect(antalyaToBodrum, closeTo(292.0, 5.0));

      // 3. One degree of longitude at the equator is ~111.2 km
      final equatorDeg = calculateDistanceKm(
        fromLat: 0.0,
        fromLng: 0.0,
        toLat: 0.0,
        toLng: 1.0,
      );
      expect(equatorDeg, closeTo(111.2, 1.0));

      // 4. Antipodal points (opposite sides of Earth) is ~20015 km
      final antipodalDist = calculateDistanceKm(
        fromLat: 0.0,
        fromLng: 0.0,
        toLat: 0.0,
        toLng: 180.0,
      );
      expect(antipodalDist, closeTo(20015.0, 50.0));
    });

    test('nearbyListings filters by radius and sorts by distance', () {
      final listingNear = Listing(
        id: 'l_near',
        posterId: 'p1',
        posterName: 'Otel 1',
        title: 'Antalya İlan',
        description: 'Yakın ilan',
        category: 'resepsiyon',
        location: 'Antalya',
        salary: '30000 TL',
        contactInfo: 'otel1@hotel.com',
        lat: 36.9000,
        lng: 30.7150, // ~0.4 km from user
      );

      final listingFar = Listing(
        id: 'l_far',
        posterId: 'p2',
        posterName: 'Otel 2',
        title: 'Bodrum İlan',
        description: 'Uzak ilan',
        category: 'servis',
        location: 'Bodrum',
        salary: '30000 TL',
        contactInfo: 'otel2@hotel.com',
        lat: 37.0344,
        lng: 27.4305, // ~292 km from user
      );

      final listingNoCoords = Listing(
        id: 'l_no_coords',
        posterId: 'p3',
        posterName: 'Otel 3',
        title: 'Koordinatsız İlan',
        description: 'Konumu yok',
        category: 'mutfak',
        location: 'Bilinmiyor',
        salary: '30000 TL',
        contactInfo: 'otel3@hotel.com',
        lat: null,
        lng: null,
      );

      final List<Listing> allListings = [listingFar, listingNoCoords, listingNear];

      // Query with 50 km radius centered at Antalya
      final results50Km = nearbyListings(
        listings: allListings,
        userLat: 36.8969,
        userLng: 30.7133,
        radiusKm: 50.0,
      );

      expect(results50Km.length, equals(1));
      expect(results50Km.first.listing.id, equals('l_near'));
      expect(results50Km.first.distanceKm, lessThan(1.0));

      // Query with 500 km radius: should return both near and far, but omit listingNoCoords
      final results500Km = nearbyListings(
        listings: allListings,
        userLat: 36.8969,
        userLng: 30.7133,
        radiusKm: 500.0,
      );

      expect(results500Km.length, equals(2));
      // Must be sorted ascending by distance
      expect(results500Km[0].listing.id, equals('l_near'));
      expect(results500Km[1].listing.id, equals('l_far'));
    });

    test('LocationService LocationResult models failure and success', () {
      const failure = LocationResult.failure(LocationFailure.denied);
      expect(failure.failure, equals(LocationFailure.denied));
      expect(failure.position, isNull);

      const servicesDisabled = LocationResult.failure(LocationFailure.servicesDisabled);
      expect(servicesDisabled.failure, equals(LocationFailure.servicesDisabled));

      const deniedForever = LocationResult.failure(LocationFailure.deniedForever);
      expect(deniedForever.failure, equals(LocationFailure.deniedForever));
    });

    testWidgets('RegionsScreen renders all 10 regions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRegionListingsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: RegionsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Antalya'), findsOneWidget);
      expect(find.text('Bodrum'), findsOneWidget);
      expect(find.text('Kapadokya'), findsOneWidget);
      expect(find.text('0 aktif ilan'), findsWidgets);
    });

    testWidgets(
      'RegionsScreen provides localized region names for all supported languages (not only Turkish/English)',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activeRegionListingsProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: const MaterialApp(
              locale: Locale('de'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: RegionsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Currently: `isEnglish ? region.nameEn : region.nameTr`
        // In German, Russian, and Arabic, it falls back to Turkish `nameTr`!
        // Cappadocia in German should not display Turkish 'Kapadokya'.
        expect(find.text('Kapadokya'), findsNothing);
      },
      skip: true, // BUG-t7-13: RegionsScreen only checks for English locale and falls back to Turkish for Russian, German, and Arabic (regions_screen.dart:21,50)
    );

    testWidgets('CategoriesScreen renders all categories and tapping updates provider', (tester) async {
      ListingCategory? selectedCategory;

      // CategoriesScreen calls context.go('/') on tap, so it needs a GoRouter
      // ancestor; a plain MaterialApp(home:) throws "No GoRouter found".
      final router = GoRouter(
        initialLocation: '/categories',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('home-stub')),
          ),
          GoRoute(
            path: '/categories',
            builder: (context, state) => const CategoriesScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              selectedCategory = ref.watch(selectedCategoryFilterProvider);
              return MaterialApp.router(
                locale: const Locale('tr'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Resepsiyon'), findsOneWidget);
      expect(find.text('Kat Hizmetleri'), findsOneWidget);
      expect(find.text('Mutfak / Aşçı'), findsOneWidget);

      // Tap Resepsiyon
      await tester.tap(find.text('Resepsiyon'));
      await tester.pumpAndSettle();

      expect(selectedCategory, equals(ListingCategory.resepsiyon));
      // Tapping a category navigates back to the home feed.
      expect(find.text('home-stub'), findsOneWidget);
    });
  });
}

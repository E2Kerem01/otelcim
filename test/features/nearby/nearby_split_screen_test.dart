import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/nearby/presentation/nearby_listings_screen.dart';
import 'package:otelcim/features/nearby/services/location_service.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/listing_service.dart';

class MockLocationService extends LocationService {
  MockLocationService(this.result);
  final LocationResult result;

  @override
  Future<LocationResult> currentPosition() async => result;
}

class MockListingService extends Fake implements ListingService {
  MockListingService(this.listings);
  final List<Listing> listings;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #watchActiveListings) {
      return Stream.value(listings);
    }
    return super.noSuchMethod(invocation);
  }
}

Listing createNearbyListing(String id, double lat, double lng) {
  return Listing(
    id: id,
    posterId: 'user1',
    posterName: 'Hotel 1',
    title: 'Otel $id',
    description: 'Açıklama',
    category: 'resepsiyon',
    location: 'Lara',
    salary: '35000 TL',
    lat: lat,
    lng: lng,
    contactInfo: '05555555555',
  );
}

void main() {
  testWidgets(
    'NearbyListingsScreen renders split screen mode with map and list hover',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final position = Position(
        longitude: 30.7133,
        latitude: 36.8969,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      final mockLocationService = MockLocationService(
        LocationResult.success(position),
      );
      final mockListingService = MockListingService([
        createNearbyListing('1', 36.90, 30.72),
        createNearbyListing('2', 36.91, 30.73),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(mockLocationService),
            listingServiceProvider.overrideWithValue(mockListingService),
          ],
          child: const MaterialApp(
            locale: Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NearbyListingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Location consent dialog appears
      expect(find.text('Konum izni'), findsOneWidget);
      final continueBtn = find.text('Devam Et');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Screen title & list items
      expect(find.text('Yakındaki İlanlar'), findsOneWidget);
      expect(find.text('Otel 1'), findsWidgets);
      expect(find.text('Otel 2'), findsWidgets);
      expect(find.byType(SegmentedButton<NearbyViewMode>), findsOneWidget);

      // View mode toggles
      final listBtn = find.byIcon(Icons.view_list_rounded).first;
      await tester.tap(listBtn);
      await tester.pump();
      await tester.pump();

      final mapBtn = find.byIcon(Icons.map_rounded).first;
      await tester.tap(mapBtn);
      await tester.pump();
      await tester.pump();

      final splitBtn = find.byIcon(Icons.vertical_split_rounded).first;
      await tester.tap(splitBtn);
      await tester.pump();
      await tester.pump();

      // Mouse hover on list item
      final otelCard = find.text('Otel 1').first;
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(otelCard));
      await tester.pump();
      await tester.pump();
      await gesture.removePointer();
      await tester.pump();
      await tester.pump();
    },
  );
}

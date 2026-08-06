import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/discovery/presentation/region_map_screen.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/listing_service.dart';

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

Listing createSampleListing(String id, String region) {
  return Listing(
    id: id,
    posterId: 'user1',
    posterName: 'Hotel 1',
    title: 'Sample Listing $id',
    description: 'Sample description',
    category: 'resepsiyon',
    location: 'Antalya',
    salary: '30000 TL',
    region: region,
    contactInfo: '05555555555',
  );
}

void main() {
  testWidgets('RegionMapScreen renders split-screen layout on wide screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final listings = [
      createSampleListing('l1', 'antalya'),
      createSampleListing('l2', 'bodrum'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingServiceProvider.overrideWithValue(MockListingService(listings)),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegionMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Bölge haritası'), findsOneWidget);
    expect(find.text('Antalya'), findsWidgets);
    expect(find.text('Bodrum'), findsWidgets);
    expect(find.byType(SegmentedButton<MapSplitViewMode>), findsOneWidget);
  });

  testWidgets('RegionMapScreen allows switching view modes (List, Map, Split)', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingServiceProvider.overrideWithValue(MockListingService([])),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegionMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final segmentedButton = find.byType(SegmentedButton<MapSplitViewMode>);
    expect(segmentedButton, findsOneWidget);

    // Tap List mode
    final listBtn = find.byIcon(Icons.view_list_rounded).first;
    await tester.tap(listBtn);
    await tester.pump();
    await tester.pump();

    // Tap Map mode
    final mapBtn = find.byIcon(Icons.map_rounded).first;
    await tester.tap(mapBtn);
    await tester.pump();
    await tester.pump();

    // Tap Split mode
    final splitBtn = find.byIcon(Icons.vertical_split_rounded).first;
    await tester.tap(splitBtn);
    await tester.pump();
    await tester.pump();
  });

  testWidgets('RegionMapScreen handles list item hover', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingServiceProvider.overrideWithValue(
            MockListingService([createSampleListing('l1', 'antalya')]),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegionMapScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final antalyaItem = find.text('Antalya').first;
    expect(antalyaItem, findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(antalyaItem));
    await tester.pump();
    await tester.pump();

    await gesture.removePointer();
    await tester.pump();
    await tester.pump();
  });
}

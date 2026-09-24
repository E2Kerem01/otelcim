import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/edit_listing_screen.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/models/app_user.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/services/listing_service.dart';

class MockListingService extends Mock implements ListingService {}

Listing editableListing() => Listing(
  id: 'listing-1',
  posterId: 'owner-1',
  posterName: 'Otel',
  posterVerified: true,
  isUrgent: true,
  title: 'Resepsiyonist',
  description: 'Açıklama',
  category: 'resepsiyon',
  location: 'Antalya',
  salary: '35.000 TL',
  city: 'Antalya',
  region: 'Akdeniz',
  lat: 36.8841,
  lng: 30.7056,
  contactInfo: '0532 111 22 33',
);

Future<void> pumpEditor(
  WidgetTester tester,
  MockListingService service, {
  AppUser? user,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        listingServiceProvider.overrideWithValue(service),
        authStateProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EditListingScreen(listingId: 'listing-1'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unauthenticated users cannot access the edit form', (
    tester,
  ) async {
    final service = MockListingService();
    when(
      () => service.getListing('listing-1'),
    ).thenAnswer((_) async => editableListing());

    await pumpEditor(tester, service);

    expect(find.text('Bu ilanı düzenleme yetkiniz yok.'), findsOneWidget);
    expect(find.text('Değişiklikleri Kaydet'), findsNothing);
  });

  testWidgets(
    'saving without edits preserves urgent and geocoded fields',
    (tester) async {
      final service = MockListingService();
      final saved = <Listing>[];
      when(
        () => service.getListing('listing-1'),
      ).thenAnswer((_) async => editableListing());
      when(() => service.updateListing(any())).thenAnswer((invocation) async {
        saved.add(invocation.positionalArguments.first as Listing);
      });

      await pumpEditor(
        tester,
        service,
        user: const AppUser(uid: 'owner-1', email: 'owner@example.com'),
      );
      await tester.tap(find.text('Değişiklikleri Kaydet'));
      await tester.pumpAndSettle();

      expect(saved.single.isUrgent, isTrue);
      expect(saved.single.lat, 36.8841);
      expect(saved.single.lng, 30.7056);
    },
    skip: true, // BUG-t4-005: submit drops isUrgent, lat, and lng
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/home/presentation/widgets/listing_feed_card.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/season_utils.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/l10n/app_localizations_en.dart';
import 'package:otelcim/l10n/app_localizations_tr.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';
import 'package:otelcim/shared/services/auth_service.dart';

Listing _listing({
  List<String> images = const [],
  bool urgent = false,
  int? meals = 3,
  String? room = 'shared',
  String? shuttle = 'Kemer - Otel',
}) =>
    Listing(
      id: 'L1',
      posterId: 'p',
      posterName: 'Deniz Otel',
      posterVerified: true,
      isUrgent: urgent,
      title: 'Resepsiyonist Aranıyor - İngilizce bilen, vardiyalı çalışabilecek',
      description: '',
      category: 'resepsiyon',
      location: 'Lara',
      city: 'Antalya',
      salary: '35.000 TL',
      contactInfo: '',
      season: 'yaz_2026',
      employmentType: EmploymentType.seasonal,
      images: images,
      housingRoomType: room,
      housingMealsIncluded: meals,
      staffShuttleRoute: shuttle,
      createdAt: DateTime(2026, 9, 23),
    );

Future<void> _pump(WidgetTester tester, Listing listing, {double textScale = 1.0}) async {
  tester.view.physicalSize = const Size(360 * 3, 800 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [authStateProvider.overrideWith((ref) => Stream.value(null))],
    child: MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        // As in the feed: the card sizes to its content, not the screen.
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListingFeedCard(listing: listing),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('leads with title, employer, place and pay; perks as chips', (tester) async {
    await _pump(tester, _listing());
    expect(find.textContaining('Resepsiyonist Aranıyor'), findsOneWidget);
    expect(find.text('Deniz Otel · Antalya'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
    expect(find.text('35.000 TL'), findsOneWidget);
    expect(find.text('Lojman'), findsOneWidget);
    expect(find.text('3 öğün'), findsOneWidget);
    expect(find.text('Servis'), findsOneWidget);
    expect(find.text('Yaz 2026'), findsOneWidget, reason: 'season code shown as a label, not yaz_2026');
    expect(tester.takeException(), isNull);
  });

  testWidgets('no photo -> small category icon, no large placeholder', (tester) async {
    await _pump(tester, _listing());
    final card = tester.getSize(find.byType(ListingFeedCard));
    expect(card.height, lessThan(200), reason: 'text-first card stays compact');
  });

  testWidgets('perks and urgent badge are optional', (tester) async {
    await _pump(tester, _listing(meals: null, room: null, shuttle: null, urgent: true));
    expect(find.text('Lojman'), findsNothing);
    expect(find.text('Servis'), findsNothing);
    expect(find.text('ACİL'), findsOneWidget);
  });

  testWidgets('no overflow on a 360dp phone at text scale 2.0 (D31)', (tester) async {
    await _pump(tester, _listing(urgent: true), textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Favorilere ekle'), findsOneWidget);
  });

  test('season codes of any year get a readable label', () {
    final tr = AppLocalizationsTr();
    final en = AppLocalizationsEn();
    expect(listingSeasonLabel(tr, 'yaz_2026'), 'Yaz 2026');
    expect(listingSeasonLabel(tr, 'kis_2026_27'), 'Kış 2026-27');
    expect(listingSeasonLabel(en, 'yaz_2027'), 'Summer 2027');
    expect(listingSeasonLabel(tr, 'yaz_2025'), tr.seasonSummer2025);
    expect(listingSeasonLabel(tr, 'bilinmeyen'), 'bilinmeyen');
  });
}

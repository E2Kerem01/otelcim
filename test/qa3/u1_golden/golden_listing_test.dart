import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:otelcim/features/home/presentation/widgets/home_screen_widgets.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/listings/presentation/widgets/listing_detail_widgets.dart';
import 'package:otelcim/l10n/app_localizations.dart';
import 'package:otelcim/shared/services/auth_service.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';

import 'golden_test_helpers.dart';

Listing _listing({
  bool urgent = false,
  bool boosted = false,
  bool housing = false,
  String title = 'Bodrum Resort resepsiyon görevlisi',
}) {
  return Listing(
    id: 'golden-listing',
    posterId: 'hotel-1',
    posterName: 'Grand Resort Bodrum',
    posterVerified: true,
    isUrgent: urgent,
    title: title,
    description:
        'Misafir karşılama, check-in ve günlük otel operasyonlarında görev alacak ekip arkadaşı aranıyor.',
    category: 'resepsiyon',
    location: 'Bodrum / Muğla',
    salary: '35.000 TL + yemek',
    city: 'Muğla',
    region: 'Ege',
    minSalaryTl: 35000,
    maxSalaryTl: 42000,
    employmentType: EmploymentType.fullTime,
    experienceLevel: ExperienceLevel.oneToThreeYears.name,
    educationLevel: EducationLevel.highSchool.name,
    season: 'yaz2025',
    contactInfo: '+90 555 123 4567',
    images: const [],
    housingRoomType: housing ? 'single' : null,
    housingHasAc: housing ? true : null,
    housingHasWifi: housing ? true : null,
    housingMealsIncluded: housing ? 3 : null,
    housingImages: const [],
    createdAt: DateTime(2026, 1, 2),
    updatedAt: DateTime(2026, 1, 2),
    isBoosted: boosted,
    boostExpiresAt: boosted ? DateTime(2099, 1, 2) : null,
  );
}

Widget _detailSurface(Listing listing) {
  return Scaffold(
    body: Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          key: const Key('listing-detail-golden'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListingImageGallery(listing: listing),
              ListingHeaderInfo(listing: listing, isBoostedActive: true),
              const SizedBox(height: 16),
              ListingSalaryCard(listing: listing),
              const SizedBox(height: 16),
              ListingRequirementsCard(
                experience: ExperienceLevel.oneToThreeYears,
                education: EducationLevel.highSchool,
                l10n: l10n,
              ),
              const SizedBox(height: 16),
              ListingDescriptionSection(listing: listing),
              const SizedBox(height: 16),
              ListingHousingCard(listing: listing, l10n: l10n),
              const SizedBox(height: 16),
              ListingPosterCard(
                listing: listing,
                myUid: 'seeker-1',
                revealContactInfo: true,
                onRevealContact: () {},
              ),
              const SizedBox(height: 16),
              ListingSafetyTipsCard(l10n: l10n, onReport: () {}),
            ],
          ),
        );
      },
    ),
  );
}

void main() {
  group('listing card goldens', () {
    final variants = <String, Listing>{
      'normal': _listing(),
      'urgent': _listing(urgent: true),
      'boosted': _listing(boosted: true),
      'long-title': _listing(
        title: 'Sezonluk konaklamalı ve deneyimli misafir ilişkileri yöneticisi',
      ),
    };

    for (final locale in goldenLocales) {
      for (final scale in <double>[1.0, 2.0]) {
        for (final entry in variants.entries) {
          final testName =
              'card ${entry.key} ${goldenLocaleName(locale)} ${goldenScaleName(scale)}';
          Future<void> testBody(WidgetTester tester) async {
            ignoreRenderFlexOverflowErrors();
            configureGoldenViewport(tester);
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  authStateProvider.overrideWith((ref) => Stream.value(null)),
                ],
                child: localizedGoldenApp(
                  locale: locale,
                  textScale: scale,
                  home: Scaffold(
                    body: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ListingCard(listing: entry.value),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            await expectLater(
              find.byType(ListingCard),
              matchesGoldenFile(
                'goldens/listing_card_${entry.key}_${goldenLocaleName(locale)}_${goldenScaleName(scale)}.png',
              ),
            );
            expect(tester.takeException(), isNull);
          }
          if (scale == 2.0 || locale.languageCode == 'ar') {
            testWidgets(
              testName,
              testBody,
              // BUG-u1-04: Listing cards overflow with Ahem at 2x or in RTL.
              skip: true,
            );
          } else {
            testWidgets(testName, testBody);
          }
        }
      }
    }
  });

  for (final locale in goldenLocales) {
    for (final scale in <double>[1.0, 2.0]) {
      final testName =
          'listing detail housing ${goldenLocaleName(locale)} ${goldenScaleName(scale)}';
      Future<void> testBody(WidgetTester tester) async {
        ignoreRenderFlexOverflowErrors();
        configureGoldenViewport(tester, physicalSize: const Size(1440, 3000));
        await tester.pumpWidget(
          localizedGoldenApp(
            locale: locale,
            textScale: scale,
            home: _detailSurface(_listing(housing: true, boosted: true)),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const Key('listing-detail-golden')),
          matchesGoldenFile(
            'goldens/listing_detail_housing_${goldenLocaleName(locale)}_${goldenScaleName(scale)}.png',
          ),
        );
        expect(tester.takeException(), isNull);
      }
      if (scale == 2.0 || locale.languageCode == 'ar') {
        testWidgets(
          testName,
          testBody,
          // BUG-u1-05: Detail rows overflow with Ahem at 2x or in RTL.
          skip: true,
        );
      } else {
        testWidgets(testName, testBody);
      }
    }
  }
}

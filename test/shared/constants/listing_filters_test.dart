import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/constants/listing_filters.dart';

void main() {
  group('ListingDateFilter', () {
    test('cutoff returns expected DateTime for each enum value', () {
      final now = DateTime.now();

      expect(ListingDateFilter.all.cutoff, isNull);

      final last24HoursCutoff = ListingDateFilter.last24Hours.cutoff!;
      final diff24Hours = now.difference(last24HoursCutoff).inHours;
      expect(diff24Hours, greaterThanOrEqualTo(23));
      expect(diff24Hours, lessThanOrEqualTo(24));

      final lastWeekCutoff = ListingDateFilter.lastWeek.cutoff!;
      final diffWeek = now.difference(lastWeekCutoff).inDays;
      expect(diffWeek, greaterThanOrEqualTo(6));
      expect(diffWeek, lessThanOrEqualTo(7));

      final lastMonthCutoff = ListingDateFilter.lastMonth.cutoff!;
      final diffMonth = now.difference(lastMonthCutoff).inDays;
      expect(diffMonth, greaterThanOrEqualTo(29));
      expect(diffMonth, lessThanOrEqualTo(30));
    });

    test('label returns non-empty Turkish text', () {
      for (final filter in ListingDateFilter.values) {
        expect(filter.label, isNotEmpty);
      }
    });
  });

  group('ListingSortOrder', () {
    test('label returns non-empty Turkish text for all sort orders', () {
      for (final sort in ListingSortOrder.values) {
        expect(sort.label, isNotEmpty);
      }
    });
  });

  group('EmploymentType', () {
    test('label returns non-empty Turkish text for all employment types', () {
      expect(EmploymentType.fullTime.label, 'Tam zamanlı');
      expect(EmploymentType.partTime.label, 'Yarı zamanlı');
      expect(EmploymentType.seasonal.label, 'Mevsimlik');
    });
  });

  group('turkishTourismCities', () {
    test('contains popular tourism cities in Turkey', () {
      expect(turkishTourismCities, contains('Antalya'));
      expect(turkishTourismCities, contains('Muğla'));
      expect(turkishTourismCities, contains('İstanbul'));
    });
  });
}

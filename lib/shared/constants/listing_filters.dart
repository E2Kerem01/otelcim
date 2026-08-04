enum EmploymentType {
  fullTime,
  partTime,
  seasonal;

  String get label => switch (this) {
        EmploymentType.fullTime => 'Tam zamanlı',
        EmploymentType.partTime => 'Yarı zamanlı',
        EmploymentType.seasonal => 'Mevsimlik',
      };
}

enum ListingSeason {
  yaz2025,
  kis202526,
  tumYil;

  String get code => switch (this) {
        ListingSeason.yaz2025 => 'yaz_2025',
        ListingSeason.kis202526 => 'kis_2025_26',
        ListingSeason.tumYil => 'tum_yil',
      };

  String get label => switch (this) {
        ListingSeason.yaz2025 => 'Yaz 2025',
        ListingSeason.kis202526 => 'Kış 2025-26',
        ListingSeason.tumYil => 'Tüm Yıl',
      };

  static ListingSeason? fromCode(String? code) {
    if (code == null) return null;
    for (final s in ListingSeason.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

enum ListingDateFilter {
  all,
  last24Hours,
  lastWeek,
  lastMonth;

  String get label => switch (this) {
        ListingDateFilter.all => 'Tümü',
        ListingDateFilter.last24Hours => 'Son 24 saat',
        ListingDateFilter.lastWeek => 'Son hafta',
        ListingDateFilter.lastMonth => 'Son ay',
      };

  DateTime? get cutoff => switch (this) {
        ListingDateFilter.all => null,
        ListingDateFilter.last24Hours => DateTime.now().subtract(const Duration(hours: 24)),
        ListingDateFilter.lastWeek => DateTime.now().subtract(const Duration(days: 7)),
        ListingDateFilter.lastMonth => DateTime.now().subtract(const Duration(days: 30)),
      };
}

enum ListingSortOrder {
  newest,
  salaryHighToLow,
  salaryLowToHigh;

  String get label => switch (this) {
        ListingSortOrder.newest => 'En yeni',
        ListingSortOrder.salaryHighToLow => 'Maaş yüksekten düşüğe',
        ListingSortOrder.salaryLowToHigh => 'Maaş düşükten yükseğe',
      };
}

const turkishTourismCities = <String>[
  'Antalya',
  'İstanbul',
  'Muğla',
  'İzmir',
  'Aydın',
  'Nevşehir',
  'Balıkesir',
  'Çanakkale',
  'Mersin',
  'Adana',
  'Trabzon',
  'Bursa',
  'Ankara',
  'Denizli',
  'Afyonkarahisar',
];

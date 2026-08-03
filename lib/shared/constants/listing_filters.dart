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

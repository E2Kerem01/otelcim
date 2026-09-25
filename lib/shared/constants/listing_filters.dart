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

enum ExperienceLevel {
  none,
  underOneYear,
  oneToThreeYears,
  threePlusYears;

  String get label => switch (this) {
    ExperienceLevel.none => 'Deneyim Aranmıyor',
    ExperienceLevel.underOneYear => '1 Yıldan Az',
    ExperienceLevel.oneToThreeYears => '1-3 Yıl',
    ExperienceLevel.threePlusYears => '3+ Yıl',
  };

  static ExperienceLevel? fromName(String? value) {
    for (final level in values) {
      if (level.name == value) return level;
    }
    return null;
  }
}

enum EducationLevel {
  none,
  primary,
  highSchool,
  university;

  String get label => switch (this) {
    EducationLevel.none => 'Eğitim Şartı Yok',
    EducationLevel.primary => 'En Az İlköğretim',
    EducationLevel.highSchool => 'En Az Lise',
    EducationLevel.university => 'En Az Üniversite',
  };

  static EducationLevel? fromName(String? value) {
    for (final level in values) {
      if (level.name == value) return level;
    }
    return null;
  }
}

class ListingSeason {
  const ListingSeason._(this.code, this.label);

  final String code;
  final String label;

  static const yaz2025 = ListingSeason._('yaz_2025', 'Yaz 2025');
  static const kis202526 = ListingSeason._('kis_2025_26', 'Kış 2025-26');
  static const tumYil = ListingSeason._('tum_yil', 'Tüm Yıl');

  /// The filter options are derived from the current year so new seasons
  /// become selectable without a code change each year.
  static List<ListingSeason> get values => listingSeasonOptions();

  static ListingSeason? fromCode(String? code) {
    if (code == null) return null;
    if (code == yaz2025.code) return yaz2025;
    if (code == kis202526.code) return kis202526;
    if (code == tumYil.code) return tumYil;
    final match = RegExp(r'^(yaz|kis)_(\d{4})(?:_(\d{2}))?$').firstMatch(code);
    if (match != null) {
      final year = match.group(2)!;
      final label = match.group(1) == 'yaz'
          ? 'Yaz $year'
          : 'Kış $year${match.group(3) == null ? '' : '-${match.group(3)}'}';
      return ListingSeason._(code, label);
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ListingSeason && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

List<ListingSeason> listingSeasonOptions({DateTime Function()? clock}) {
  final year = (clock ?? DateTime.now).call().year;
  final nextYear = year + 1;
  final winterCode =
      'kis_${year}_${(nextYear % 100).toString().padLeft(2, '0')}';
  return [
    ListingSeason.fromCode('yaz_$year')!,
    ListingSeason.fromCode(winterCode)!,
    ListingSeason.tumYil,
  ];
}

List<String> get listingSeasonValues =>
    ListingSeason.values.map((season) => season.code).toList(growable: false);

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
    ListingDateFilter.last24Hours => DateTime.now().subtract(
      const Duration(hours: 24),
    ),
    ListingDateFilter.lastWeek => DateTime.now().subtract(
      const Duration(days: 7),
    ),
    ListingDateFilter.lastMonth => DateTime.now().subtract(
      const Duration(days: 30),
    ),
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

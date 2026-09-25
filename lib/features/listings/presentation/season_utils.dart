import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

bool isSeasonalContract(String? season) =>
    season != null && season != 'tum_yil';

String listingSeasonLabel(AppLocalizations l10n, String season) {
  return switch (season) {
    'yaz_2025' => l10n.seasonSummer2025,
    'kis_2025_26' => l10n.seasonWinter202526,
    'tum_yil' => l10n.seasonYearRound,
    _ => _seasonFromCode(l10n, season),
  };
}

final _seasonCode = RegExp(r'^(yaz|kis)_(\d{4})(?:_(\d{2}))?$');

/// Any year's season code (yaz_2026, kis_2026_27) as a readable label,
/// instead of showing the raw code for seasons newer than the named keys.
String _seasonFromCode(AppLocalizations l10n, String season) {
  final match = _seasonCode.firstMatch(season);
  if (match == null) return season;
  final year = match.group(2)!;
  if (match.group(1) == 'yaz') return l10n.seasonSummerOf(year);
  final next = match.group(3);
  return l10n.seasonWinterOf(next == null ? year : '$year-$next');
}

String formatContractDate(DateTime? date, AppLocalizations l10n) {
  if (date == null) return l10n.selectDate;
  return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

class SeasonBadge extends StatelessWidget {
  const SeasonBadge({super.key, required this.season});

  final String season;

  @override
  Widget build(BuildContext context) {
    if (!isSeasonalContract(season)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Text(
        listingSeasonLabel(l10n, season),
        style: TextStyle(
          color: Colors.orange.shade900,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

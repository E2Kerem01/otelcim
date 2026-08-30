import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCategoryFilterProvider = StateProvider<ListingCategory?>((ref) => null);

enum ListingCategory {
  resepsiyon,
  katHizmetleri,
  mutfakAsci,
  servisGarson,
  barBarmen,
  guvenlik,
  animasyon,
  spaWellness,
  havuzPlaj,
  rezervasyonSatis,
  yonetim,
  muhasebeIk,
  teknikServis,
  diger,
}

const Map<ListingCategory, String> listingCategoryLabels = {
  ListingCategory.resepsiyon: 'Resepsiyon',
  ListingCategory.katHizmetleri: 'Kat Hizmetleri',
  ListingCategory.mutfakAsci: 'Mutfak / Aşçı',
  ListingCategory.servisGarson: 'Servis / Garson',
  ListingCategory.barBarmen: 'Bar / Barmen',
  ListingCategory.guvenlik: 'Güvenlik',
  ListingCategory.animasyon: 'Animasyon',
  ListingCategory.spaWellness: 'SPA & Wellness',
  ListingCategory.havuzPlaj: 'Havuz & Plaj',
  ListingCategory.rezervasyonSatis: 'Rezervasyon / Satış',
  ListingCategory.yonetim: 'Yönetim',
  ListingCategory.muhasebeIk: 'Muhasebe / İnsan Kaynakları',
  ListingCategory.teknikServis: 'Teknik Servis',
  ListingCategory.diger: 'Diğer',
};

const Map<ListingCategory, IconData> listingCategoryIcons = {
  ListingCategory.resepsiyon: Icons.desk_outlined,
  ListingCategory.katHizmetleri: Icons.cleaning_services_outlined,
  ListingCategory.mutfakAsci: Icons.restaurant_outlined,
  ListingCategory.servisGarson: Icons.room_service_outlined,
  ListingCategory.barBarmen: Icons.local_bar_outlined,
  ListingCategory.guvenlik: Icons.security_outlined,
  ListingCategory.animasyon: Icons.celebration_outlined,
  ListingCategory.spaWellness: Icons.spa_outlined,
  ListingCategory.havuzPlaj: Icons.pool_outlined,
  ListingCategory.rezervasyonSatis: Icons.event_note_outlined,
  ListingCategory.yonetim: Icons.business_center_outlined,
  ListingCategory.muhasebeIk: Icons.calculate_outlined,
  ListingCategory.teknikServis: Icons.build_outlined,
  ListingCategory.diger: Icons.more_horiz_outlined,
};

/// Accent color per category. Used for the fallback listing-card artwork
/// (most listings have no photo since Storage isn't provisioned) so cards
/// are visually distinguishable at a glance instead of all looking like
/// identical pale-blue boxes with the same generic hotel icon.
const Map<ListingCategory, Color> listingCategoryColors = {
  ListingCategory.resepsiyon: Color(0xFF4C6FFF),
  ListingCategory.katHizmetleri: Color(0xFF14B8A6),
  ListingCategory.mutfakAsci: Color(0xFFF97316),
  ListingCategory.servisGarson: Color(0xFF8B5CF6),
  ListingCategory.barBarmen: Color(0xFFB45309),
  ListingCategory.guvenlik: Color(0xFF1E3A5F),
  ListingCategory.animasyon: Color(0xFFEC4899),
  ListingCategory.spaWellness: Color(0xFF059669),
  ListingCategory.havuzPlaj: Color(0xFF0EA5E9),
  ListingCategory.rezervasyonSatis: Color(0xFF6366F1),
  ListingCategory.yonetim: Color(0xFF475569),
  ListingCategory.muhasebeIk: Color(0xFF9333EA),
  ListingCategory.teknikServis: Color(0xFF0891B2),
  ListingCategory.diger: Color(0xFF64748B),
};

String listingCategoryLabel(String categoryName) {
  final category = ListingCategory.values.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => ListingCategory.diger,
  );
  return listingCategoryLabels[category]!;
}

ListingCategory listingCategoryFromName(String categoryName) {
  return ListingCategory.values.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => ListingCategory.diger,
  );
}

IconData listingCategoryIcon(String categoryName) =>
    listingCategoryIcons[listingCategoryFromName(categoryName)]!;

Color listingCategoryColor(String categoryName) =>
    listingCategoryColors[listingCategoryFromName(categoryName)]!;

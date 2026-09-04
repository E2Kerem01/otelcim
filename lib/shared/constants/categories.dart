import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCategoryFilterProvider = StateProvider<ListingCategory?>((ref) => null);

enum ListingCategory {
  resepsiyon,
  onburoIliskiler,
  katHizmetleri,
  mutfakAsci,
  pastaneSteward,
  servisGarson,
  barBarmen,
  guvenlik,
  saglik,
  animasyon,
  cocukKulubu,
  spaWellness,
  havuzPlaj,
  rezervasyonSatis,
  yonetim,
  muhasebeIk,
  depoAmbar,
  teknikServis,
  bahcePeyzaj,
  ulasimSofor,
  stajyer,
  diger,
}

const Map<ListingCategory, String> listingCategoryLabels = {
  ListingCategory.resepsiyon: 'Resepsiyon',
  ListingCategory.onburoIliskiler: 'Misafir İlişkileri / Önbüro',
  ListingCategory.katHizmetleri: 'Kat Hizmetleri',
  ListingCategory.mutfakAsci: 'Mutfak / Aşçı',
  ListingCategory.pastaneSteward: 'Pastane / Steward',
  ListingCategory.servisGarson: 'Servis / Garson',
  ListingCategory.barBarmen: 'Bar / Barmen',
  ListingCategory.guvenlik: 'Güvenlik',
  ListingCategory.saglik: 'Sağlık / Revir',
  ListingCategory.animasyon: 'Animasyon',
  ListingCategory.cocukKulubu: 'Çocuk Kulübü / Bakıcı',
  ListingCategory.spaWellness: 'SPA & Wellness',
  ListingCategory.havuzPlaj: 'Havuz & Plaj',
  ListingCategory.rezervasyonSatis: 'Rezervasyon / Satış',
  ListingCategory.yonetim: 'Yönetim',
  ListingCategory.muhasebeIk: 'Muhasebe / İnsan Kaynakları',
  ListingCategory.depoAmbar: 'Depo / Ambar',
  ListingCategory.teknikServis: 'Teknik Servis',
  ListingCategory.bahcePeyzaj: 'Bahçe & Peyzaj',
  ListingCategory.ulasimSofor: 'Ulaşım / Şoför',
  ListingCategory.stajyer: 'Stajyer',
  ListingCategory.diger: 'Diğer',
};

const Map<ListingCategory, IconData> listingCategoryIcons = {
  ListingCategory.resepsiyon: Icons.desk_outlined,
  ListingCategory.onburoIliskiler: Icons.support_agent_outlined,
  ListingCategory.katHizmetleri: Icons.cleaning_services_outlined,
  ListingCategory.mutfakAsci: Icons.restaurant_outlined,
  ListingCategory.pastaneSteward: Icons.cake_outlined,
  ListingCategory.servisGarson: Icons.room_service_outlined,
  ListingCategory.barBarmen: Icons.local_bar_outlined,
  ListingCategory.guvenlik: Icons.security_outlined,
  ListingCategory.saglik: Icons.medical_services_outlined,
  ListingCategory.animasyon: Icons.celebration_outlined,
  ListingCategory.cocukKulubu: Icons.child_care_outlined,
  ListingCategory.spaWellness: Icons.spa_outlined,
  ListingCategory.havuzPlaj: Icons.pool_outlined,
  ListingCategory.rezervasyonSatis: Icons.event_note_outlined,
  ListingCategory.yonetim: Icons.business_center_outlined,
  ListingCategory.muhasebeIk: Icons.calculate_outlined,
  ListingCategory.depoAmbar: Icons.warehouse_outlined,
  ListingCategory.teknikServis: Icons.build_outlined,
  ListingCategory.bahcePeyzaj: Icons.grass_outlined,
  ListingCategory.ulasimSofor: Icons.directions_car_outlined,
  ListingCategory.stajyer: Icons.school_outlined,
  ListingCategory.diger: Icons.more_horiz_outlined,
};

/// Accent color per category. Used for the fallback listing-card artwork
/// (most listings have no photo since Storage isn't provisioned) so cards
/// are visually distinguishable at a glance instead of all looking like
/// identical pale-blue boxes with the same generic hotel icon.
const Map<ListingCategory, Color> listingCategoryColors = {
  ListingCategory.resepsiyon: Color(0xFF4C6FFF),
  ListingCategory.onburoIliskiler: Color(0xFFE11D48),
  ListingCategory.katHizmetleri: Color(0xFF14B8A6),
  ListingCategory.mutfakAsci: Color(0xFFF97316),
  ListingCategory.pastaneSteward: Color(0xFFD97706),
  ListingCategory.servisGarson: Color(0xFF8B5CF6),
  ListingCategory.barBarmen: Color(0xFFB45309),
  ListingCategory.guvenlik: Color(0xFF1E3A5F),
  ListingCategory.saglik: Color(0xFFDC2626),
  ListingCategory.animasyon: Color(0xFFEC4899),
  ListingCategory.cocukKulubu: Color(0xFFFACC15),
  ListingCategory.spaWellness: Color(0xFF059669),
  ListingCategory.havuzPlaj: Color(0xFF0EA5E9),
  ListingCategory.rezervasyonSatis: Color(0xFF6366F1),
  ListingCategory.yonetim: Color(0xFF475569),
  ListingCategory.muhasebeIk: Color(0xFF9333EA),
  ListingCategory.depoAmbar: Color(0xFF78716C),
  ListingCategory.teknikServis: Color(0xFF0891B2),
  ListingCategory.bahcePeyzaj: Color(0xFF16A34A),
  ListingCategory.ulasimSofor: Color(0xFF0369A1),
  ListingCategory.stajyer: Color(0xFF7C3AED),
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

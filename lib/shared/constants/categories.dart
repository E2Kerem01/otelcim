import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedCategoryFilterProvider = StateProvider<ListingCategory?>((ref) => null);

enum ListingCategory {
  resepsiyon,
  katHizmetleri,
  mutfakAsci,
  servisGarson,
  guvenlik,
  animasyon,
  yonetim,
  teknikServis,
  diger,
}

const Map<ListingCategory, String> listingCategoryLabels = {
  ListingCategory.resepsiyon: 'Resepsiyon',
  ListingCategory.katHizmetleri: 'Kat Hizmetleri',
  ListingCategory.mutfakAsci: 'Mutfak / Aşçı',
  ListingCategory.servisGarson: 'Servis / Garson',
  ListingCategory.guvenlik: 'Güvenlik',
  ListingCategory.animasyon: 'Animasyon',
  ListingCategory.yonetim: 'Yönetim',
  ListingCategory.teknikServis: 'Teknik Servis',
  ListingCategory.diger: 'Diğer',
};

const Map<ListingCategory, IconData> listingCategoryIcons = {
  ListingCategory.resepsiyon: Icons.desk_outlined,
  ListingCategory.katHizmetleri: Icons.cleaning_services_outlined,
  ListingCategory.mutfakAsci: Icons.restaurant_outlined,
  ListingCategory.servisGarson: Icons.room_service_outlined,
  ListingCategory.guvenlik: Icons.security_outlined,
  ListingCategory.animasyon: Icons.celebration_outlined,
  ListingCategory.yonetim: Icons.business_center_outlined,
  ListingCategory.teknikServis: Icons.build_outlined,
  ListingCategory.diger: Icons.more_horiz_outlined,
};

String listingCategoryLabel(String categoryName) {
  final category = ListingCategory.values.firstWhere(
    (c) => c.name == categoryName,
    orElse: () => ListingCategory.diger,
  );
  return listingCategoryLabels[category]!;
}

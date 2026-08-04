import '../../listings/domain/listing_model.dart';
import 'tourism_region.dart';

Map<String, int> countRegionListings(Iterable<Listing> listings) {
  final counts = {for (final region in tourismRegions) region.id: 0};
  for (final listing in listings) {
    final region = listing.region;
    if (region != null && counts.containsKey(region)) {
      counts[region] = counts[region]! + 1;
    }
  }
  return counts;
}

double regionMarkerDiameter(int listingCount) =>
    (44 + listingCount * 2).clamp(44, 72).toDouble();

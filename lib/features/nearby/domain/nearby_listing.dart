import 'dart:math' as math;

import '../../listings/domain/listing_model.dart';

class NearbyListing {
  const NearbyListing({required this.listing, required this.distanceKm});

  final Listing listing;
  final double distanceKm;
}

double calculateDistanceKm({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earthRadiusKm = 6371.0;
  final latDelta = _radians(toLat - fromLat);
  final lngDelta = _radians(toLng - fromLng);
  final a =
      math.pow(math.sin(latDelta / 2), 2) +
      math.cos(_radians(fromLat)) *
          math.cos(_radians(toLat)) *
          math.pow(math.sin(lngDelta / 2), 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

List<NearbyListing> nearbyListings({
  required Iterable<Listing> listings,
  required double userLat,
  required double userLng,
  required double radiusKm,
}) {
  final results = <NearbyListing>[];
  for (final listing in listings) {
    final lat = listing.lat;
    final lng = listing.lng;
    if (lat == null || lng == null) continue;
    final distance = calculateDistanceKm(
      fromLat: userLat,
      fromLng: userLng,
      toLat: lat,
      toLng: lng,
    );
    if (distance <= radiusKm) {
      results.add(NearbyListing(listing: listing, distanceKm: distance));
    }
  }
  results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return results;
}

double _radians(double degrees) => degrees * math.pi / 180;

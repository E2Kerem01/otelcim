import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/features/listings/domain/listing_model.dart';
import 'package:otelcim/features/nearby/domain/nearby_listing.dart';

Listing listing(String id, double? lat, double? lng) => Listing(
  id: id,
  posterId: 'poster',
  posterName: 'Hotel',
  title: id,
  description: 'description',
  category: 'diger',
  location: 'location',
  salary: 'salary',
  contactInfo: 'contact',
  lat: lat,
  lng: lng,
);

void main() {
  test('Haversine returns the expected Istanbul-Ankara distance', () {
    final distance = calculateDistanceKm(
      fromLat: 41.0082,
      fromLng: 28.9784,
      toLat: 39.9334,
      toLng: 32.8597,
    );
    expect(distance, closeTo(352, 3));
  });

  test(
    'nearby listings excludes missing coordinates and sorts by distance',
    () {
      final results = nearbyListings(
        listings: [
          listing('far', 41.2, 29.0),
          listing('missing', null, null),
          listing('near', 41.01, 28.98),
          listing('outside', 39.93, 32.86),
        ],
        userLat: 41.0082,
        userLng: 28.9784,
        radiusKm: 25,
      );
      expect(results.map((item) => item.listing.id), ['near', 'far']);
      expect(results.first.distanceKm, lessThan(results.last.distanceKm));
    },
  );
}

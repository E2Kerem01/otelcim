class TourismRegion {
  const TourismRegion({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String nameTr;
  final String nameEn;
  final double latitude;
  final double longitude;
}

const tourismRegions = <TourismRegion>[
  TourismRegion(
    id: 'antalya',
    nameTr: 'Antalya',
    nameEn: 'Antalya',
    latitude: 36.8969,
    longitude: 30.7133,
  ),
  TourismRegion(
    id: 'bodrum',
    nameTr: 'Bodrum',
    nameEn: 'Bodrum',
    latitude: 37.0344,
    longitude: 27.4305,
  ),
  TourismRegion(
    id: 'fethiye',
    nameTr: 'Fethiye',
    nameEn: 'Fethiye',
    latitude: 36.6217,
    longitude: 29.1164,
  ),
  TourismRegion(
    id: 'marmaris',
    nameTr: 'Marmaris',
    nameEn: 'Marmaris',
    latitude: 36.8549,
    longitude: 28.2709,
  ),
  TourismRegion(
    id: 'kusadasi',
    nameTr: 'Kuşadası',
    nameEn: 'Kusadasi',
    latitude: 37.8579,
    longitude: 27.2610,
  ),
  TourismRegion(
    id: 'kapadokya',
    nameTr: 'Kapadokya',
    nameEn: 'Cappadocia',
    latitude: 38.6431,
    longitude: 34.8289,
  ),
  TourismRegion(
    id: 'istanbul',
    nameTr: 'İstanbul',
    nameEn: 'Istanbul',
    latitude: 41.0082,
    longitude: 28.9784,
  ),
  TourismRegion(
    id: 'izmir',
    nameTr: 'İzmir',
    nameEn: 'Izmir',
    latitude: 38.4237,
    longitude: 27.1428,
  ),
  TourismRegion(
    id: 'trabzon',
    nameTr: 'Trabzon',
    nameEn: 'Trabzon',
    latitude: 41.0027,
    longitude: 39.7168,
  ),
  TourismRegion(
    id: 'cesme',
    nameTr: 'Çeşme',
    nameEn: 'Cesme',
    latitude: 38.3242,
    longitude: 26.3020,
  ),
];

TourismRegion? tourismRegionById(String? id) {
  if (id == null) return null;
  for (final region in tourismRegions) {
    if (region.id == id) return region;
  }
  return null;
}

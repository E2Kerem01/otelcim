import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

enum LocationFailure { servicesDisabled, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.success(this.position) : failure = null;
  const LocationResult.failure(this.failure) : position = null;

  final Position? position;
  final LocationFailure? failure;
}

class LocationService {
  Future<LocationResult> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.servicesDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailure.denied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.deniedForever);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationResult.success(position);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

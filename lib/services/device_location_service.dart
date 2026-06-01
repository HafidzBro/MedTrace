import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? address;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.address,
  });
}

class DeviceLocationService {
  const DeviceLocationService();

  Future<DeviceLocation> getCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionDeniedException();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: await _reverseGeocode(position),
    );
  }

  Future<String?> _reverseGeocode(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = [
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
        place.country,
      ].where((part) => part != null && part.trim().isNotEmpty);

      final address = parts.join(', ');
      return address.isEmpty ? null : address;
    } catch (_) {
      return null;
    }
  }
}

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();
}

class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();
}

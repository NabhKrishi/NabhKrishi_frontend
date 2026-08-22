import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_model.dart';

class LocationNotifier extends Notifier<LocationData> {
  @override
  LocationData build() {
    // Default location: Ludhiana agricultural zone (30.9009, 75.8573)
    return LocationData(
      latitude: 30.9009,
      longitude: 75.8573,
      boundary: [],
    );
  }

  void updateCoordinate(double latitude, double longitude) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
    );
  }

  void addBoundaryPoint(LatLng point) {
    final updatedBoundary = List<LatLng>.from(state.boundary)..add(point);
    state = state.copyWith(boundary: updatedBoundary);
  }

  void removeLastBoundaryPoint() {
    if (state.boundary.isEmpty) return;
    final updatedBoundary = List<LatLng>.from(state.boundary)..removeLast();
    state = state.copyWith(boundary: updatedBoundary);
  }

  void clearBoundary() {
    state = state.copyWith(boundary: []);
  }

  void setBoundary(List<LatLng> points) {
    state = state.copyWith(boundary: points);
  }

  /// Triggers device geolocation.
  /// Throws standard user-friendly error messages on failure.
  Future<void> fetchDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'error_gps_unavailable';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'error_gps_denied';
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw 'error_gps_denied';
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      updateCoordinate(position.latitude, position.longitude);
      clearBoundary(); // Reset boundary when location changes to new region.
    } catch (_) {
      throw 'error_generic';
    }
  }
}

final locationProvider = NotifierProvider<LocationNotifier, LocationData>(() {
  return LocationNotifier();
});

final confirmedLocationProvider = StateProvider<LocationData>((ref) {
  return LocationData(
    latitude: 30.9009,
    longitude: 75.8573,
    boundary: [],
  );
});

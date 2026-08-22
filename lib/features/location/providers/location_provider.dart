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
      boundary: const [],
      isDrawing: false,
      isLocating: false,
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
    double newLat = state.latitude;
    double newLng = state.longitude;
    if (updatedBoundary.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (final pt in updatedBoundary) {
        latSum += pt.latitude;
        lngSum += pt.longitude;
      }
      newLat = latSum / updatedBoundary.length;
      newLng = lngSum / updatedBoundary.length;
    }
    state = state.copyWith(
      boundary: updatedBoundary,
      latitude: newLat,
      longitude: newLng,
    );
  }

  void undoLastBoundaryPoint() {
    if (state.boundary.isEmpty) return;
    final updatedBoundary = List<LatLng>.from(state.boundary)..removeLast();
    double newLat = state.latitude;
    double newLng = state.longitude;
    if (updatedBoundary.isNotEmpty) {
      double latSum = 0;
      double lngSum = 0;
      for (final pt in updatedBoundary) {
        latSum += pt.latitude;
        lngSum += pt.longitude;
      }
      newLat = latSum / updatedBoundary.length;
      newLng = lngSum / updatedBoundary.length;
    }
    state = state.copyWith(
      boundary: updatedBoundary,
      latitude: newLat,
      longitude: newLng,
    );
  }

  void clearBoundary() {
    state = state.copyWith(boundary: const []);
  }

  void setBoundary(List<LatLng> points) {
    state = state.copyWith(boundary: points);
  }

  void toggleDrawing(bool drawing) {
    state = state.copyWith(isDrawing: drawing);
  }

  void clearGpsError() {
    state = state.copyWith(gpsError: null);
  }

  /// Triggers device geolocation.
  Future<void> fetchDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    state = state.copyWith(isLocating: true, gpsError: null);

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(isLocating: false, gpsError: 'error_gps_unavailable');
        throw 'error_gps_unavailable';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(isLocating: false, gpsError: 'error_gps_denied');
          throw 'error_gps_denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(isLocating: false, gpsError: 'error_gps_denied');
        throw 'error_gps_denied';
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        boundary: const [],
        isLocating: false,
        gpsError: null,
      );
    } catch (e) {
      String err = 'error_generic';
      if (e == 'error_gps_unavailable' || e == 'error_gps_denied') {
        err = e.toString();
      }
      state = state.copyWith(isLocating: false, gpsError: err);
      rethrow;
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
    boundary: const [],
    isDrawing: false,
    isLocating: false,
  );
});

import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final List<LatLng> boundary;
  final bool isDrawing;
  final bool isLocating;
  final String? gpsError;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.boundary,
    this.isDrawing = false,
    this.isLocating = false,
    this.gpsError,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    List<LatLng>? boundary,
    bool? isDrawing,
    bool? isLocating,
    String? gpsError,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      boundary: boundary ?? this.boundary,
      isDrawing: isDrawing ?? this.isDrawing,
      isLocating: isLocating ?? this.isLocating,
      gpsError: gpsError, // cleared if not explicitly passed
    );
  }

  /// Calculates the centroid of the farm boundary polygon.
  /// If the boundary is empty, returns the current latitude and longitude.
  LatLng get centroid {
    if (boundary.isEmpty) {
      return LatLng(latitude, longitude);
    }
    
    double latSum = 0;
    double lngSum = 0;
    for (final point in boundary) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / boundary.length, lngSum / boundary.length);
  }

  /// Calculates the approximate area of the farm boundary in hectares.
  /// Uses planar Shoelace projection relative to centroid center.
  double get farmAreaHectares {
    if (boundary.length < 3) return 0.0;

    final center = centroid;
    final latCenterRad = center.latitude * 3.141592653589793 / 180.0;

    final List<double> xCoords = [];
    final List<double> yCoords = [];

    for (final pt in boundary) {
      // Longitude to meters relative to center
      xCoords.add(pt.longitude * 111320.0 * math.cos(latCenterRad));
      // Latitude to meters relative to center
      yCoords.add(pt.latitude * 110540.0);
    }

    double area = 0.0;
    int j = boundary.length - 1;
    for (int i = 0; i < boundary.length; i++) {
      area += (xCoords[j] + xCoords[i]) * (yCoords[j] - yCoords[i]);
      j = i;
    }

    return (area.abs() / 2.0) / 10000.0;
  }
}

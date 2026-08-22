import 'package:latlong2/latlong.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final List<LatLng> boundary;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.boundary,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    List<LatLng>? boundary,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      boundary: boundary ?? this.boundary,
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
}

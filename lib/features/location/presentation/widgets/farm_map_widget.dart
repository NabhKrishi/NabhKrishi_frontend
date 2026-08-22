import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../language/providers/language_provider.dart';
import '../../providers/location_provider.dart';

class FarmMapWidget extends ConsumerStatefulWidget {
  final VoidCallback onLocationConfirmed;

  const FarmMapWidget({
    super.key,
    required this.onLocationConfirmed,
  });

  @override
  ConsumerState<FarmMapWidget> createState() => _FarmMapWidgetState();
}

class _FarmMapWidgetState extends ConsumerState<FarmMapWidget> {
  final MapController _mapController = MapController();
  bool _isLocating = false;
  String? _gpsError;

  @override
  Widget build(BuildContext context) {
    final locationData = ref.watch(locationProvider);
    final currentLanguage = ref.watch(languageProvider);
    final confirmedLoc = ref.watch(confirmedLocationProvider);
    final hasChanges = locationData.latitude != confirmedLoc.latitude ||
        locationData.longitude != confirmedLoc.longitude ||
        locationData.boundary.length != confirmedLoc.boundary.length;
    final mapCenter = LatLng(locationData.latitude, locationData.longitude);

    // Listen to location provider changes to center map on GPS updates automatically
    ref.listen(locationProvider, (previous, next) {
      if (previous == null || previous.latitude != next.latitude || previous.longitude != next.longitude) {
        _mapController.move(LatLng(next.latitude, next.longitude), 16.0);
      }
    });

    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0C2A34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6CE6B6).withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Interactive Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: mapCenter,
                initialZoom: 14.0,
                onTap: (tapPosition, point) {
                  // Add vertex to boundary polygon
                  ref.read(locationProvider.notifier).addBoundaryPoint(point);
                  // Update center to centroid
                  final centroid = ref.read(locationProvider).centroid;
                  ref.read(locationProvider.notifier).updateCoordinate(centroid.latitude, centroid.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.nabhkrishi.app',
                  tileBuilder: (context, tileWidget, tile) {
                    // Give tiles a subtle green/blue tint to match NabhKrishi dark theme
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2, 0.4, 0.4, 0.0, -100.0, // R
                        0.2, 0.5, 0.3, 0.0, -60.0,  // G
                        0.3, 0.3, 0.6, 0.0, -40.0,  // B
                        0.0, 0.0, 0.0, 1.0, 0.0,    // A
                      ]),
                      child: tileWidget,
                    );
                  },
                ),
                // Draw Farm Area Polygon
                if (locationData.boundary.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: locationData.boundary,
                        color: const Color(0xFF56E2AF).withValues(alpha: 0.25),
                        borderColor: const Color(0xFF56E2AF),
                        borderStrokeWidth: 2.5,
                        isFilled: true,
                      ),
                    ],
                  )
                else if (locationData.boundary.isNotEmpty)
                  // For drawing phase, connect points with a polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: locationData.boundary,
                        color: const Color(0xFFE7C96E),
                        strokeWidth: 2,
                      ),
                    ],
                  ),
                // Marker at Centroid (Prediction coordinate)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: locationData.centroid,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE7C96E),
                        size: 32,
                      ),
                    ),
                    // Draw mini dots for boundary vertices
                    ...locationData.boundary.map(
                      (pt) => Marker(
                        point: pt,
                        width: 10,
                        height: 10,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF56E2AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top Instructions Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF031A22).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Text(
                  locationData.boundary.length < 3
                      ? context.translate('draw_instruction', currentLanguage)
                      : '${context.translate('farm_boundary', currentLanguage)}: ${locationData.boundary.length} ${currentLanguage == 'Hindi' ? 'बिंदु' : 'points'}',
                  style: GoogleFonts.poppins(color: const Color(0xFFD4E3E7), fontSize: 10.5),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Bottom Right Map Controls
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                children: [
                  // Clear Boundary Button
                  if (locationData.boundary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: FloatingActionButton.small(
                        heroTag: 'clear_map_boundary',
                        backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.9),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                        onPressed: () {
                          ref.read(locationProvider.notifier).clearBoundary();
                        },
                      ),
                    ),
                  // Zoom In Button
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_map',
                    backgroundColor: const Color(0xFF0C2A34).withValues(alpha: 0.9),
                    child: const Icon(Icons.add, color: Colors.white70),
                    onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                  ),
                  const SizedBox(height: 6),
                  // Zoom Out Button
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_map',
                    backgroundColor: const Color(0xFF0C2A34).withValues(alpha: 0.9),
                    child: const Icon(Icons.remove, color: Colors.white70),
                    onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                  ),
                ],
              ),
            ),

            // Use My Location & Confirm Button Bar
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  // Use My Location
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39C793),
                      foregroundColor: const Color(0xFF07372B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      elevation: 4,
                    ),
                    icon: _isLocating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07372B)),
                          )
                        : const Icon(Icons.my_location_rounded, size: 16),
                    label: Text(
                      context.translate('use_my_location', currentLanguage),
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isLocating ? null : _gpsLocationHandler,
                  ),
                  const SizedBox(width: 8),
                  // Confirm button
                  if (hasChanges)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7C96E),
                        foregroundColor: const Color(0xFF2C2405),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        elevation: 4,
                      ),
                      child: Text(
                        context.translate('confirm_farm_location', currentLanguage),
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      onPressed: widget.onLocationConfirmed,
                    ),
                ],
              ),
            ),

            // GPS Error Notification Overlay
            if (_gpsError != null)
              Positioned(
                top: 70,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.translate(_gpsError!, currentLanguage),
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 10.5),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _gpsError = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _gpsLocationHandler() async {
    setState(() {
      _isLocating = true;
      _gpsError = null;
    });

    try {
      await ref.read(locationProvider.notifier).fetchDeviceLocation();
      widget.onLocationConfirmed();
    } catch (e) {
      setState(() {
        _gpsError = e.toString();
      });
    } finally {
      setState(() {
        _isLocating = false;
      });
    }
  }
}

// Helper color extension to avoid hardcoded/missing colors
extension ColorsExtension on Colors {
  static const Color whiteDimm = Color(0xFFD4E3E7);
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../../core/constants/location_constants.dart';
import '../../core/theme/app_theme.dart';
import '../services/location_service.dart';

class SalahnyMapMarker {
  const SalahnyMapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.snippet,
    this.onTap,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? snippet;
  final VoidCallback? onTap;
}

class SalahnyMap extends StatelessWidget {
  const SalahnyMap({
    super.key,
    required this.markers,
    this.currentLocation,
    this.onTap,
    this.height = 220,
  });

  final List<SalahnyMapMarker> markers;
  final LatLng? currentLocation;
  final ValueChanged<LatLng>? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final center =
        currentLocation ??
            (markers.isNotEmpty
                ? LatLng(markers.first.latitude, markers.first.longitude)
                : const LatLng(30.0444, 31.2357));

    final mapKey = ValueKey(
      '${center.latitude}_${center.longitude}_${markers.length}',
    );

    final useOsm =
        kIsWeb ||
        !LocationConstants.useGoogleMaps ||
        !LocationConstants.googleMapsConfigured;

    return ClipRRect(
      borderRadius: Rd.lgA,
      child: SizedBox(
        height: height,
        child: useOsm
            ? fmap.FlutterMap(
                key: mapKey,
                options: fmap.MapOptions(
                  initialCenter: center,
                  initialZoom: 13,
                  onTap: onTap == null
                      ? null
                      : (_, point) =>
                          onTap!(LatLng(point.latitude, point.longitude)),
                ),
                children: [
                  fmap.TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.salahny_fixed',
                  ),
                  fmap.MarkerLayer(
                    markers: [
                      for (final marker in markers)
                        fmap.Marker(
                          point: LatLng(marker.latitude, marker.longitude),
                          width: 42,
                          height: 42,
                          child: GestureDetector(
                            onTap: marker.onTap,
                            child: Tooltip(
                              message: marker.snippet == null
                                  ? marker.title
                                  : '${marker.title}\n${marker.snippet}',
                              child: const Icon(
                                Icons.location_on,
                                color: AC.red,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      if (currentLocation != null)
                        fmap.Marker(
                          point: LatLng(
                            currentLocation!.latitude,
                            currentLocation!.longitude,
                          ),
                          width: 42,
                          height: 42,
                          child: const Icon(
                            Icons.my_location,
                            color: AC.info,
                            size: 28,
                          ),
                        ),
                    ],
                  ),
                ],
              )
            : gm.GoogleMap(
                key: mapKey,
                initialCameraPosition: gm.CameraPosition(
                  target: gm.LatLng(center.latitude, center.longitude),
                  zoom: 13,
                ),
                markers: {
                  for (final marker in markers)
                    gm.Marker(
                      markerId: gm.MarkerId(marker.id),
                      position: gm.LatLng(marker.latitude, marker.longitude),
                      infoWindow: gm.InfoWindow(
                        title: marker.title,
                        snippet: marker.snippet,
                      ),
                      onTap: marker.onTap,
                    ),
                  if (currentLocation != null)
                    gm.Marker(
                      markerId: const gm.MarkerId('current_location'),
                      position: gm.LatLng(
                        currentLocation!.latitude,
                        currentLocation!.longitude,
                      ),
                      infoWindow:
                          const gm.InfoWindow(title: 'Current location'),
                      icon: gm.BitmapDescriptor.defaultMarkerWithHue(
                        gm.BitmapDescriptor.hueAzure,
                      ),
                    ),
                },
                myLocationEnabled: currentLocation != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: onTap == null
                    ? null
                    : (p) => onTap!(LatLng(p.latitude, p.longitude)),
              ),
      ),
    );
  }
}

Future<LocationResult> requestCurrentPosition({bool withAddress = false}) =>
    const LocationService().currentPosition(withAddress: withAddress);
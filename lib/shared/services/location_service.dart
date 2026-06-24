import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class LocationResult {
  const LocationResult({
    this.position,
    this.address,
    this.message,
    this.permanentlyDenied = false,
    this.serviceDisabled = false,
  });

  final Position? position;
  final String? address;
  final String? message;
  final bool permanentlyDenied;
  final bool serviceDisabled;

  bool get hasLocation => position != null;
}

class LocationService {
  const LocationService();

  Future<LocationResult> currentPosition({bool withAddress = false}) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return const LocationResult(
        serviceDisabled: true,
        message: 'GPS is disabled. Please enable location services.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        permanentlyDenied: true,
        message:
            'Location permission is permanently denied. Enable it from app settings.',
      );
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(
        message:
            'Location permission denied. You can enter the address manually.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final address = withAddress
        ? await reverseGeocode(position.latitude, position.longitude)
        : null;
    return LocationResult(position: position, address: address);
  }

  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final marks = await placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) return null;
      final p = marks.first;
      return [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.country,
      ].where((part) => (part ?? '').trim().isNotEmpty).join(', ');
    } catch (_) {
      return null;
    }
  }

  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;
      return LatLng(locations.first.latitude, locations.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> openAppSettings() => ph.openAppSettings();

  static double distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthKm = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double value) => value * math.pi / 180;
}

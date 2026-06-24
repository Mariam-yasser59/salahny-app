import 'package:flutter/material.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/salahny_map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _service = EmergencyService();
  final _locationService = const LocationService();
  final _address = TextEditingController();
  final _notes = TextEditingController();
  final _issue = TextEditingController();
  String _type = 'towing';
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _addressSearching = false;
  bool _submitting = false;
  bool _loading = true;
  List<EmergencyRequestModel> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    _issue.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppErrorHandler.guard(context, _service.myRequests);
    if (!mounted) return;
    setState(() {
      _history = items ?? const [];
      _loading = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final result = await _locationService.currentPosition(withAddress: true);
      if (!mounted) return;
      if (!result.hasLocation) {
        AppErrorHandler.showMessage(
          context,
          result.message ??
              'Could not detect your location. Enter an address manually.',
        );
        if (result.permanentlyDenied) {
          await _locationService.openAppSettings();
        }
        return;
      }
      final position = result.position!;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_address.text.trim().isEmpty) {
          _address.text =
              result.address ??
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (_) {
      if (mounted) {
        AppErrorHandler.showMessage(
          context,
          'Could not detect your location. Enter an address manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_address.text.trim().isEmpty || _issue.text.trim().isEmpty) {
      AppErrorHandler.showMessage(
        context,
        'Enter both the issue description and a location.',
      );
      return;
    }
    if ((_latitude == null || _longitude == null) &&
        _address.text.trim().isNotEmpty) {
      final point = await _locationService.geocodeAddress(_address.text.trim());
      if (point != null) {
        _latitude = point.latitude;
        _longitude = point.longitude;
      }
    }
    setState(() => _submitting = true);
    final request = await AppErrorHandler.guard(
      context,
      () => _service.createRequest(
        emergencyType: _type,
        issueDescription: _issue.text.trim(),
        address: _address.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        locationNotes: _notes.text.trim(),
        vehicleId: AppCache.vehicles.firstOrNull?.id,
        vehicleLabel: AppCache.vehicles.firstOrNull?.fullName ?? '',
        phone: AppCache.currentUser.phone,
      ),
      fallbackMessage: 'Could not create the emergency request.',
      successMessage: 'Emergency request created',
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (request != null) {
      await _load();
    }
  }

  Future<void> _searchAddress() async {
    final address = _address.text.trim();
    if (address.isEmpty) {
      AppErrorHandler.showMessage(context, 'Type an address first.');
      return;
    }
    setState(() => _addressSearching = true);
    final point = await _locationService.geocodeAddress(address);
    if (!mounted) return;
    setState(() => _addressSearching = false);
    if (point == null) {
      AppErrorHandler.showMessage(
        context,
        'Could not find that address. Try adding city/country.',
      );
      return;
    }
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const SAppBar(title: 'Emergency Help'),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Request Roadside Assistance',
                  style: TextStyle(
                    color: AC.t1,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _type,
                  dropdownColor: AC.s2,
                  items: const [
                    DropdownMenuItem(value: 'towing', child: Text('Towing')),
                    DropdownMenuItem(value: 'battery', child: Text('Battery')),
                    DropdownMenuItem(value: 'tire', child: Text('Tire')),
                    DropdownMenuItem(value: 'engine', child: Text('Engine')),
                    DropdownMenuItem(value: 'fuel', child: Text('Fuel')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _type = value ?? 'other'),
                ),
                const SizedBox(height: 12),
                AppField(
                  label: 'Issue Description',
                  hint: 'What happened?',
                  ctrl: _issue,
                ),
                const SizedBox(height: 12),
                AppField(
                  label: 'Address',
                  hint: 'Street, district, landmark — editable like Uber',
                  ctrl: _address,
                ),
                const SizedBox(height: 12),
                AppField(
                  label: 'Location Notes',
                  hint: 'Near gas station, beside bridge, etc.',
                  ctrl: _notes,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppBtn(
                        label: _locating
                            ? 'Detecting...'
                            : 'Use Current Location',
                        outline: true,
                        loading: _locating,
                        onTap: _locating ? null : _useCurrentLocation,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppBtn(
                        label: _addressSearching
                            ? 'Searching...'
                            : 'Search Address',
                        loading: _addressSearching,
                        onTap: _addressSearching ? null : _searchAddress,
                      ),
                    ),
                  ],
                ),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Detected address: ${_address.text.trim().isEmpty ? 'selected map point' : _address.text.trim()}',
                    style: const TextStyle(color: AC.t2, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saved GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                    style: const TextStyle(color: AC.t3, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                SalahnyMap(
                  currentLocation: _latitude != null && _longitude != null
                      ? LatLng(_latitude!, _longitude!)
                      : null,
                  markers: const [],
                  onTap: (point) {
                    setState(() {
                      _latitude = point.latitude;
                      _longitude = point.longitude;
                      _address.text =
                          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
                    });
                    _locationService
                        .reverseGeocode(point.latitude, point.longitude)
                        .then((address) {
                          if (!mounted || address == null) return;
                          setState(() => _address.text = address);
                        });
                  },
                ),
                const SizedBox(height: 16),
                AppBtn(
                  label: 'Send Emergency Request',
                  loading: _submitting,
                  onTap: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SecHeader(title: 'Emergency History'),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            const EmptyState(
              icon: '!',
              title: 'No emergency requests',
              sub: 'Your requests will appear here.',
            )
          else
            ..._history.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.issueDescription,
                        style: const TextStyle(
                          color: AC.t1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(item.address, style: const TextStyle(color: AC.t3)),
                      const SizedBox(height: 6),
                      Text(
                        item.assignedWorkshopName == null
                            ? 'Waiting for admin assignment'
                            : '${item.assignedWorkshopName} - ${item.distanceKm?.toStringAsFixed(1) ?? '-'} km',
                        style: const TextStyle(color: AC.t2),
                      ),
                      const SizedBox(height: 6),
                      GoldBadge(item.status.replaceAll('_', ' ')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

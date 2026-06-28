import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../workshops/services/workshop_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/salahny_map.dart';

class WorkshopsScreen extends StatefulWidget {
  const WorkshopsScreen({super.key});

  @override
  State<WorkshopsScreen> createState() => _WorkshopsScreenState();
}

class _WorkshopsScreenState extends State<WorkshopsScreen> {
  static const double _nearbyRadiusKm = 25;

  final _api = WorkshopService();
  final _locationService = const LocationService();
  final _searchCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  List<WorkshopModel> _allItems = AppData.i.workshops;
  List<WorkshopModel> _items = AppData.i.workshops;
  bool _loading = false;
  bool _locating = false;
  bool _addressSearching = false;
  LatLng? _currentLocation;
  String? _locationMessage;
  String? _detectedAddress;
  final Map<String, LatLng> _geocodedWorkshopLocations = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilters);
    _load();
    _loadLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getWorkshops(
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
        search: _searchCtrl.text,
      );
      if (!mounted) return;
      setState(() => _allItems = _sortByDistance(data));
      _applyFilters();
      _geocodeMissingWorkshopLocations(data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _allItems = AppData.i.workshops);
      _applyFilters();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLocation() async {
    setState(() => _locating = true);
    final result = await _locationService.currentPosition(withAddress: true);
    if (!mounted) return;
    setState(() => _locating = false);
    if (!result.hasLocation) {
      setState(() => _locationMessage = result.message);
      return;
    }
    final position = result.position!;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _detectedAddress = result.address;
      _addressCtrl.text =
          result.address ??
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      _locationMessage = null;
      _allItems = _sortByDistance(_allItems);
    });
    _applyFilters();
    await _load();
  }

  Future<void> _searchAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      setState(() => _locationMessage = 'Type an address or area first.');
      return;
    }
    setState(() {
      _addressSearching = true;
      _locationMessage = null;
    });
    final point = await _locationService.geocodeAddress(address);
    if (!mounted) return;
    if (point == null) {
      setState(() {
        _addressSearching = false;
        _locationMessage =
            'Could not find that address. Try adding city/country.';
      });
      return;
    }
    setState(() {
      _addressSearching = false;
      _currentLocation = point;
      _detectedAddress = address;
      _allItems = _sortByDistance(_allItems);
    });
    _applyFilters();
    await _load();
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    final nearby = _currentLocation == null
        ? <WorkshopModel>[]
        : _allItems
              .where((item) {
                final distance = _distanceFor(item);
                return distance != null && distance <= _nearbyRadiusKm;
              })
              .toList(growable: false);
    final filtered = query.isEmpty
        ? nearby
        : nearby
              .where((item) {
                final haystack = [
                  item.name,
                  item.specialty,
                  item.address,
                ].join(' ').toLowerCase();
                return haystack.contains(query);
              })
              .toList(growable: false);
    if (!mounted) return;
    setState(() => _items = _sortByDistance(filtered));
  }

  List<WorkshopModel> _sortByDistance(List<WorkshopModel> items) {
    if (_currentLocation == null) return items;
    final sorted = [...items];
    sorted.sort((a, b) {
      final ad = _distanceFor(a);
      final bd = _distanceFor(b);
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return sorted;
  }

  double? _distanceFor(WorkshopModel item) {
    final point = _pointFor(item);
    if (_currentLocation == null || point == null) {
      return item.distance > 0 ? item.distance : null;
    }
    return LocationService.distanceKm(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      point.latitude,
      point.longitude,
    );
  }

  LatLng? _pointFor(WorkshopModel item) {
    if (item.latitude != null && item.longitude != null) {
      return LatLng(item.latitude!, item.longitude!);
    }
    return _geocodedWorkshopLocations[item.id];
  }

  Future<void> _geocodeMissingWorkshopLocations(
    List<WorkshopModel> workshops,
  ) async {
    for (final workshop in workshops) {
      if (!mounted) return;
      if (_pointFor(workshop) != null || workshop.address.trim().isEmpty) {
        continue;
      }
      final point = await _locationService.geocodeAddress(workshop.address);
      if (point == null || !mounted) continue;
      setState(() {
        _geocodedWorkshopLocations[workshop.id] = point;
        _allItems = _sortByDistance(_allItems);
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const SAppBar(title: 'Nearby Workshops'),
    body: Column(
      children: [
        if (_loading)
          const LinearProgressIndicator(minHeight: 2, color: AC.red),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            children: [
              _SearchField(
                controller: _searchCtrl,
                hint: 'Search by workshop, service, or area',
                onSubmitted: (_) => _load(),
                onRefresh: _load,
              ),
              const SizedBox(height: 10),
              _AddressPickerCard(
                controller: _addressCtrl,
                detectedAddress: _detectedAddress,
                loadingLocation: _locating,
                searchingAddress: _addressSearching,
                onUseCurrentLocation: _loadLocation,
                onSearchAddress: _searchAddress,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: SalahnyMap(
            currentLocation: _currentLocation,
            markers: _items
                .map((item) {
                  final point = _pointFor(item);
                  if (point == null) return null;
                  final distance = _distanceFor(item) ?? item.distance;
                  return SalahnyMapMarker(
                    id: item.id,
                    latitude: point.latitude,
                    longitude: point.longitude,
                    title: item.name,
                    snippet:
                        '${item.specialty} • ${distance.toStringAsFixed(1)} km',
                    onTap: () => Navigator.pushNamed(
                      context,
                      R.workshopDetail,
                      arguments: item.id,
                    ),
                  );
                })
                .whereType<SalahnyMapMarker>()
                .toList(growable: false),
          ),
        ),
        if (_locationMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              _locationMessage!,
              style: const TextStyle(color: AC.warning, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SecHeader(
            title: 'Available Now',
            sub: _currentLocation == null
                ? 'Share your location to see nearby workshops'
                : '${_items.length} workshops within ${_nearbyRadiusKm.toStringAsFixed(0)} km',
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: EmptyState(
                    icon: '?',
                    title: _currentLocation == null
                        ? 'Location required'
                        : 'No nearby workshops',
                    sub: _currentLocation == null
                        ? 'Use current location or search an address to show nearby workshops only.'
                        : 'Try another address or check back when more workshops are available nearby.',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _workshopTile(
                    workshop: _items[i],
                    distanceKm: _distanceFor(_items[i]) ?? _items[i].distance,
                  ),
                ),
        ),
      ],
    ),
  );

  Widget _workshopTile({
    required WorkshopModel workshop,
    required double distanceKm,
  }) => ACard(
    onTap: () =>
        Navigator.pushNamed(context, R.workshopDetail, arguments: workshop.id),
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.mdA),
          child: const Icon(
            Icons.garage_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workshop.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AC.t1,
                      ),
                    ),
                  ),
                  if (workshop.isVerified) const GoldBadge('Verified'),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                workshop.specialty,
                style: const TextStyle(fontSize: 12, color: AC.t3),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  RatingStars(rating: workshop.rating),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      workshop.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AC.t3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: workshop.isOpen
                    ? AC.success.withValues(alpha: 0.12)
                    : AC.error.withValues(alpha: 0.12),
                borderRadius: Rd.fullA,
                border: Border.all(
                  color: workshop.isOpen
                      ? AC.success.withValues(alpha: 0.4)
                      : AC.error.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                workshop.isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: workshop.isOpen ? AC.success : AC.error,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AC.t2,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    required this.onRefresh,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onSubmitted: onSubmitted,
    style: const TextStyle(color: AC.t1),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AC.t4),
      prefixIcon: const Icon(Icons.search_rounded, color: AC.t3),
      suffixIcon: IconButton(
        icon: const Icon(Icons.tune_rounded, color: AC.red),
        onPressed: onRefresh,
      ),
      filled: true,
      fillColor: AC.s2,
      border: OutlineInputBorder(
        borderRadius: Rd.lgA,
        borderSide: const BorderSide(color: AC.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Rd.lgA,
        borderSide: const BorderSide(color: AC.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Rd.lgA,
        borderSide: const BorderSide(color: AC.red, width: 1.2),
      ),
    ),
  );
}

class _AddressPickerCard extends StatelessWidget {
  const _AddressPickerCard({
    required this.controller,
    required this.detectedAddress,
    required this.loadingLocation,
    required this.searchingAddress,
    required this.onUseCurrentLocation,
    required this.onSearchAddress,
  });

  final TextEditingController controller;
  final String? detectedAddress;
  final bool loadingLocation;
  final bool searchingAddress;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onSearchAddress;

  @override
  Widget build(BuildContext context) => ACard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((detectedAddress ?? '').isNotEmpty) ...[
          Text(
            'Detected address: $detectedAddress',
            style: const TextStyle(color: AC.t2, fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          style: const TextStyle(color: AC.t1, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Type an address or area like Uber',
            hintStyle: const TextStyle(color: AC.t4),
            prefixIcon: const Icon(Icons.place_rounded, color: AC.red),
            filled: true,
            fillColor: AC.s1,
            border: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.red),
            ),
          ),
          onSubmitted: (_) => onSearchAddress(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: AppBtn(
                label: loadingLocation
                    ? 'Detecting...'
                    : 'Use Current Location',
                outline: true,
                loading: loadingLocation,
                onTap: loadingLocation ? null : onUseCurrentLocation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppBtn(
                label: searchingAddress ? 'Searching...' : 'Search Address',
                loading: searchingAddress,
                onTap: searchingAddress ? null : onSearchAddress,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

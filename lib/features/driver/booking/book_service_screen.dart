import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../workshops/services/workshop_service.dart';

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  static const double _nearbyRadiusKm = 25;

  int _step = 0;
  String? _vehicleId, _workshopId, _serviceId, _date, _time;
  DateTime? _slot;
  bool _routeArgsApplied = false;
  final _workshopService = WorkshopService();
  final _locationService = const LocationService();
  List<WorkshopModel> _workshops = AppData.i.workshops;
  LatLng? _currentLocation;
  bool _locating = false;
  String? _locationMessage;

  static const _diagnosticServiceId = 'ai_car_check_diagnostics';

  WorkshopModel? get _selectedWorkshop => _nearbyWorkshops
      .where((workshop) => workshop.id == _workshopId)
      .firstOrNull;

  List<WorkshopModel> get _nearbyWorkshops {
    if (_currentLocation == null) return const [];
    final nearby = _workshops
        .where((workshop) {
          final distance = _distanceFor(workshop);
          return distance != null && distance <= _nearbyRadiusKm;
        })
        .toList(growable: false);
    nearby.sort(
      (a, b) =>
          (_distanceFor(a) ?? 999999).compareTo(_distanceFor(b) ?? 999999),
    );
    return nearby;
  }

  ServiceModel get _diagnosticService => const ServiceModel(
    id: _diagnosticServiceId,
    name: 'Car Check + AI Diagnostics',
    category: 'Inspection',
    description:
        'Workshop inspection supported by Salahny AI diagnostic review.',
    emoji: 'AI',
    price: 25,
    durationMins: 30,
    isPopular: true,
  );

  List<ServiceModel> get _serviceOptions {
    final services = AppData.i.services;
    final workshop = _selectedWorkshop;
    final availableNames =
        workshop?.serviceNames
            .map((name) => name.toLowerCase().trim())
            .where((name) => name.isNotEmpty)
            .toSet() ??
        const <String>{};

    final matched = availableNames.isEmpty
        ? services
        : services
              .where(
                (service) => availableNames.any(
                  (name) =>
                      name == service.name.toLowerCase().trim() ||
                      name.contains(service.name.toLowerCase().trim()) ||
                      service.name.toLowerCase().contains(name),
                ),
              )
              .toList(growable: false);

    final base = matched.isEmpty ? services : matched;
    return [_diagnosticService, ...base];
  }

  ServiceModel? get _selectedService {
    final options = _serviceOptions;
    if (options.isEmpty) return null;
    return options.firstWhere(
      (service) => service.id == _serviceId,
      orElse: () => options.first,
    );
  }

  List<DateTime> get _availableSlots =>
      (_selectedWorkshop?.availableSlots ?? const [])
          .where((slot) => slot.isAfter(DateTime.now()))
          .toList()
        ..sort();

  List<String> get _dates =>
      _availableSlots.map(_dateLabel).toSet().toList(growable: false);

  List<String> get _times => _availableSlots
      .where((slot) => _dateLabel(slot) == _date)
      .map((slot) => DateFormat('h:mm a').format(slot))
      .toSet()
      .toList(growable: false);

  final _labels = const [
    'Select Vehicle',
    'Choose Workshop',
    'Choose Service',
    'Pick a Date',
    'Pick a Time',
  ];

  bool get _canNext => [
    _vehicleId != null,
    _workshopId != null,
    _serviceId != null,
    _date != null,
    _time != null,
  ][_step];

  @override
  void initState() {
    super.initState();
    final preferredVehicleId = AppCache.preferredVehicleId;
    final vehicles = AppData.i.vehicles;
    if (vehicles.isNotEmpty) {
      _vehicleId = vehicles.any((vehicle) => vehicle.id == preferredVehicleId)
          ? preferredVehicleId
          : vehicles.first.id;
      _step = 1;
    }
    _loadLocation();
  }

  Future<void> _loadWorkshops() async {
    try {
      final workshops = await _workshopService.getWorkshops(
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );
      if (!mounted) return;
      setState(() => _workshops = workshops);
    } catch (_) {
      if (!mounted) return;
      setState(() => _workshops = AppData.i.workshops);
    }
  }

  Future<void> _loadLocation() async {
    setState(() {
      _locating = true;
      _locationMessage = null;
    });
    final result = await _locationService.currentPosition(withAddress: true);
    if (!mounted) return;
    setState(() => _locating = false);
    if (!result.hasLocation) {
      setState(
        () => _locationMessage =
            result.message ?? 'Could not detect your location.',
      );
      await _loadWorkshops();
      return;
    }
    final position = result.position!;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _locationMessage = result.address;
    });
    await _loadWorkshops();
  }

  void _applyRouteArgs() {
    if (_routeArgsApplied) return;
    _routeArgsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    final presetWorkshopId = args is Map<String, dynamic>
        ? args['workshopId']?.toString()
        : null;
    final presetServiceId = args is String
        ? args
        : args is Map<String, dynamic>
        ? args['serviceId']?.toString()
        : null;
    if (presetWorkshopId != null && presetWorkshopId.isNotEmpty) {
      _workshopId = presetWorkshopId;
      if (_step < 2 && _vehicleId != null) _step = 2;
    }
    if (presetServiceId != null && presetServiceId.isNotEmpty) {
      _serviceId = presetServiceId;
    }
  }

  @override
  Widget build(BuildContext context) {
    _applyRouteArgs();

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(
        title: 'Book a Service',
        actions: [
          IconButton(
            tooltip: 'Refresh slots',
            onPressed: _loadWorkshops,
            icon: const Icon(Icons.refresh_rounded, color: AC.t1),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              children: List.generate(
                _labels.length,
                (i) => Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: 250.ms,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: i <= _step ? AC.redGrad : null,
                            color: i > _step ? AC.border : null,
                            borderRadius: Rd.fullA,
                            boxShadow: i <= _step
                                ? [
                                    BoxShadow(
                                      color: AC.red.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                      if (i < _labels.length - 1) const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _labels[_step],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                Text(
                  '${_step + 1}/${_labels.length}',
                  style: const TextStyle(fontSize: 13, color: AC.t3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: [
                  _vehicleStep(),
                  _workshopStep(),
                  _serviceStep(),
                  _dateStep(),
                  _timeStep(),
                ][_step],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Row(
              children: [
                if (_step > 0) ...[
                  GestureDetector(
                    onTap: () => setState(() => _step--),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AC.s2,
                        borderRadius: Rd.mdA,
                        border: Border.all(color: AC.border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AC.t2),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _canNext ? 1 : 0.5,
                    duration: 200.ms,
                    child: AppBtn(
                      label: _step < _labels.length - 1
                          ? 'Next'
                          : 'Confirm Booking',
                      onTap: _canNext ? _nextOrConfirm : null,
                      icon: Icon(
                        _step < _labels.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleStep() => AppData.i.vehicles.isEmpty
      ? const Center(
          child: EmptyState(
            icon: 'CAR',
            title: 'No Vehicles',
            sub: 'Add a vehicle before booking a service.',
          ),
        )
      : ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            ...AppData.i.vehicles.map(
              (v) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: VehicleCard(
                  make: v.make,
                  model: v.model,
                  year: v.year,
                  plate: v.plate,
                  health: v.health.toDouble(),
                  selected: _vehicleId == v.id,
                  onTap: () => setState(() => _vehicleId = v.id),
                ),
              ),
            ),
          ],
        );

  Widget _workshopStep() => _workshops.isEmpty
      ? const Center(
          child: EmptyState(
            icon: 'WS',
            title: 'No Workshops',
            sub: 'Workshops will appear after owner setup.',
          ),
        )
      : _currentLocation == null
      ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ACard(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AC.red,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Location required',
                    style: TextStyle(
                      color: AC.t1,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Salahny shows nearby workshops only. Share your location to continue booking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AC.t3, height: 1.4),
                  ),
                  if ((_locationMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _locationMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AC.warning, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppBtn(
                    label: _locating ? 'Detecting...' : 'Use Current Location',
                    loading: _locating,
                    onTap: _locating ? null : _loadLocation,
                  ),
                ],
              ),
            ),
          ),
        )
      : _nearbyWorkshops.isEmpty
      ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: EmptyState(
              icon: 'WS',
              title: 'No Nearby Workshops',
              sub:
                  'No approved workshops were found within ${_nearbyRadiusKm.toStringAsFixed(0)} km. Try again from another location.',
            ),
          ),
        )
      : ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            ..._nearbyWorkshops.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SelectableCard(
                  selected: _workshopId == w.id,
                  icon: Icons.garage_rounded,
                  title: w.name,
                  subtitle: w.specialty,
                  trailing: w.isVerified ? const GoldBadge('Verified') : null,
                  footer: Row(
                    children: [
                      RatingStars(rating: w.rating),
                      const SizedBox(width: 6),
                      Text(
                        '${(_distanceFor(w) ?? w.distance).toStringAsFixed(1)} km',
                        style: const TextStyle(fontSize: 11, color: AC.gold),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AC.t3),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => setState(() {
                    _workshopId = w.id;
                    _serviceId = null;
                    _date = null;
                    _time = null;
                    _slot = null;
                  }),
                ),
              ),
            ),
          ],
        );

  Widget _serviceStep() {
    final options = _serviceOptions;
    if (_selectedWorkshop == null) {
      return const Center(
        child: EmptyState(
          icon: 'WS',
          title: 'Choose a workshop first',
          sub: 'A workshop is required before selecting a service.',
        ),
      );
    }
    if (options.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: 'SVC',
          title: 'No Services Available',
          sub: 'Services will appear after workshops add them.',
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        ACard(
          glow: true,
          glowColor: AC.purple,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need to check your car first?',
                style: TextStyle(
                  color: AC.t1,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You can book an AI-supported car check, or run diagnostics now before booking.',
                style: TextStyle(color: AC.t3, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),
              AppBtn(
                label: 'Run AI Diagnostics First',
                outline: true,
                onTap: () => Navigator.pushNamed(context, R.diagnostics),
                icon: const Icon(
                  Icons.analytics_rounded,
                  color: AC.red,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...options.map(
          (service) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableCard(
              selected: _serviceId == service.id,
              icon: service.id == _diagnosticServiceId
                  ? Icons.health_and_safety_rounded
                  : Icons.build_rounded,
              title: service.name,
              subtitle: service.description,
              footer: Row(
                children: [
                  Text(
                    service.id == _diagnosticServiceId ? 'AI' : service.emoji,
                    style: const TextStyle(fontSize: 16, color: AC.t2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${service.durationMins} min',
                    style: const TextStyle(fontSize: 12, color: AC.t3),
                  ),
                  const Spacer(),
                  Text(
                    '\$${service.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AC.gold,
                    ),
                  ),
                ],
              ),
              trailing: service.isPopular
                  ? const GoldBadge('Recommended')
                  : null,
              onTap: () => setState(() {
                _serviceId = service.id;
                _date = null;
                _time = null;
                _slot = null;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dateStep() => _dates.isEmpty
      ? const Center(
          child: EmptyState(
            icon: 'S',
            title: 'No Slots Available',
            sub: 'Choose another workshop or check back later.',
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _dates
                .map(
                  (d) => GestureDetector(
                    onTap: () => setState(() {
                      _date = d;
                      _time = null;
                      _slot = null;
                    }),
                    child: _ChipBox(label: d, selected: _date == d),
                  ),
                )
                .toList(),
          ),
        );

  Widget _timeStep() => _times.isEmpty
      ? const Center(
          child: EmptyState(
            icon: 'T',
            title: 'Pick a Date First',
            sub: 'Available times are loaded from the workshop schedule.',
          ),
        )
      : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _times
                .map(
                  (t) => GestureDetector(
                    onTap: () => setState(() {
                      _time = t;
                      _slot = _availableSlots.firstWhere(
                        (slot) =>
                            _dateLabel(slot) == _date &&
                            DateFormat('h:mm a').format(slot) == t,
                      );
                    }),
                    child: _ChipBox(label: t, selected: _time == t),
                  ),
                )
                .toList(),
          ),
        );

  Future<void> _nextOrConfirm() async {
    if (_step < _labels.length - 1) {
      setState(() => _step++);
      return;
    }

    final vehicles = AppData.i.vehicles;
    final service = _selectedService;
    if (vehicles.isEmpty || _nearbyWorkshops.isEmpty || service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehicle, workshop, and service data must be loaded.'),
        ),
      );
      return;
    }
    final vehicle = vehicles.firstWhere(
      (item) => item.id == _vehicleId,
      orElse: () => vehicles.first,
    );
    final workshop = _nearbyWorkshops.firstWhere(
      (item) => item.id == _workshopId,
      orElse: () => _nearbyWorkshops.first,
    );
    final subtotal = service.price;
    const serviceFee = 5.0;
    final discount = service.isPopular && service.id != _diagnosticServiceId
        ? 4.0
        : 0.0;
    await AppCache.saveBookingCheckout(
      BookingCheckoutData(
        serviceId: service.id,
        serviceName: service.name,
        workshopId: workshop.id,
        workshopName: workshop.name,
        vehicleId: vehicle.id,
        vehicleLabel: vehicle.fullName,
        date: _date!,
        time: _time!,
        slotIso: _slot!.toUtc().toIso8601String(),
        durationMins: service.durationMins,
        subtotal: subtotal,
        serviceFee: serviceFee,
        discount: discount,
        total: subtotal + serviceFee - discount,
        paymentOptions: const [
          PaymentOptionData(
            id: 'card',
            icon: 'Card',
            label: 'Credit / Debit Card',
          ),
          PaymentOptionData(id: 'wallet', icon: 'Pay', label: 'Apple Pay'),
          PaymentOptionData(id: 'cash', icon: 'Cash', label: 'Cash on Service'),
        ],
        selectedPaymentOptionId: 'card',
      ),
    );
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, R.bookingConfirm);
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(date.year, date.month, date.day);
    if (selected == today) return 'Today';
    if (selected == today.add(const Duration(days: 1))) return 'Tomorrow';
    return DateFormat('MMM d').format(date);
  }

  double? _distanceFor(WorkshopModel workshop) {
    if (_currentLocation == null) {
      return workshop.distance > 0 ? workshop.distance : null;
    }
    if (workshop.latitude != null && workshop.longitude != null) {
      return LocationService.distanceKm(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        workshop.latitude!,
        workshop.longitude!,
      );
    }
    return workshop.distance > 0 ? workshop.distance : null;
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.footer,
    this.trailing,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? footer;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: 250.ms,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
        ),
        borderRadius: Rd.lgA,
        border: Border.all(
          color: selected ? AC.red : AC.border,
          width: selected ? 1.5 : 0.8,
        ),
        boxShadow: selected
            ? [BoxShadow(color: AC.red.withValues(alpha: 0.2), blurRadius: 18)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: selected ? AC.redGrad : null,
              color: selected ? null : AC.s2,
              borderRadius: Rd.mdA,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
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
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AC.t1,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AC.t3),
                ),
                if (footer != null) ...[const SizedBox(height: 8), footer!],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ChipBox extends StatelessWidget {
  const _ChipBox({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: 200.ms,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      gradient: selected ? AC.redGrad : null,
      color: selected ? null : AC.s2,
      borderRadius: Rd.mdA,
      border: Border.all(color: selected ? AC.red : AC.border),
      boxShadow: selected
          ? [BoxShadow(color: AC.red.withValues(alpha: 0.3), blurRadius: 12)]
          : null,
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AC.t2,
      ),
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

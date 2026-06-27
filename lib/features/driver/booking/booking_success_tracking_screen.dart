import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/realtime_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../ratings/services/rating_service.dart';
import 'services/tracking_service.dart';

class BookingSuccessTrackingScreen extends StatefulWidget {
  const BookingSuccessTrackingScreen({super.key});

  @override
  State<BookingSuccessTrackingScreen> createState() =>
      _BookingSuccessTrackingScreenState();
}

class _BookingSuccessTrackingScreenState
    extends State<BookingSuccessTrackingScreen> {
  final _tracking = TrackingService();
  List<TrackingPoint> _points = const [];
  StreamSubscription<RealtimeEvent>? _subscription;

  Future<void> _load(String bookingId) async {
    if (bookingId.isEmpty) return;
    await RealtimeService.instance.joinBooking(bookingId);
    _subscription ??= RealtimeService.instance.events.listen((event) {
      if (event.type != 'tracking_update') return;
      final point = _tracking.mapPoint(event.data);
      if (mounted) setState(() => _points = [point, ..._points]);
    });
    final points = await _tracking
        .getUpdates(bookingId)
        .catchError((_) => const <TrackingPoint>[]);
    if (mounted) setState(() => _points = points);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = ModalRoute.of(context)?.settings.arguments as String?;
    final bookings = AppData.i.bookings;
    if (bookings.isEmpty) {
      return const Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(title: 'Booking Confirmed'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No bookings available to track yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AC.t3, fontSize: 16),
            ),
          ),
        ),
      );
    }

    final booking = bookings.firstWhere(
      (item) => item.id == bookingId,
      orElse: () => bookings.first,
    );
    if (_points.isEmpty) _load(booking.id);
    final latest = _points.isEmpty ? null : _points.first;
    final statusColor = _statusColor(booking.status);

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const SAppBar(title: 'Booking Confirmed'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AC.redGrad,
              borderRadius: Rd.lgA,
              boxShadow: AS.redGlow,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: Rd.mdA,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking confirmed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.serviceName,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${booking.workshopName} • ${booking.date} ${booking.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    GoldBadge('\$${booking.price.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: Rd.fullA,
                  child: LinearProgressIndicator(
                    value: _progressFor(booking.status),
                    minHeight: 8,
                    backgroundColor: AC.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusHint(booking.status),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AC.t3,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  icon: Icons.schedule_rounded,
                  label: 'ETA',
                  value: latest == null ? '--' : '${latest.etaMinutes} min',
                  color: AC.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(
                  icon: Icons.location_on_rounded,
                  label: 'Tracking',
                  value: latest == null ? 'Waiting' : 'Live',
                  color: latest == null ? AC.warning : AC.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SecHeader(title: 'Live Workshop Location'),
                const SizedBox(height: 14),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AC.s1,
                    borderRadius: Rd.lgA,
                    border: Border.all(color: AC.border),
                  ),
                  child: latest == null
                      ? const Center(
                          child: Text(
                            'Waiting for workshop location',
                            style: TextStyle(fontSize: 12, color: AC.t2),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: Rd.lgA,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                latest.latitude,
                                latest.longitude,
                              ),
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.salahny.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      latest.latitude,
                                      latest.longitude,
                                    ),
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: AC.redGrad,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.car_repair_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                if (latest?.note.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Text(
                    latest!.note,
                    style: const TextStyle(fontSize: 12, color: AC.t3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (booking.status.toLowerCase() == 'completed' &&
              !booking.driverReviewed) ...[
            _RateWorkshopCard(bookingId: booking.id),
            const SizedBox(height: 16),
          ],
          AppBtn(
            label: 'Chat with Mechanic',
            outline: true,
            onTap: () => Navigator.pushNamed(
              context,
              R.mechanicChat,
              arguments: booking.id,
            ),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AC.red,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          AppBtn(
            label: 'Back to Home',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              R.home,
              (_) => false,
            ),
            icon: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  double _progressFor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 0.35;
      case 'in progress':
        return 0.55;
      case 'diagnostics ready':
        return 0.7;
      case 'repair in progress':
        return 0.85;
      case 'completed':
        return 1;
      default:
        return 0.15;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AC.success;
      case 'accepted':
      case 'in progress':
      case 'repair in progress':
        return AC.info;
      case 'diagnostics ready':
        return AC.purple;
      default:
        return AC.warning;
    }
  }

  String _statusHint(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'The workshop accepted your request and is preparing the job.';
      case 'in progress':
        return 'Service has started. You will see live updates here.';
      case 'diagnostics ready':
        return 'Diagnostics are ready and the workshop is reviewing the result.';
      case 'repair in progress':
        return 'Repair is underway. The workshop will update you when finished.';
      case 'completed':
        return 'Your service is complete and ready for handoff.';
      default:
        return 'Your request was sent and is waiting for workshop review.';
    }
  }
}

class _RateWorkshopCard extends StatefulWidget {
  const _RateWorkshopCard({required this.bookingId});

  final String bookingId;

  @override
  State<_RateWorkshopCard> createState() => _RateWorkshopCardState();
}

class _RateWorkshopCardState extends State<_RateWorkshopCard> {
  final _service = RatingService();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _service.submitRating(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _comment.text,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Workshop rating submitted')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return const SizedBox.shrink();
    return ACard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate this workshop',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AC.t1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                onPressed: _loading
                    ? null
                    : () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: AC.gold,
                ),
              ),
            ),
          ),
          TextField(
            controller: _comment,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a short note',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          AppBtn(
            label: _loading ? 'Submitting...' : 'Submit Rating',
            onTap: _loading ? () {} : _submit,
            icon: const Icon(Icons.star_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AC.s2,
      borderRadius: Rd.lgA,
      border: Border.all(color: AC.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AC.t3)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AC.t1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

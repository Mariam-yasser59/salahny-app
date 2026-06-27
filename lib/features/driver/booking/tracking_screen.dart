import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../ratings/services/rating_service.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  static const _steps = [
    ('Booking Confirmed', 'Your request was received', true, AC.success),
    (
      'Awaiting Workshop',
      'Workshop is reviewing your request',
      false,
      AC.warning,
    ),
    ('Work in Progress', 'Technician has started', false, AC.info),
    ('Ready for Pickup', 'Your car is ready', false, AC.success),
  ];

  @override
  Widget build(BuildContext context) {
    // Accept a booking ID passed as route argument, fallback to first booking
    final argId = ModalRoute.of(context)?.settings.arguments;
    if (AppData.i.bookings.isEmpty) {
      return Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(title: 'Booking History'),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: EmptyState(
              icon: '📅',
              title: 'No bookings yet',
              sub:
                  'Book a service first, then your booking status will appear here.',
            ),
          ),
        ),
      );
    }
    final BookingModel booking;
    if (argId != null) {
      booking = AppData.i.bookings.firstWhere(
        (b) => b.id == argId.toString(),
        orElse: () => AppData.i.bookings.first,
      );
    } else {
      booking = AppData.i.bookings.first;
    }

    // Map booking status to step progress
    final completedSteps = _stepsCompleted(booking.status);

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Track Booking'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            ACard(
              glow: true,
              glowColor: AC.warning,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AC.redGrad,
                      borderRadius: Rd.mdA,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AC.t1,
                          ),
                        ),
                        Text(
                          '${booking.workshopName} • ${booking.date} ${booking.time}',
                          style: const TextStyle(fontSize: 12, color: AC.t3),
                        ),
                      ],
                    ),
                  ),
                  StatusChip(booking.status),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (_, i) {
                  final (title, sub, _, col) = _steps[i];
                  final isDone = i < completedSteps;
                  return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: isDone
                                      ? LinearGradient(
                                          colors: [col.withOpacity(0.8), col],
                                        )
                                      : null,
                                  color: isDone ? null : AC.s3,
                                  shape: BoxShape.circle,
                                  border: isDone
                                      ? null
                                      : Border.all(color: AC.border),
                                ),
                                child: Icon(
                                  isDone
                                      ? Icons.check_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isDone ? Colors.white : AC.t4,
                                  size: 18,
                                ),
                              ),
                              if (i < _steps.length - 1)
                                Container(
                                  width: 2,
                                  height: 52,
                                  color: isDone
                                      ? col.withOpacity(0.4)
                                      : AC.border,
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDone ? AC.t1 : AC.t3,
                                    ),
                                  ),
                                  Text(
                                    sub,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AC.t3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      .animate()
                      .fadeIn(delay: (i * 100).ms)
                      .slideX(begin: 0.2, end: 0, delay: (i * 100).ms);
                },
              ),
            ),
            if (booking.status.toLowerCase() == 'completed' &&
                !booking.driverReviewed) ...[
              _RateWorkshopCard(booking: booking),
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: AppBtn(
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
            ),
          ],
        ),
      ),
    );
  }

  int _stepsCompleted(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 2;
      case 'completed':
        return 4;
      case 'pending':
      default:
        return 1;
    }
  }
}

class _RateWorkshopCard extends StatefulWidget {
  const _RateWorkshopCard({required this.booking});

  final BookingModel booking;

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
        bookingId: widget.booking.id,
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

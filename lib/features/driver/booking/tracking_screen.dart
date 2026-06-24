import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  static const _steps = [
    ('Booking Confirmed',  'Your request was received',        true,  AC.success),
    ('Awaiting Workshop',  'Workshop is reviewing your request', false, AC.warning),
    ('Work in Progress',   'Technician has started',           false, AC.info),
    ('Ready for Pickup',   'Your car is ready',                false, AC.success),
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
              sub: 'Book a service first, then your booking status will appear here.',
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
        child: Column(children: [
          const SizedBox(height: 8),
          ACard(
            glow: true,
            glowColor: AC.warning,
            child: Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.mdA)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(booking.serviceName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AC.t1)),
                Text('${booking.workshopName} • ${booking.date} ${booking.time}',
                  style: const TextStyle(fontSize: 12, color: AC.t3)),
              ])),
              StatusChip(booking.status),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _steps.length,
              itemBuilder: (_, i) {
                final (title, sub, _, col) = _steps[i];
                final isDone = i < completedSteps;
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: isDone ? LinearGradient(colors: [col.withOpacity(0.8), col]) : null,
                        color: isDone ? null : AC.s3,
                        shape: BoxShape.circle,
                        border: isDone ? null : Border.all(color: AC.border),
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                        color: isDone ? Colors.white : AC.t4,
                        size: 18,
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Container(width: 2, height: 52, color: isDone ? col.withOpacity(0.4) : AC.border),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: isDone ? AC.t1 : AC.t3)),
                      Text(sub, style: const TextStyle(fontSize: 12, color: AC.t3)),
                    ]),
                  )),
                ]).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.2, end: 0, delay: (i * 100).ms);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: AppBtn(
              label: 'Chat with Mechanic',
              outline: true,
              onTap: () => Navigator.pushNamed(context, R.mechanicChat, arguments: booking.id),
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: AC.red, size: 18),
            ),
          ),
        ]),
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

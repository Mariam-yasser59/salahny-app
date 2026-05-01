import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/services/mock_data.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class BookingsManagementScreen extends StatelessWidget {
  const BookingsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminShell(
    title: 'Bookings',
    child: BookingsManagementView(),
  );
}

class BookingsManagementView extends StatefulWidget {
  const BookingsManagementView({super.key});

  @override
  State<BookingsManagementView> createState() => _BookingsManagementViewState();
}

class _BookingsManagementViewState extends State<BookingsManagementView> {
  String _filter = 'All';
  final _service = AdminService();

  Future<void> _updateStatus(AdminBooking booking, AdminBookingStatus status) async {
    final ok = await AppErrorHandler.guard<bool>(
      context,
      () async {
        await _service.updateBookingStatus(booking.id, status);
        await _service.refreshBookings();
        await _service.refreshLogs();
        return true;
      },
      fallbackMessage: 'Could not update this booking right now.',
    );
    if (!mounted || ok != true) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bookings = MockData.adminBookings.where((booking) {
      if (_filter == 'All') return true;
      return booking.status.label == _filter;
    }).toList();

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Pending', 'Active', 'Completed', 'Cancelled']
                  .map(
                    (item) => AdminFilterPill(
                      label: item,
                      selected: _filter == item,
                      onTap: () => setState(() => _filter = item),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            ...bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${booking.serviceName} • ${booking.driverName}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AC.t1,
                              ),
                            ),
                          ),
                          StatusChip(booking.status.label),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${booking.workshopName} • ${booking.date} ${booking.time}',
                        style: const TextStyle(fontSize: 12, color: AC.t3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Payment: ${booking.paymentMethod} • \$${booking.total.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, color: AC.t3),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppBtn(
                              label: 'Details',
                              small: true,
                              outline: true,
                              onTap: () => _showDetails(context, booking),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppBtn(
                              label: 'Cancel',
                              small: true,
                              outline: true,
                              onTap: () => _updateStatus(
                                booking,
                                AdminBookingStatus.cancelled,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  void _showDetails(BuildContext context, AdminBooking booking) {
    showAdminInfoDialog(
      context: context,
      title: 'Booking ${booking.id}',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          AdminBooking current = MockData.bookingById(booking.id) ?? booking;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoRow(label: 'Driver', value: current.driverName),
              const SizedBox(height: 10),
              InfoRow(label: 'Workshop', value: current.workshopName),
              const SizedBox(height: 10),
              InfoRow(label: 'Service', value: current.serviceName),
              const SizedBox(height: 10),
              InfoRow(label: 'Status', value: current.status.label),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AdminBookingStatus.values
                    .map(
                      (status) => AdminFilterPill(
                        label: status.label,
                        selected: current.status == status,
                        onTap: () {
                          _updateStatus(current, status).then((_) {
                            if (!mounted) return;
                            setModalState(() {
                              current = MockData.bookingById(current.id) ?? current;
                            });
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

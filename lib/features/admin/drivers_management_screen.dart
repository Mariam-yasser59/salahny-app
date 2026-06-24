import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class DriversManagementScreen extends StatelessWidget {
  const DriversManagementScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AdminShell(title: 'Drivers', child: DriversManagementView());
}

class DriversManagementView extends StatefulWidget {
  const DriversManagementView({super.key});

  @override
  State<DriversManagementView> createState() => _DriversManagementViewState();
}

class _DriversManagementViewState extends State<DriversManagementView> {
  String _query = '';
  final _service = AdminService();

  Future<void> _refresh() async {
    await _service.refreshDrivers();
    await _service.refreshLogs();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = AppCache.drivers
        .where(
          (driver) =>
              driver.name.toLowerCase().contains(_query.toLowerCase()) ||
              driver.email.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        children: [
          AdminSearchBar(
            hint: 'Search drivers by name or email',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (driver) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AdminSectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AC.red.withOpacity(0.16),
                          child: Text(
                            driver.name.substring(0, 1),
                            style: const TextStyle(
                              color: AC.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AC.t1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                driver.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AC.t3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(driver.status.label),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: AppBtn(
                            label: 'Details',
                            small: true,
                            outline: true,
                            onTap: () => _showDetails(context, driver),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppBtn(
                            label: 'Message',
                            small: true,
                            outline: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              R.saDriverChat,
                              arguments: {
                                'driverId': driver.id,
                                'driverName': driver.name,
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppBtn(
                            label: driver.status == AdminAccountStatus.suspended
                                ? 'Activate'
                                : 'Suspend',
                            small: true,
                            onTap: () => AppErrorHandler.guard<void>(
                              context,
                              () async {
                                await _service.updateUserStatus(
                                  driver.id,
                                  driver.status == AdminAccountStatus.suspended
                                      ? AdminAccountStatus.active
                                      : AdminAccountStatus.suspended,
                                );
                                await _refresh();
                              },
                              fallbackMessage:
                                  'Could not update this driver right now.',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppBtn(
                            label: 'Delete',
                            small: true,
                            outline: true,
                            onTap: () => AppErrorHandler.guard<void>(
                              context,
                              () async {
                                await _service.deleteUser(driver.id);
                                await _refresh();
                              },
                              fallbackMessage:
                                  'Could not delete this driver right now.',
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

  void _showDetails(BuildContext context, DriverUser driver) {
    showAdminInfoDialog(
      context: context,
      title: driver.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Email', value: driver.email),
          const SizedBox(height: 10),
          InfoRow(label: 'Phone', value: driver.phone),
          const SizedBox(height: 10),
          InfoRow(label: 'Bookings', value: '${driver.totalBookings}'),
          const SizedBox(height: 10),
          InfoRow(
            label: 'Wallet',
            value: '\$${driver.walletBalance.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 10),
          InfoRow(label: 'Status', value: driver.status.label),
        ],
      ),
    );
  }
}

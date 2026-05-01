import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';
import '_admin_shared.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminShell(
    title: 'Super Admin',
    showBack: false,
    child: SuperAdminDashboardView(),
  );
}

class SuperAdminDashboardView extends StatelessWidget {
  const SuperAdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final drivers = MockData.drivers;
    final workshops = MockData.adminWorkshops;
    final bookings = MockData.adminBookings;
    final revenue = MockData.totalRevenue;
    final pending = MockData.pendingApprovalsCount;
    final services = MockData.managedServices.where((item) => item.isEnabled).length;
    final logs = MockData.activityLogs.take(5).toList();

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ACard(
              glow: true,
              glowColor: AC.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platform command center',
                    style: TextStyle(fontSize: 13, color: AC.t3),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor the full Salahny marketplace in one place.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      GoldBadge('$services active services'),
                      const SizedBox(width: 8),
                      GoldBadge('$pending pending approvals'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                AdminKpiCard(
                  label: 'Total Drivers',
                  value: '${drivers.length}',
                  icon: Icons.people_alt_rounded,
                  color: AC.info,
                  delta: '${MockData.pendingDrivers.length} pending',
                ),
                AdminKpiCard(
                  label: 'Total Workshops',
                  value: '${workshops.length}',
                  icon: Icons.garage_rounded,
                  color: AC.gold,
                  delta: '${MockData.pendingWorkshops.length} pending',
                ),
                AdminKpiCard(
                  label: 'Total Bookings',
                  value: '${bookings.length}',
                  icon: Icons.receipt_long_rounded,
                  color: AC.success,
                  delta: '${bookings.where((b) => b.status == AdminBookingStatus.active).length} active',
                ),
                AdminKpiCard(
                  label: 'Revenue',
                  value: '\$$revenue',
                  icon: Icons.paid_rounded,
                  color: AC.red,
                  delta: 'Live gross',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SecHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            AdminActionTile(
              title: 'Pending Approvals',
              sub: 'Approve or reject new drivers and workshops',
              icon: Icons.verified_user_rounded,
              color: AC.warning,
              onTap: () => Navigator.pushNamed(context, R.saApprovals),
            ),
            const SizedBox(height: 10),
            AdminActionTile(
              title: 'Manage Services',
              sub: 'Update services, pricing, and visibility',
              icon: Icons.build_circle_rounded,
              color: AC.info,
              onTap: () => Navigator.pushNamed(context, R.saServices),
            ),
            const SizedBox(height: 10),
            AdminActionTile(
              title: 'Drivers & Workshops',
              sub: 'Open user management for both sides of the marketplace',
              icon: Icons.manage_accounts_rounded,
              color: AC.success,
              onTap: () => Navigator.pushNamed(context, R.saDrivers),
            ),
            const SizedBox(height: 10),
            AdminActionTile(
              title: 'Bookings & Packages',
              sub: 'Track live bookings and maintain subscription plans',
              icon: Icons.inventory_2_rounded,
              color: AC.red,
              onTap: () => Navigator.pushNamed(context, R.saBookings),
            ),
            const SizedBox(height: 10),
            AdminActionTile(
              title: 'Activity Logs',
              sub: 'Review platform actions and suspicious activity',
              icon: Icons.timeline_rounded,
              color: AC.gold,
              onTap: () => Navigator.pushNamed(context, R.saLogs),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _navPill(context, 'Workshops', R.saWorkshops),
                _navPill(context, 'Packages', R.saPackages),
                _navPill(context, 'Settings', R.saSettings),
              ],
            ),
            const SizedBox(height: 24),
            SecHeader(
              title: 'Recent Activity',
              action: 'View all',
              onAction: () => Navigator.pushNamed(context, R.saLogs),
            ),
            const SizedBox(height: 12),
            ...logs.map(
              (log) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AdminSectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AC.red.withOpacity(0.12),
                          borderRadius: Rd.mdA,
                        ),
                        child: const Icon(
                          Icons.shield_moon_rounded,
                          color: AC.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${log.actor} • ${log.action}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AC.t1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              log.details,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AC.t3,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 11, color: AC.t4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppBtn(
              label: 'Open Management Hub',
              onTap: () => Navigator.pushNamed(context, R.saDrivers),
              icon: const Icon(
                Icons.dashboard_customize_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      );
  }

  Widget _navPill(BuildContext context, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AC.s2,
          borderRadius: Rd.fullA,
          border: Border.all(color: AC.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AC.t2,
          ),
        ),
      ),
    );
  }
}

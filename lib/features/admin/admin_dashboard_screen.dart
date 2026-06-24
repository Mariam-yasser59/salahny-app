import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/app_cache.dart';
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
  const SuperAdminDashboardView({
    super.key,
    this.loading = false,
    this.loadError,
    this.onRetry,
  });

  final bool loading;
  final String? loadError;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AC.red));
    }

    if (loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AC.t2),
              ),
              const SizedBox(height: 12),
              AppBtn(label: 'Retry', onTap: () => onRetry?.call()),
            ],
          ),
        ),
      );
    }

    final drivers = AppCache.drivers;
    final workshops = AppCache.adminWorkshops;
    final bookings = AppCache.adminBookings;
    final revenue = AppCache.totalRevenue;
    final pending = AppCache.pendingApprovalsCount;
    final services = AppCache.managedServices
        .where((item) => item.isEnabled)
        .length;
    final logs = AppCache.activityLogs.take(5).toList();
    final analytics = AppCache.adminAnalytics;

    return RefreshIndicator(
      color: AC.red,
      onRefresh: onRetry ?? () async {},
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                  delta: '${AppCache.pendingDrivers.length} pending',
                ),
                AdminKpiCard(
                  label: 'Total Workshops',
                  value: '${workshops.length}',
                  icon: Icons.garage_rounded,
                  color: AC.gold,
                  delta: '${AppCache.pendingWorkshops.length} pending',
                ),
                AdminKpiCard(
                  label: 'Total Bookings',
                  value: '${bookings.length}',
                  icon: Icons.receipt_long_rounded,
                  color: AC.success,
                  delta:
                      '${bookings.where((b) => b.status == AdminBookingStatus.active).length} active',
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
            const SecHeader(title: 'Live Analytics'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AdminKpiCard(
                    label: 'Subscribers',
                    value: '${analytics.activeSubscribers}',
                    icon: Icons.workspace_premium_rounded,
                    color: AC.purple,
                    delta: 'Active now',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminKpiCard(
                    label: 'Documents',
                    value: '${analytics.pendingDocuments}',
                    icon: Icons.fact_check_rounded,
                    color: AC.warning,
                    delta: 'Pending review',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bookings by status',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AC.t1),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: analytics.bookingsByStatus.entries
                        .map(
                          (entry) => GoldBadge('${entry.key}: ${entry.value}'),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _StatusBarChart(values: analytics.bookingsByStatus),
                ],
              ),
            ),
            if (analytics.topWorkshops.isNotEmpty) ...[
              const SizedBox(height: 12),
              ACard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top workshops',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AC.t1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...analytics.topWorkshops.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InfoRow(
                          label: item.name,
                          value: '\$${item.revenue.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              title: 'Emergency Requests',
              sub: 'Monitor roadside cases and assignments',
              icon: Icons.emergency_share_rounded,
              color: AC.warning,
              onTap: () => Navigator.pushNamed(context, R.saEmergency),
            ),
            const SizedBox(height: 10),
            AdminActionTile(
              title: 'Diagnostics',
              sub: 'Review driver AI scans and severity',
              icon: Icons.analytics_rounded,
              color: AC.info,
              onTap: () => Navigator.pushNamed(context, R.saDiagnostics),
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
                          color: AC.red.withValues(alpha: 0.12),
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

class _StatusBarChart extends StatelessWidget {
  const _StatusBarChart({required this.values});

  final Map<String, int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );
    if (values.isEmpty || maxValue == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: values.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: Rd.fullA,
                      child: LinearProgressIndicator(
                        value: entry.value / maxValue,
                        minHeight: 10,
                        backgroundColor: AC.s3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colorFor(entry.key),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Color _colorFor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AC.success;
      case 'cancelled':
      case 'rejected':
        return AC.error;
      case 'active':
      case 'accepted':
        return AC.info;
      default:
        return AC.warning;
    }
  }
}

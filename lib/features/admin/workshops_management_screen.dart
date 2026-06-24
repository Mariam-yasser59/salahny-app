import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/salahny_map.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class WorkshopsManagementScreen extends StatefulWidget {
  const WorkshopsManagementScreen({super.key});

  @override
  State<WorkshopsManagementScreen> createState() =>
      _WorkshopsManagementScreenState();
}

class _WorkshopsManagementScreenState extends State<WorkshopsManagementScreen> {
  String _query = '';
  final _service = AdminService();

  Future<void> _refresh() async {
    await _service.refreshWorkshops();
    await _service.refreshLogs();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = AppCache.adminWorkshops
        .where(
          (workshop) =>
              workshop.name.toLowerCase().contains(_query.toLowerCase()) ||
              workshop.specialty.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return AdminShell(
      title: 'Workshops',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: [
            AdminSearchBar(
              hint: 'Search workshops by name or specialty',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            ...items.map(
              (workshop) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminSectionCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AC.gold.withOpacity(0.12),
                              borderRadius: Rd.mdA,
                            ),
                            child: const Icon(
                              Icons.garage_rounded,
                              color: AC.gold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AC.t1,
                                        ),
                                      ),
                                    ),
                                    if (workshop.isVerified)
                                      const GoldBadge('Verified'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  workshop.specialty,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AC.t3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StatusChip(workshop.status.label),
                          const SizedBox(width: 8),
                          Text(
                            '${workshop.totalJobs} jobs',
                            style: const TextStyle(fontSize: 12, color: AC.t3),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _miniButton(
                            label: 'Details',
                            onTap: () => _showDetails(context, workshop),
                          ),
                          _miniButton(
                            label: 'Message',
                            onTap: () => Navigator.pushNamed(
                              context,
                              R.saWorkshopChat,
                              arguments: {
                                'workshopId': workshop.id,
                                'workshopName': workshop.name,
                              },
                            ),
                          ),
                          _miniButton(
                            label: workshop.isVerified ? 'Verified' : 'Verify',
                            onTap: workshop.isVerified
                                ? null
                                : () => AppErrorHandler.guard<void>(
                                    context,
                                    () async {
                                      await _service.updateWorkshop(
                                        id: workshop.id,
                                        isVerified: true,
                                        status:
                                            workshop.status ==
                                                    AdminAccountStatus
                                                        .pending ||
                                                workshop.status ==
                                                    AdminAccountStatus.rejected
                                            ? AdminAccountStatus.active
                                            : null,
                                      );
                                      await _refresh();
                                    },
                                    fallbackMessage:
                                        'Could not verify this workshop right now.',
                                  ),
                          ),
                          _miniButton(
                            label:
                                workshop.status == AdminAccountStatus.suspended
                                ? 'Activate'
                                : 'Suspend',
                            onTap: () => AppErrorHandler.guard<void>(
                              context,
                              () async {
                                await _service.updateWorkshop(
                                  id: workshop.id,
                                  status:
                                      workshop.status ==
                                          AdminAccountStatus.suspended
                                      ? AdminAccountStatus.active
                                      : AdminAccountStatus.suspended,
                                );
                                await _refresh();
                              },
                              fallbackMessage:
                                  'Could not update this workshop right now.',
                            ),
                          ),
                          _miniButton(
                            label: 'Delete',
                            onTap: () => AppErrorHandler.guard<void>(
                              context,
                              () async {
                                await _service.deleteWorkshop(workshop.id);
                                await _refresh();
                              },
                              fallbackMessage:
                                  'Could not delete this workshop right now.',
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
      ),
    );
  }

  Widget _miniButton({required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onTap == null ? AC.s3 : AC.s2,
          borderRadius: Rd.fullA,
          border: Border.all(color: AC.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: onTap == null ? AC.t4 : AC.t2,
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, WorkshopUser workshop) {
    showAdminInfoDialog(
      context: context,
      title: workshop.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRow(label: 'Email', value: workshop.email),
          const SizedBox(height: 10),
          InfoRow(label: 'Phone', value: workshop.phone),
          const SizedBox(height: 10),
          InfoRow(label: 'Address', value: workshop.address),
          const SizedBox(height: 10),
          if (workshop.latitude != null && workshop.longitude != null) ...[
            SalahnyMap(
              height: 180,
              markers: [
                SalahnyMapMarker(
                  id: workshop.id,
                  latitude: workshop.latitude!,
                  longitude: workshop.longitude!,
                  title: workshop.name,
                  snippet: workshop.address,
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          InfoRow(label: 'Revenue', value: '\$${workshop.revenue.toInt()}'),
          const SizedBox(height: 10),
          InfoRow(label: 'Status', value: workshop.status.label),
        ],
      ),
    );
  }
}

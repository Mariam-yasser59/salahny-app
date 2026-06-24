import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';
import '_admin_shared.dart';
import 'services/admin_service.dart';
import '../../shared/widgets/salahny_map.dart';

class EmergencyManagementScreen extends StatefulWidget {
  const EmergencyManagementScreen({super.key});
  @override
  State<EmergencyManagementScreen> createState() =>
      _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState extends State<EmergencyManagementScreen> {
  final _service = AdminService();
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppErrorHandler.guard(
      context,
      _service.getEmergencyRequests,
    );
    if (!mounted) return;
    setState(() {
      _items = items ?? const [];
      _loading = false;
    });
  }

  Future<void> _assign(String requestId) async {
    final workshopId = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        backgroundColor: AC.s1,
        title: const Text('Assign workshop'),
        children: AppCache.adminWorkshops
            .where((item) => item.isVerified)
            .map(
              (item) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, item.id),
                child: Text(item.name),
              ),
            )
            .toList(),
      ),
    );
    if (workshopId == null) return;
    await AppErrorHandler.guard<void>(
      context,
      () => _service.assignEmergencyWorkshop(requestId, workshopId),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Emergency Management',
    child: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final item = _items[index];
                final driver = item['driver'] as Map<String, dynamic>?;
                final workshop =
                    item['assignedWorkshop'] as Map<String, dynamic>?;
                return AdminSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['issueDescription']?.toString() ?? '',
                        style: const TextStyle(
                          color: AC.t1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${driver?['name'] ?? 'Unknown'} - ${driver?['phone'] ?? ''}',
                        style: const TextStyle(color: AC.t3),
                      ),
                      Text(
                        item['address']?.toString() ?? '',
                        style: const TextStyle(color: AC.t3),
                      ),
                      if (item['latitude'] != null &&
                          item['longitude'] != null) ...[
                        const SizedBox(height: 10),
                        SalahnyMap(
                          height: 160,
                          markers: [
                            SalahnyMapMarker(
                              id: item['id']?.toString() ?? '$index',
                              latitude: (item['latitude'] as num).toDouble(),
                              longitude: (item['longitude'] as num).toDouble(),
                              title:
                                  item['issueDescription']?.toString() ??
                                  'Emergency',
                            ),
                          ],
                        ),
                      ],
                      Text(
                        workshop == null
                            ? 'Unassigned'
                            : '${workshop['name']} - ${workshop['distanceKm'] ?? '-'} km',
                        style: const TextStyle(color: AC.t2),
                      ),
                      Row(
                        children: [
                          GoldBadge(item['status']?.toString() ?? ''),
                          const Spacer(),
                          TextButton(
                            onPressed: () =>
                                _assign(item['id']?.toString() ?? ''),
                            child: Text(
                              workshop == null ? 'Assign' : 'Reassign',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
  );
}

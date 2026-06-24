import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import '_admin_shared.dart';
import 'services/admin_service.dart';

class DiagnosticsManagementScreen extends StatefulWidget {
  const DiagnosticsManagementScreen({super.key});
  @override
  State<DiagnosticsManagementScreen> createState() =>
      _DiagnosticsManagementScreenState();
}

class _DiagnosticsManagementScreenState
    extends State<DiagnosticsManagementScreen> {
  final _service = AdminService();
  List<Map<String, dynamic>> _items = const [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppErrorHandler.guard(
      context,
      _service.getAdminDiagnostics,
    );
    if (!mounted) return;
    setState(() => _items = items ?? const []);
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Diagnostics',
    child: RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = _items[index];
          final driver = item['driver'] as Map<String, dynamic>?;
          return AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['summary']?.toString() ?? '',
                  style: const TextStyle(
                    color: AC.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  driver?['name']?.toString() ?? 'Unknown driver',
                  style: const TextStyle(color: AC.t3),
                ),
                const SizedBox(height: 8),
                GoldBadge(
                  '${item['severity'] ?? ''} - ${item['status'] ?? ''}',
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

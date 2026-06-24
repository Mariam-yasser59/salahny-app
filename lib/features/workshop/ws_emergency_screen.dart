import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '_ws_shared.dart';
import 'services/workshop_emergency_service.dart';

class WsEmergencyScreen extends StatefulWidget {
  const WsEmergencyScreen({super.key});
  @override
  State<WsEmergencyScreen> createState() => _WsEmergencyScreenState();
}

class _WsEmergencyScreenState extends State<WsEmergencyScreen> {
  final _service = WorkshopEmergencyService();
  List<EmergencyRequestModel> _items = const [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppErrorHandler.guard(context, _service.getAssigned);
    if (!mounted) return;
    setState(() => _items = items ?? const []);
  }

  Future<void> _update(String id, String status) async {
    await AppErrorHandler.guard<void>(
      context,
      () => _service.update(id, status),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'Emergency Requests', showBack: true),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final item = _items[index];
          return WsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.issueDescription,
                  style: const TextStyle(
                    color: AC.t1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(item.address, style: const TextStyle(color: AC.t3)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => _update(item.id, 'accepted_by_workshop'),
                      child: const Text('Accept'),
                    ),
                    TextButton(
                      onPressed: () => _update(item.id, 'mechanic_on_the_way'),
                      child: const Text('On Way'),
                    ),
                    TextButton(
                      onPressed: () => _update(item.id, 'arrived'),
                      child: const Text('Arrived'),
                    ),
                    TextButton(
                      onPressed: () => _update(item.id, 'completed'),
                      child: const Text('Complete'),
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

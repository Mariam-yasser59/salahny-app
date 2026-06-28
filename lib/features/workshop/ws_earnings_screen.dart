import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '_ws_shared.dart';
import 'services/workshop_portal_service.dart';

class WsEarningsScreen extends StatefulWidget {
  const WsEarningsScreen({super.key});
  @override
  State<WsEarningsScreen> createState() => _WsEarningsScreenState();
}

class _WsEarningsScreenState extends State<WsEarningsScreen> {
  final _service = WorkshopPortalService();
  bool _loading = true;
  double _total = 0;
  double _available = 0;
  List<WorkshopEarningItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AppErrorHandler.guard(context, _service.getEarnings);
    if (!mounted || data == null) return;
    setState(() {
      _loading = false;
      _total = (data['total'] as num?)?.toDouble() ?? 0;
      _available = (data['availableBalance'] as num?)?.toDouble() ?? 0;
      _items = (data['items'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (item) => WorkshopEarningItem(
              id: item['id']?.toString() ?? '',
              bookingId: item['bookingId']?.toString() ?? '',
              driverName: item['driverName']?.toString() ?? '',
              serviceName: item['serviceName']?.toString() ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
              status: item['status']?.toString() ?? '',
              createdAt:
                  DateTime.tryParse(item['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'Earnings & Payouts', showBack: true),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WsCard(
                  glowColor: AC.gold,
                  child: Column(
                    children: [
                      const Text(
                        'Total Earnings',
                        style: TextStyle(color: AC.t3),
                      ),
                      Text(
                        'EGP ${_total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AC.gold,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Available balance: EGP ${_available.toStringAsFixed(0)}',
                        style: const TextStyle(color: AC.t2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Recent Earnings',
                  style: TextStyle(color: AC.t1, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ..._items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: WsCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.serviceName,
                                  style: const TextStyle(color: AC.t1),
                                ),
                                Text(
                                  item.driverName,
                                  style: const TextStyle(color: AC.t3),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'EGP ${item.amount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AC.gold,
                              fontWeight: FontWeight.w800,
                            ),
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

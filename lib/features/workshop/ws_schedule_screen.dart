import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/workshop_portal_service.dart';

class WsScheduleScreen extends StatefulWidget {
  const WsScheduleScreen({super.key});

  @override
  State<WsScheduleScreen> createState() => _WsScheduleScreenState();
}

class _WsScheduleScreenState extends State<WsScheduleScreen> {
  final _service = WorkshopPortalService();
  List<DateTime> _slots = const [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final slots = await _service.getSlots().catchError((_) => <DateTime>[]);
    if (!mounted) return;
    setState(() {
      _slots = slots;
      _loading = false;
    });
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    final slot = DateTime(day.year, day.month, day.day, time.hour, time.minute);
    final next = [..._slots, slot]..sort();
    await _save(next);
  }

  Future<void> _removeSlot(DateTime slot) async {
    await _save(_slots.where((item) => item != slot).toList());
  }

  Future<void> _save(List<DateTime> slots) async {
    setState(() => _saving = true);
    final saved = await _service.updateSlots(slots).catchError((_) => _slots);
    if (!mounted) return;
    setState(() {
      _slots = saved;
      _saving = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: SAppBar(
      title: 'Availability',
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _saving ? null : _load,
          icon: const Icon(Icons.refresh_rounded, color: AC.t1),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: AC.red,
      onPressed: _saving ? null : _addSlot,
      child: const Icon(Icons.add_rounded),
    ),
    body: RefreshIndicator(
      color: AC.red,
      onRefresh: _load,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.red))
          : _slots.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(
                  child: EmptyState(
                    icon: 'S',
                    title: 'No Available Slots',
                    sub: 'Add times drivers can book.',
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: _slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final slot = _slots[index];
                return ACard(
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: AC.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEE, MMM d - h:mm a').format(slot),
                          style: const TextStyle(
                            color: AC.t1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove slot',
                        onPressed: _saving ? null : () => _removeSlot(slot),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AC.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    ),
  );
}

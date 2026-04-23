// lib/features/workshop/ws_services_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';

class WsServicesScreen extends StatefulWidget {
  const WsServicesScreen({super.key});
  @override
  State<WsServicesScreen> createState() => _WsServicesScreenState();
}

class _WsServicesScreenState extends State<WsServicesScreen> {
  final List<WsServiceItem> _services = List.of(AppData.i.workshopServices);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: WsBar(
      title: 'My Services',
      showBack: true,
      actions: [
        GestureDetector(
          onTap: _showAddSheet,
          child: Container(
            width: 36, height: 36,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.smA),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
    body: _services.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: AC.s2, borderRadius: Rd.lgA, border: Border.all(color: AC.border)),
        child: const Icon(Icons.build_circle_outlined, size: 36, color: AC.t3),
      ),
      const SizedBox(height: 14),
      const Text('No services yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AC.t1)),
      const SizedBox(height: 6),
      const Text('Tap + to add your first service', style: TextStyle(fontSize: 13, color: AC.t3)),
    ]))
        : ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _services.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ServiceCard(
        service: _services[i],
        onDelete: () => setState(() => _services.removeAt(i)),
      ).animate().fadeIn(duration: 300.ms, delay: (i * 50).ms),
    ),
  );

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AC.s1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddServiceSheet(
        onAdd: (s) {
          setState(() => _services.add(s));
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── SERVICE CARD ────────────────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final WsServiceItem service;
  final VoidCallback onDelete;
  const _ServiceCard({required this.service, required this.onDelete});

  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.mdA),
        child: Center(child: Text(service.emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(service.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AC.t1)),
        const SizedBox(height: 3),
        Row(children: [
          const Icon(Icons.schedule_outlined, size: 12, color: AC.t3),
          const SizedBox(width: 4),
          Text('${service.durationMins} min', style: const TextStyle(fontSize: 12, color: AC.t3)),
        ]),
      ])),
      Text('\$${service.price.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AC.gold)),
      const SizedBox(width: 10),
      PopupMenuButton<String>(
        onSelected: (v) { if (v == 'delete') onDelete(); },
        icon: const Icon(Icons.more_vert_rounded, color: AC.t3, size: 20),
        color: AC.s2,
        shape: RoundedRectangleBorder(borderRadius: Rd.lgA),
        itemBuilder: (_) => [
          const PopupMenuItem(value: 'edit', child: Text('Edit service', style: TextStyle(color: AC.t1))),
          const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: AC.error))),
        ],
      ),
    ]),
  );
}

// ─── ADD SERVICE SHEET ───────────────────────────────────────────────────────
class _AddServiceSheet extends StatefulWidget {
  final void Function(WsServiceItem) onAdd;
  const _AddServiceSheet({required this.onAdd});
  @override
  State<_AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<_AddServiceSheet> {
  final _nameCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durCtrl   = TextEditingController();
  String _emoji    = '🔧';

  static const _emojis = ['🔧', '🛢️', '🛞', '🔋', '🚿', '❄️', '⚙️', '🪛', '🔍', '🛑'];

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _durCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 28),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 40, height: 4, decoration: BoxDecoration(color: AC.border2, borderRadius: Rd.fullA)),
      const SizedBox(height: 18),
      const Text('Add New Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AC.t1)),
      const SizedBox(height: 20),
      // Emoji picker
      SizedBox(height: 48,
        child: ListView(scrollDirection: Axis.horizontal, children: _emojis.map((e) =>
          GestureDetector(
            onTap: () => setState(() => _emoji = e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44, height: 44, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: _emoji == e ? AC.redGrad : null,
                color:    _emoji != e ? AC.s2 : null,
                borderRadius: Rd.smA,
                border: Border.all(color: _emoji == e ? AC.red : AC.border),
              ),
              child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
            ),
          )).toList()),
      ),
      const SizedBox(height: 16),
      _SField(ctrl: _nameCtrl, hint: 'Service name', icon: Icons.build_rounded),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _SField(ctrl: _priceCtrl, hint: 'Price (\$)', icon: Icons.attach_money_rounded, number: true)),
        const SizedBox(width: 10),
        Expanded(child: _SField(ctrl: _durCtrl,   hint: 'Duration (min)', icon: Icons.schedule_rounded, number: true)),
      ]),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity,
        child: WsBtn(label: 'Add Service', icon: Icons.add_rounded, onTap: () {
          final name  = _nameCtrl.text.trim();
          final price = double.tryParse(_priceCtrl.text) ?? 0;
          final dur   = int.tryParse(_durCtrl.text)      ?? 30;
          if (name.isEmpty) return;
          widget.onAdd(WsServiceItem(emoji: _emoji, name: name, durationMins: dur, price: price));
        }),
      ),
    ]),
  );
}

class _SField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool number;
  const _SField({required this.ctrl, required this.hint, required this.icon, this.number = false});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    style: const TextStyle(fontSize: 13, color: AC.t1),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AC.t3),
      prefixIcon: Icon(icon, size: 18, color: AC.t3),
    ),
  );
}
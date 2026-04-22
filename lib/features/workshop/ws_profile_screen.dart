// lib/features/workshop/ws_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'ws_earnings_screen.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/mock_data.dart';

class WsProfileScreen extends StatelessWidget {
  const WsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'Workshop Profile'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        // ── Identity Card ─────────────────────────────────────────────────
        WsCard(
          glowColor: AC.red,
          child: Column(children: [
            Row(children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.lgA),
                child: const Center(child: Text('PA',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ProTech Auto Center',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AC.t1, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                const Text('Multi-Service Workshop',
                    style: TextStyle(fontSize: 12, color: AC.t3)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AC.goldGrad,
                    borderRadius: Rd.fullA,
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF1A0A00), size: 12),
                    SizedBox(width: 4),
                    Text('Verified Partner', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF1A0A00))),
                  ]),
                ),
              ])),
            ]),
            const SizedBox(height: 18),
            const WsDiv(),
            const SizedBox(height: 14),
            const WsInfoRow(label: 'Phone',     value: '+1 (555) 234-5678'),
            const SizedBox(height: 8),
            const WsInfoRow(label: 'Address',   value: '142 Maple Ave, Downtown'),
            const SizedBox(height: 8),
            const WsInfoRow(label: 'Jobs Done', value: '1,820'),
            const SizedBox(height: 8),
            const WsInfoRow(label: 'Rating',    value: '4.9 ⭐', bold: true),
          ]),
        ).animate().fadeIn(duration: 350.ms),

        const SizedBox(height: 18),

        // ── Performance Stats ─────────────────────────────────────────────
        Row(children: [
          Expanded(child: _MiniStat('98%',   'Completion',     Icons.done_all_rounded,    AC.success)),
          const SizedBox(width: 10),
          Expanded(child: _MiniStat('38%',   'Repeat Clients', Icons.people_rounded,      AC.info)),
          const SizedBox(width: 10),
          Expanded(child: _MiniStat('8 min', 'Avg Response',   Icons.speed_rounded,       AC.warning)),
        ]).animate().fadeIn(duration: 350.ms, delay: 80.ms),

        const SizedBox(height: 24),

        // ── Services ──────────────────────────────────────────────────────
        const _SecLabel('Services Offered'),
        const SizedBox(height: 12),
        WsCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: WsMock.services.asMap().entries.map((e) {
            final s    = e.value;
            final last = e.key == WsMock.services.length - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.t1)),
                    Text('${s.durationMins} min', style: const TextStyle(fontSize: 11, color: AC.t3)),
                  ])),
                  Text('\$${s.price.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AC.gold)),
                ]),
              ),
              if (!last) const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: WsDiv()),
            ]);
          }).toList()),
        ).animate().fadeIn(duration: 350.ms, delay: 140.ms),

        const SizedBox(height: 22),

        // ── Quick Action Tiles ────────────────────────────────────────────
        Row(children: [
          Expanded(child: _ActionTile(Icons.payments_rounded,  'Earnings', AC.gold,    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WsEarningsScreen())))),
          const SizedBox(width: 12),
          Expanded(child: _ActionTile(Icons.star_rounded,       'Reviews',  AC.warning, () {})),
        ]).animate().fadeIn(duration: 350.ms, delay: 200.ms),

        const SizedBox(height: 24),

        // ── Actions ───────────────────────────────────────────────────────
        WsBtn(label: 'Edit Profile', outline: true, icon: Icons.edit_rounded, onTap: () {})
            .animate().fadeIn(duration: 350.ms, delay: 260.ms),
        const SizedBox(height: 12),
        WsBtn(
          label: 'Sign Out',
          outline: true,
          icon: Icons.logout_rounded,
          onTap: () async {
            await MockData.logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, R.roleSelect, (_) => false);
            }
          },
        ).animate().fadeIn(duration: 350.ms, delay: 300.ms),
      ],
    ),
  );
}

class _SecLabel extends StatelessWidget {
  final String t;
  const _SecLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AC.t1, letterSpacing: -0.2));
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _MiniStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: Rd.lgA,
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AC.t3)),
    ]),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: Rd.lgA,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    ),
  );
}
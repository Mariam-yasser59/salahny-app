// lib/features/workshop/ws_earnings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';

class WsEarningsScreen extends StatelessWidget {
  const WsEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = AppData.i.workshopProfile;
    final jobs = AppData.i.workshopBookings;
    final completedJobs = jobs.where((b) => b.status == RequestStatus.completed).length;
    final totalJobsValue = jobs.fold(0.0, (sum, b) => sum + b.price);
    final avgJob = jobs.isEmpty ? 0 : (totalJobsValue / jobs.length).round();
    final latestPayout = AppData.i.workshopPayouts.isEmpty ? 0 : AppData.i.workshopPayouts.first.amount.toInt();

    return Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'Earnings & Payouts'),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      children: [
        // ── Monthly Hero ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: AC.redGrad,
            borderRadius: Rd.xlA,
            boxShadow: [BoxShadow(color: AC.red.withOpacity(0.3), blurRadius: 28, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            const Text('Total This Month', style: TextStyle(fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (b) => AC.goldGrad.createShader(b),
              child: Text('\$${profile.monthlyRevenue.toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5)),
            ),
            const SizedBox(height: 6),
            Text(profile.revenuePeriod, style: const TextStyle(fontSize: 13, color: Colors.white54)),
            const SizedBox(height: 20),
            Container(height: 0.5, color: Colors.white.withOpacity(0.18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HeroStat(label: 'Jobs Done', value: '$completedJobs'),
                const _VDiv(),
                _HeroStat(label: 'Avg / Job', value: '\$$avgJob'),
                const _VDiv(),
                _HeroStat(label: 'Rating', value: profile.rating.toStringAsFixed(1)),
              ],
            ),
          ]),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 24),

        // ── Quick Stats Grid ──────────────────────────────────────────────
        const _SecLabel('Quick Stats'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            WsStatTile(label: 'Today', value: '\$${totalJobsValue.toInt()}', icon: Icons.today_rounded, color: AC.success),
            WsStatTile(label: 'This Week', value: '\$$latestPayout', icon: Icons.date_range_rounded, color: AC.info),
            WsStatTile(label: 'Completed Jobs', value: '$completedJobs', icon: Icons.check_circle_rounded, color: AC.warning),
            WsStatTile(label: 'Repeat Clients', value: '${jobs.length * 8}%', icon: Icons.people_rounded, color: AC.red),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 80.ms),

        const SizedBox(height: 28),

        // ── Payouts ────────────────────────────────────────────────────────
        const _SecLabel('Recent Payouts'),
        const SizedBox(height: 12),
        ...AppData.i.workshopPayouts.asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _PayoutRow(e.value)
              .animate().fadeIn(duration: 350.ms, delay: (e.key * 60).ms),
        )),

        const SizedBox(height: 20),
        WsBtn(label: 'Request Payout', icon: Icons.account_balance_rounded, gold: true, onTap: () {}),
      ],
    ),
  );
  }
}

class _SecLabel extends StatelessWidget {
  final String t;
  const _SecLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AC.t1, letterSpacing: -0.2));
}

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
  ]);
}

class _VDiv extends StatelessWidget {
  const _VDiv();
  @override
  Widget build(BuildContext context) => Container(width: 0.5, height: 30, color: Colors.white.withOpacity(0.2));
}

class _PayoutRow extends StatelessWidget {
  final WsPayoutData p;
  const _PayoutRow(this.p);
  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AC.success.withOpacity(0.12), borderRadius: Rd.mdA, border: Border.all(color: AC.success.withOpacity(0.3))),
        child: const Icon(Icons.account_balance_rounded, color: AC.success, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.period, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.t1)),
        const SizedBox(height: 2),
        const Text('Bank Transfer', style: TextStyle(fontSize: 11, color: AC.t3)),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('\$${p.amount.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AC.gold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AC.success.withOpacity(0.12),
            borderRadius: Rd.fullA,
            border: Border.all(color: AC.success.withOpacity(0.3)),
          ),
          child: const Text('Paid', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.success)),
        ),
      ]),
    ]),
  );
}

// lib/features/workshop/ws_active_jobs_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';

class WsActiveJobsScreen extends StatefulWidget {
  const WsActiveJobsScreen({super.key});
  @override
  State<WsActiveJobsScreen> createState() => _WsActiveJobsScreenState();
}

class _WsActiveJobsScreenState extends State<WsActiveJobsScreen> {
  late List<_JobEntry> _jobs;

  @override
  void initState() {
    super.initState();
    _jobs = WsMock.bookings
        .where((b) => b.status == RequestStatus.inProgress || b.status == RequestStatus.repairInProgress)
        .map((b) => _JobEntry(b, b.progress))
        .toList();
  }

  void _markComplete(int i) => setState(() => _jobs[i] = _JobEntry(_jobs[i].b, 1.0));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: WsBar(
      title: 'Active Jobs',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AC.warning.withOpacity(0.12),
              borderRadius: Rd.fullA,
              border: Border.all(color: AC.warning.withOpacity(0.35)),
            ),
            child: Text('${_jobs.length} in progress',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.warning)),
          )),
        ),
      ],
    ),
    body: _jobs.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: AC.success.withOpacity(0.1), borderRadius: Rd.lgA, border: Border.all(color: AC.success.withOpacity(0.3))),
        child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: AC.success),
      ),
      const SizedBox(height: 14),
      const Text('All jobs complete!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AC.t1)),
      const SizedBox(height: 4),
      const Text('No active jobs right now', style: TextStyle(fontSize: 13, color: AC.t3)),
    ]))
        : ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: _jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) => _JobCard(
        entry: _jobs[i],
        onComplete: _jobs[i].progress < 1.0 ? () => _markComplete(i) : null,
      ).animate().fadeIn(duration: 350.ms, delay: (i * 70).ms),
    ),
  );
}

class _JobEntry {
  final WsBookingData b;
  final double progress;
  const _JobEntry(this.b, this.progress);
}

class _JobCard extends StatelessWidget {
  final _JobEntry entry;
  final VoidCallback? onComplete;
  const _JobCard({required this.entry, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final b    = entry.b;
    final pct  = (entry.progress * 100).toInt();
    final done = entry.progress >= 1.0;

    return WsCard(
      glowColor: done ? AC.success : null,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: done ? AC.goldGrad : AC.redGrad,
              borderRadius: Rd.mdA,
            ),
            child: Icon(done ? Icons.check_rounded : Icons.build_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.serviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AC.t1, letterSpacing: -0.2)),
            const SizedBox(height: 3),
            Text(b.vehicleInfo, style: const TextStyle(fontSize: 12, color: AC.t3)),
          ])),
          Text('\$${b.price.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AC.gold)),
        ]),

        const SizedBox(height: 14),

        // Customer strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: AC.bg, borderRadius: Rd.smA, border: Border.all(color: AC.border)),
          child: Row(children: [
            const Icon(Icons.person_outline_rounded, size: 13, color: AC.t3),
            const SizedBox(width: 6),
            Text(b.customerName, style: const TextStyle(fontSize: 12, color: AC.t2)),
            const SizedBox(width: 12),
            const Icon(Icons.schedule_rounded, size: 13, color: AC.t3),
            const SizedBox(width: 6),
            Text('${b.date} • ${b.time}', style: const TextStyle(fontSize: 12, color: AC.t2)),
          ]),
        ),

        const SizedBox(height: 14),

        // Progress
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AC.t2)),
          Text('$pct%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: done ? AC.success : AC.red)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: Rd.fullA,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: entry.progress),
            duration: 600.ms,
            curve: Curves.easeOut,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val, minHeight: 8,
              backgroundColor: AC.border,
              valueColor: AlwaysStoppedAnimation<Color>(done ? AC.success : AC.red),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Button
        SizedBox(
          width: double.infinity,
          child: done
              ? Container(
            height: 46,
            decoration: BoxDecoration(
              color: AC.success.withOpacity(0.12),
              borderRadius: Rd.mdA,
              border: Border.all(color: AC.success.withOpacity(0.35)),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, color: AC.success, size: 18),
              SizedBox(width: 8),
              Text('Completed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.success)),
            ]),
          )
              : WsBtn(label: 'Mark as Complete', icon: Icons.check_rounded, onTap: onComplete ?? () {}),
        ),
      ]),
    );
  }
}
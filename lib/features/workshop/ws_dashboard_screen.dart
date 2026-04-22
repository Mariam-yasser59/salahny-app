// lib/features/workshop/ws_dashboard_screen.dart
// Main workshop shell with dark bottom nav + Dashboard tab.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'ws_requests_screen.dart';
import 'ws_active_jobs_screen.dart';
import 'ws_diagnostics_screen.dart';
import 'ws_profile_screen.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';

class WsDashboardScreen extends StatefulWidget {
  const WsDashboardScreen({super.key});
  @override
  State<WsDashboardScreen> createState() => _WsDashboardScreenState();
}

class _WsDashboardScreenState extends State<WsDashboardScreen> {
  int _index = 0;

  late final List<Widget> _pages = const [
    _DashboardTab(),
    WsRequestsScreen(),
    WsActiveJobsScreen(),
    WsDiagnosticsScreen(),
    WsProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: WsBottomNav(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
    ),
  );
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final pending  = WsMock.bookings.where((b) => b.status == RequestStatus.pending).toList();
    final active   = WsMock.bookings.where((b) => b.status == RequestStatus.inProgress || b.status == RequestStatus.repairInProgress).toList();
    final today    = WsMock.bookings.where((b) => b.status != RequestStatus.cancelled).toList();

    return Scaffold(
      backgroundColor: AC.bg,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 210,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5C0F1F), AC.red, Color(0xFFD93344)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _WsGridPaint())),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: Rd.mdA),
                            child: const Icon(Icons.car_repair_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Good Morning 👋', style: TextStyle(fontSize: 12, color: Colors.white60)),
                            Text('ProTech Auto Center',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                          ])),
                          _HeaderBadge('4.9', Icons.star_rounded, const Color(0xFFD4A843)),
                          const SizedBox(width: 8),
                          _HeaderBadge('OPEN', Icons.circle, Colors.greenAccent),
                        ]),
                        const SizedBox(height: 16),
                        // Quick stats row
                        Row(children: [
                          _QuickStat('${today.length}', 'Jobs Today'),
                          const SizedBox(width: 10),
                          _QuickStat('${pending.length}', 'Pending'),
                          const SizedBox(width: 10),
                          _QuickStat('\$${today.fold(0.0, (s, b) => s + b.price).toInt()}', 'Revenue'),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Body Rounded Corner ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: AC.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(children: [
                    // Stat Grid
                    _SectionLabel("Today's Overview"),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12, crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        WsStatTile(label: 'Jobs Today',  value: '${today.length}', icon: Icons.build_rounded,        color: AC.red),
                        WsStatTile(label: 'Pending',     value: '${pending.length}', icon: Icons.hourglass_top_rounded, color: AC.warning),
                        WsStatTile(label: 'Revenue',     value: '\$${today.fold(0.0, (s, b) => s + b.price).toInt()}', icon: Icons.payments_rounded, color: AC.gold),
                        WsStatTile(label: 'Rating',      value: '4.9', icon: Icons.star_rounded,          color: AC.success),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    // Pending requests
                    _SectionLabel('New Requests (${pending.length})'),
                    const SizedBox(height: 12),
                    if (pending.isEmpty)
                      _DarkEmpty('No pending requests right now')
                    else
                      ...pending.take(3).toList().asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DashReqRow(e.value)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (e.key * 60).ms),
                      )),

                    const SizedBox(height: 24),

                    // Active jobs
                    _SectionLabel('Active Jobs (${active.length})'),
                    const SizedBox(height: 12),
                    if (active.isEmpty)
                      _DarkEmpty('No active jobs right now')
                    else
                      ...active.take(2).toList().asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DashJobRow(e.value)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (e.key * 70).ms),
                      )),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

class _HeaderBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _HeaderBadge(this.text, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: Rd.fullA),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: color),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
}

class _QuickStat extends StatelessWidget {
  final String val, lbl;
  const _QuickStat(this.val, this.lbl);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: Rd.mdA, border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Column(children: [
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(lbl, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ]),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AC.t1, letterSpacing: -0.2)),
  );
}

class _DarkEmpty extends StatelessWidget {
  final String msg;
  const _DarkEmpty(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AC.s2,
      borderRadius: Rd.lgA,
      border: Border.all(color: AC.border),
    ),
    child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AC.t3)),
  );
}

class _DashReqRow extends StatelessWidget {
  final WsBookingData b;
  const _DashReqRow(this.b);
  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Row(children: [
      const WsIconBox(Icons.person_rounded),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(b.serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AC.t1)),
        const SizedBox(height: 3),
        Text('${b.vehicleInfo} • ${b.time}', style: const TextStyle(fontSize: 12, color: AC.t3)),
      ])),
      WsChip(b.status),
    ]),
  );
}

class _DashJobRow extends StatelessWidget {
  final WsBookingData b;
  const _DashJobRow(this.b);
  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const WsIconBox(Icons.build_rounded),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AC.t1)),
          const SizedBox(height: 3),
          Text(b.vehicleInfo, style: const TextStyle(fontSize: 12, color: AC.t3)),
        ])),
        Text('\$${b.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AC.gold)),
      ]),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: Rd.fullA,
        child: LinearProgressIndicator(
          value: b.progress, minHeight: 6,
          backgroundColor: AC.border,
          valueColor: const AlwaysStoppedAnimation<Color>(AC.red),
        ),
      ),
      const SizedBox(height: 5),
      Text('${(b.progress * 100).toInt()}% complete', style: const TextStyle(fontSize: 11, color: AC.t3)),
    ]),
  );
}

// ─── GRID PAINTER ─────────────────────────────────────────────────────────────
class _WsGridPaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.06)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}
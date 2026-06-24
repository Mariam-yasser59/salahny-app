// lib/features/workshop/ws_dashboard_screen.dart
// Main workshop shell with dark bottom nav + Dashboard tab.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/workshop_portal_service.dart';
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
  final _service = WorkshopPortalService();
  bool _isRefreshing = false;

  List<Widget> get _pages => [
    _DashboardTab(
      onRefresh: _refreshPortal,
      isRefreshing: _isRefreshing,
    ),
    const WsRequestsScreen(),
    const WsActiveJobsScreen(),
    const WsDiagnosticsScreen(),
    const WsProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPortal();
  }

  Future<void> _loadPortal() async {
    try {
      await _service.syncDashboard();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to load dashboard data');
    }
  }

  Future<void> _refreshPortal() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await _service.syncDashboard();
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to refresh dashboard');
    } finally {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AC.error,
      ),
    );
  }

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
  final Future<void> Function() onRefresh;
  final bool isRefreshing;

  const _DashboardTab({
    required this.onRefresh,
    required this.isRefreshing,
  });

  @override
  Widget build(BuildContext context) {
    final profile = AppData.i.workshopProfile;

    final pending = AppData.i.workshopBookings
        .where((b) => b.status == RequestStatus.pending)
        .toList();

    final active = AppData.i.workshopBookings
        .where(
          (b) =>
      b.status == RequestStatus.accepted ||
          b.status == RequestStatus.inProgress ||
          b.status == RequestStatus.diagnosticsReady ||
          b.status == RequestStatus.repairInProgress,
    )
        .toList();

    final today = AppData.i.workshopBookings
        .where((b) => b.status != RequestStatus.cancelled)
        .toList();

    final revenue = today.fold<double>(0.0, (sum, b) => sum + b.price).toInt();

    return Scaffold(
      backgroundColor: AC.bg,
      body: RefreshIndicator(
        color: AC.red,
        backgroundColor: AC.s2,
        onRefresh: onRefresh,
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Container(
                      height: 210,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF5C0F1F),
                            AC.red,
                            Color(0xFFD93344),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: Rd.mdA,
                                  ),
                                  child: const Icon(
                                    Icons.car_repair_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Good Morning',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white60,
                                        ),
                                      ),
                                      Text(
                                        profile.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _HeaderBadge(
                                  profile.rating.toStringAsFixed(1),
                                  Icons.star_rounded,
                                  const Color(0xFFD4A843),
                                ),
                                const SizedBox(width: 8),
                                _HeaderBadge(
                                  profile.isOpen ? 'OPEN' : 'CLOSED',
                                  Icons.circle,
                                  profile.isOpen
                                      ? Colors.greenAccent
                                      : AC.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _QuickStat('${today.length}', 'Jobs Today'),
                                const SizedBox(width: 10),
                                _QuickStat('${pending.length}', 'Pending'),
                                const SizedBox(width: 10),
                                _QuickStat('\$$revenue', 'Revenue'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isRefreshing)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: AC.bg,
                    valueColor: AlwaysStoppedAnimation<Color>(AC.red),
                  ),
                ),

              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AC.bg,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        children: [
                          const _SectionLabel("Today's Overview"),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.55,
                            children: [
                              WsStatTile(
                                label: 'Jobs Today',
                                value: '${today.length}',
                                icon: Icons.build_rounded,
                                color: AC.red,
                              ),
                              WsStatTile(
                                label: 'Pending',
                                value: '${pending.length}',
                                icon: Icons.hourglass_top_rounded,
                                color: AC.warning,
                              ),
                              WsStatTile(
                                label: 'Revenue',
                                value: '\$$revenue',
                                icon: Icons.payments_rounded,
                                color: AC.gold,
                              ),
                              WsStatTile(
                                label: 'Rating',
                                value: profile.rating.toStringAsFixed(1),
                                icon: Icons.star_rounded,
                                color: AC.success,
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms),

                          const SizedBox(height: 28),

                          _SectionLabel('New Requests (${pending.length})'),
                          const SizedBox(height: 12),
                          if (pending.isEmpty)
                            const _DarkEmpty('No pending requests right now')
                          else
                            ...pending.take(3).toList().asMap().entries.map(
                                  (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child:
                                _DashReqRow(e.value).animate().fadeIn(
                                  duration: 350.ms,
                                  delay: (e.key * 60).ms,
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          _SectionLabel('Active Jobs (${active.length})'),
                          const SizedBox(height: 12),
                          if (active.isEmpty)
                            const _DarkEmpty('No active jobs right now')
                          else
                            ...active.take(2).toList().asMap().entries.map(
                                  (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child:
                                _DashJobRow(e.value).animate().fadeIn(
                                  duration: 350.ms,
                                  delay: (e.key * 70).ms,
                                ),
                              ),
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: Rd.fullA,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _QuickStat extends StatelessWidget {
  final String val;
  final String lbl;

  const _QuickStat(this.val, this.lbl);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: Rd.mdA,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            lbl,
            style: const TextStyle(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AC.t1,
        letterSpacing: -0.2,
      ),
    ),
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
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, color: AC.t3),
    ),
  );
}

class _DashReqRow extends StatelessWidget {
  final WsBookingData b;

  const _DashReqRow(this.b);

  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        const WsIconBox(Icons.person_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.serviceName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AC.t1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${b.vehicleInfo} • ${b.time}',
                style: const TextStyle(fontSize: 12, color: AC.t3),
              ),
            ],
          ),
        ),
        WsChip(b.status),
      ],
    ),
  );
}

class _DashJobRow extends StatelessWidget {
  final WsBookingData b;

  const _DashJobRow(this.b);

  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const WsIconBox(Icons.build_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.serviceName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    b.vehicleInfo,
                    style: const TextStyle(fontSize: 12, color: AC.t3),
                  ),
                ],
              ),
            ),
            Text(
              '\$${b.price.toInt()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AC.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: Rd.fullA,
          child: LinearProgressIndicator(
            value: b.progress,
            minHeight: 6,
            backgroundColor: AC.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AC.red),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${(b.progress * 100).toInt()}% complete',
          style: const TextStyle(fontSize: 11, color: AC.t3),
        ),
      ],
    ),
  );
}

// ─── GRID PAINTER ─────────────────────────────────────────────────────────────

class _WsGridPaint extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

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
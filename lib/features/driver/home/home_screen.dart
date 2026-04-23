import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/services/mock_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  int _tab = 0;
  late AnimationController _nav;

  @override
  void initState() {
    super.initState();
    _nav = AnimationController(vsync: this, duration: 300.ms);
    _nav.forward();
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  static const _tabs = [
    'Home',
    'Services',
    'Diagnostics',
    'Bookings',
    'Profile',
  ];

  static const _icons = [
    Icons.home_rounded,
    Icons.build_circle_rounded,
    Icons.radar_rounded,
    Icons.calendar_month_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: IndexedStack(
      index: _tab,
      children: const [
        _HomeTab(),
        _ServicesTab(),
        _DiagnosticsTab(),
        _BookingsTab(),
        _ProfileTab(),
      ],
    ),
    bottomNavigationBar: _NavBar(
      current: _tab,
      tabs: _tabs,
      icons: _icons,
      onTap: (i) {
        setState(() => _tab = i);
      },
    ),
  );
}

// ────────── HOME TAB ──────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final user = AppData.i.currentUser;
    final vehicle = AppData.i.vehicles;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            children: [
              Container(
                height: 265,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B0A12), AC.red, Color(0xFFD93344)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPaint(opacity: 0.09),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good morning, ${user.name.split(' ').first} 👋',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Let's check your car today",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, R.notifications),
                            child: Stack(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.14),
                                    borderRadius: Rd.mdA,
                                  ),
                                  child: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AC.gold,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: Rd.lgA,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${vehicle[0].make} ${vehicle[0].model}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${vehicle[0].year} • ${vehicle[0].plate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.speed_rounded,
                                        color: Colors.white54,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${vehicle[0].mileage} mi',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      const Icon(
                                        Icons.build_circle_outlined,
                                        color: Colors.white54,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '2 mo ago',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            HealthArc(value: vehicle[0].health.toDouble()),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -18),
            child: Container(
              decoration: const BoxDecoration(
                color: AC.bg,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                child: Column(
                  children: [
                    const SecHeader(title: 'Quick Actions'),
                    const SizedBox(height: 16),
                    _QuickGrid(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SecHeader(
                  title: 'Active Booking',
                  action: 'All',
                  onAction: () =>
                      Navigator.pushNamed(context, R.bookingTrack),
                ),
                const SizedBox(height: 14),
                const _ActiveBookingCard(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8),
            child: SecHeader(
              title: 'Workshops Near You',
              action: 'See All',
              onAction: () => Navigator.pushNamed(context, R.workshops),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: SizedBox(
            height: 195,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              scrollDirection: Axis.horizontal,
              itemCount: AppData.i.workshops.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) =>
                  _WorkshopMiniCard(w: AppData.i.workshops[i]),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: _AiBanner(),
          ),
        ),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  static const _actions = [
    _QA('Book Service', Icons.calendar_month_rounded, AC.red, R.bookService),
    _QA('Diagnostics', Icons.radar_rounded, AC.info, R.diagnostics),
    _QA('Workshops', Icons.location_on_rounded, AC.success, R.workshops),
    _QA('Emergency', Icons.emergency_share_rounded, AC.warning, R.emergency),
    _QA('Plans', Icons.workspace_premium_rounded, AC.gold, R.packages),
    _QA('AI Chat', Icons.smart_toy_outlined, Color(0xFFEC4899), R.aiChat),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.05,
    children: _actions.map((a) => _QATile(action: a)).toList(),
  );
}

class _QA {
  final String label, route;
  final IconData icon;
  final Color color;

  const _QA(this.label, this.icon, this.color, this.route);
}

class _QATile extends StatefulWidget {
  final _QA action;

  const _QATile({super.key, required this.action});

  @override
  State<_QATile> createState() => _QATileState();
}

class _QATileState extends State<_QATile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: 100.ms);
    _s = Tween(begin: 1.0, end: 0.92).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) {
      _c.reverse();
      Navigator.pushNamed(context, widget.action.route);
    },
    onTapCancel: () => _c.reverse(),
    child: AnimatedBuilder(
      animation: _s,
      builder: (_, child) =>
          Transform.scale(scale: _s.value, child: child),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.action.color.withOpacity(0.16),
              widget.action.color.withOpacity(0.05),
            ],
          ),
          borderRadius: Rd.lgA,
          border: Border.all(
            color: widget.action.color.withOpacity(0.22),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.action.color.withOpacity(0.14),
                borderRadius: Rd.mdA,
              ),
              child: Icon(
                widget.action.icon,
                color: widget.action.color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.action.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActiveBookingCard extends StatelessWidget {
  const _ActiveBookingCard();

  @override
  Widget build(BuildContext context) {
    final b = AppData.i.bookings;

    return ACard(
      glow: true,
      glowColor: AC.info,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  borderRadius: Rd.mdA,
                  boxShadow: [
                    BoxShadow(
                      color: AC.red.withOpacity(0.35),
                      blurRadius: 14,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.build_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b[0].serviceName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AC.t1,
                      ),
                    ),
                    Text(
                      b[0].workshopName,
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ],
                ),
              ),
              StatusChip(b[0].status),
            ],
          ),
          const SizedBox(height: 14),
          const Div(),
          const SizedBox(height: 14),
          Row(
            children: [
              _Chip(Icons.calendar_today_rounded, b[0].date),
              const SizedBox(width: 14),
              _Chip(Icons.access_time_rounded, b[0].time),
              const Spacer(),
              Text(
                '\$${b[0].price.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AC.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppBtn(
            label: 'Track Booking',
            small: true,
            onTap: () => Navigator.pushNamed(context, R.bookingTrack),
            icon: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: AC.t3),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AC.t3),
      ),
    ],
  );
}

class _WorkshopMiniCard extends StatelessWidget {
  final WorkshopModel w;

  const _WorkshopMiniCard({required this.w});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () =>
        Navigator.pushNamed(context, R.workshopDetail, arguments: w.id),
    child: Container(
      width: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
        ),
        borderRadius: Rd.lgA,
        border: Border.all(color: AC.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AC.redGrad,
                    borderRadius: Rd.mdA,
                  ),
                ),
                const Spacer(),
                if (w.isVerified)
                  const GoldBadge(
                    'Verified',
                    icon: Icons.verified_rounded,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              w.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AC.t1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              w.specialty,
              style: const TextStyle(fontSize: 11, color: AC.t3),
            ),
            const Spacer(),
            Row(
              children: [
                RatingStars(rating: w.rating),
                const SizedBox(width: 4),
                Text(
                  '${w.rating}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AC.gold,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.location_on_rounded,
                  size: 12,
                  color: AC.t3,
                ),
                Text(
                  '${w.distance} mi',
                  style: const TextStyle(fontSize: 11, color: AC.t3),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, R.aiChat),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A0A3A),
            const Color(0xFF0F1B40),
            AC.red.withOpacity(0.2),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: Rd.lgA,
        border: Border.all(
          color: const Color(0xFF4C2D8A).withOpacity(0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF7C3AED), AC.red],
              ),
              borderRadius: Rd.mdA,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withOpacity(0.4),
                  blurRadius: 18,
                )
              ],
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                GoldBadge('AI Powered'),
                SizedBox(height: 8),
                Text(
                  'Smart Car Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                Text(
                  'Ask anything about your vehicle',
                  style: TextStyle(fontSize: 12, color: AC.t3),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AC.t3,
            size: 14,
          ),
        ],
      ),
    ),
  );
}

// ────────── SERVICES TAB ──────────────────────────────────────────────────────
class _ServicesTab extends StatefulWidget {
  const _ServicesTab();

  @override
  State<_ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<_ServicesTab> {
  final _cats = [
    'All',
    'Maintenance',
    'Tires',
    'Inspection',
    'Cleaning',
    'Brakes',
    'HVAC',
    'Electrical'
  ];

  String _sel = 'All';

  List<ServiceModel> get _filtered => _sel == 'All'
      ? AppData.i.services
      : AppData.i.services.where((s) => s.category == _sel).toList();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 14,
          left: 24,
          right: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AC.t1,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _sel = _cats[i]),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: _sel == _cats[i] ? AC.redGrad : null,
                      color: _sel != _cats[i] ? AC.s2 : null,
                      borderRadius: Rd.fullA,
                      border: Border.all(
                        color: _sel == _cats[i] ? AC.red : AC.border,
                        width: 0.8,
                      ),
                      boxShadow: _sel == _cats[i]
                          ? [
                        BoxShadow(
                          color: AC.red.withOpacity(0.3),
                          blurRadius: 10,
                        )
                      ]
                          : null,
                    ),
                    child: Text(
                      _cats[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _sel == _cats[i] ? Colors.white : AC.t3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 100),
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.86,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _ServiceCard(svc: _filtered[i]),
        ),
      ),
    ],
  );
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel svc;

  const _ServiceCard({required this.svc});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () =>
        Navigator.pushNamed(context, R.bookService, arguments: svc.id),
    child: ACard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  borderRadius: Rd.mdA,
                  boxShadow: [
                    BoxShadow(
                      color: AC.red.withOpacity(0.3),
                      blurRadius: 14,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    svc.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              if (svc.isPopular) const GoldBadge('Hot'),
            ],
          ),
          const Spacer(),
          Text(
            svc.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AC.t1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            svc.description,
            style: const TextStyle(fontSize: 11, color: AC.t3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${svc.price.toInt()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AC.gold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  borderRadius: Rd.smA,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ────────── DIAGNOSTICS TAB ──────────────────────────────────────────────────
class _DiagnosticsTab extends StatefulWidget {
  const _DiagnosticsTab();

  @override
  State<_DiagnosticsTab> createState() => _DiagnosticsTabState();
}

class _DiagnosticsTabState extends State<_DiagnosticsTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _scan;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: 2000.ms);
  }

  @override
  void dispose() {
    _scan.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() => _scanning = true);
    _scan.repeat();
    Future.delayed(3000.ms, () {
      if (mounted) {
        setState(() => _scanning = false);
        _scan.stop();
        _scan.reset();
        Navigator.pushNamed(context, R.diagResult);
      }
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top + 20),
        const Text(
          'AI Diagnostics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AC.t1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'OBD-II powered real-time analysis',
          style: TextStyle(fontSize: 13, color: AC.t3),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _scan,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    ...List.generate(3, (i) {
                      final delay = i * 0.33;
                      final prog =
                      (_scan.value - delay).clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.55 + prog * 1.0,
                        child: Opacity(
                          opacity: (1 - prog) * 0.45,
                          child: Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _scanning ? AC.red : AC.border,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: _scanning
                      ? AC.redGrad
                      : const LinearGradient(
                    colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: _scanning
                      ? [
                    BoxShadow(
                      color: AC.red.withOpacity(0.55),
                      blurRadius: 36,
                    )
                  ]
                      : null,
                ),
                child: Icon(
                  Icons.radar_rounded,
                  color: _scanning ? Colors.white : AC.t3,
                  size: 56,
                ),
              )
                  .animate(target: _scanning ? 1 : 0)
                  .rotate(
                end: 1.0,
                duration: 2000.ms,
                curve: Curves.linear,
              ),
            ],
          ),
        ),
        Text(
          _scanning ? 'Scanning…' : 'Tap to scan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _scanning ? AC.red : AC.t2,
          ),
        ),
        const SizedBox(height: 28),
        AppBtn(
          label: _scanning ? 'Scanning...' : 'Start Diagnostics',
          loading: _scanning,
          onTap: _scanning ? null : _startScan,
          icon: _scanning
              ? null
              : const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 30),
        SecHeader(
          title: 'Last Scan',
          action: 'History',
          onAction: () => Navigator.pushNamed(context, R.diagHistory),
        ),
        const SizedBox(height: 14),
        _LastScanWidget(),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class _LastScanWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = AppData.i.diagnosticSummary;

    return ACard(
      glow: true,
      glowColor: AC.success,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AC.t1,
                      ),
                    ),
                    Text(
                      d.date,
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ],
                ),
              ),
              HealthArc(value: d.health.toDouble()),
            ],
          ),
          const SizedBox(height: 14),
          const Div(),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: d.vitals.entries.map((e) {
              final col = e.value >= 75
                  ? AC.success
                  : e.value >= 50
                  ? AC.warning
                  : AC.error;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: col.withOpacity(0.08),
                  borderRadius: Rd.smA,
                  border: Border.all(color: col.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(fontSize: 11, color: AC.t3),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${e.value.toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: col,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ────────── BOOKINGS TAB ──────────────────────────────────────────────────────
class _BookingsTab extends StatefulWidget {
  const _BookingsTab();

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  final _statuses = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 14,
          bottom: 0,
          left: 24,
          right: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Bookings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, R.bookService),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AC.redGrad,
                      borderRadius: Rd.fullA,
                    ),
                    child: const Text(
                      '+ New',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TabBar(
              controller: _tab,
              isScrollable: true,
              indicatorColor: AC.red,
              labelColor: AC.red,
              unselectedLabelColor: AC.t3,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: AC.border,
              tabs: _statuses.map((s) => Tab(text: s)).toList(),
            ),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tab,
          children: _statuses.map((s) {
            final list = s == 'All'
                ? AppData.i.bookings
                : AppData.i.bookings
                .where((b) => b.status == s)
                .toList();
            if (list.isEmpty) {
              return const EmptyState(
                icon: '📅',
                title: 'No Bookings',
                sub: 'Your bookings will appear here',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BookingTile(b: list[i]),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _BookingTile extends StatelessWidget {
  final BookingModel b;

  const _BookingTile({required this.b});

  @override
  Widget build(BuildContext context) => ACard(
    padding: const EdgeInsets.all(16),
    onTap: () => Navigator.pushNamed(context, R.bookingTrack),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AC.redGrad,
                borderRadius: Rd.mdA,
              ),
              child: const Icon(
                Icons.build_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    b.serviceName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AC.t1,
                    ),
                  ),
                  Text(
                    b.workshopName,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AC.t3,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(b.status),
          ],
        ),
        const SizedBox(height: 10),
        const Div(),
        const SizedBox(height: 10),
        Row(
          children: [
            _Chip2(Icons.calendar_today_rounded, b.date),
            const SizedBox(width: 12),
            _Chip2(Icons.access_time_rounded, b.time),
            const Spacer(),
            Text(
              '\$${b.price.toInt()}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AC.gold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Chip2 extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip2(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: AC.t3),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(fontSize: 11, color: AC.t3),
      ),
    ],
  );
}

// ────────── PROFILE TAB ──────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final user = AppData.i.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 20),
          ACard(
            glow: true,
            glowColor: AC.red,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AC.redGrad,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name[0],
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AC.t1,
                            ),
                          ),
                          Text(
                            user.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AC.t3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const GoldBadge(
                            'Premium Member',
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, R.editProfile),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AC.s3,
                          borderRadius: Rd.mdA,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: AC.t2,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Div(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatPill('${user.totalBookings}', 'Bookings', AC.info),
                    const SizedBox(width: 10),
                    _StatPill('${user.rating}', 'Rating', AC.gold),
                    const SizedBox(width: 10),
                    _StatPill(
                      '\$${user.walletBalance.toInt()}',
                      'Wallet',
                      AC.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _MenuGroup(
            'My Account',
            [
              _MI(Icons.directions_car_rounded, 'My Vehicles', R.vehicles),
              _MI(Icons.history_rounded, 'Booking History', R.bookingTrack),
              _MI(
                Icons.workspace_premium_rounded,
                'Subscription Plan',
                R.packages,
              ),
              _MI(
                Icons.notifications_outlined,
                'Notifications',
                R.notifications,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MenuGroup(
            'Support & Settings',
            [
              _MI(Icons.settings_outlined, 'Settings', R.settings),
              _MI(
                Icons.privacy_tip_outlined,
                'Privacy Policy',
                R.privacy,
              ),
              _MI(Icons.info_outline_rounded, 'About', R.about),
            ],
          ),
          const SizedBox(height: 14),
          ACard(
            padding: EdgeInsets.zero,
            child: ListTile(
              onTap: () async {
                await MockData.logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    R.roleSelect,
                        (_) => false,
                  );
                }
              },
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AC.error.withOpacity(0.12),
                  borderRadius: Rd.smA,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AC.error,
                  size: 20,
                ),
              ),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AC.error,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String val, lbl;
  final Color col;

  const _StatPill(this.val, this.lbl, this.col);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: col.withOpacity(0.08),
        borderRadius: Rd.mdA,
        border: Border.all(color: col.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: col,
            ),
          ),
          Text(
            lbl,
            style: const TextStyle(fontSize: 10, color: AC.t3),
          ),
        ],
      ),
    ),
  );
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<_MI> items;

  const _MenuGroup(this.title, this.items);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AC.t3,
            letterSpacing: 0.5,
          ),
        ),
      ),
      ACard(
        padding: EdgeInsets.zero,
        child: Column(
          children: items.asMap().entries.map((e) {
            return Column(
              children: [
                ListTile(
                  onTap: () => Navigator.pushNamed(context, e.value.route),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AC.s3,
                      borderRadius: Rd.smA,
                    ),
                    child: Icon(
                      e.value.icon,
                      color: AC.t2,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    e.value.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AC.t1,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: AC.t3,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                ),
                if (e.key < items.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Div(),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _MI {
  final IconData icon;
  final String title, route;

  const _MI(this.icon, this.title, this.route);
}

// ────────── NAV BAR ──────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int current;
  final List<String> tabs;
  final List<IconData> icons;
  final ValueChanged<int> onTap;

  const _NavBar({
    required this.current,
    required this.tabs,
    required this.icons,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 72 + MediaQuery.of(context).padding.bottom,
    decoration: BoxDecoration(
      color: AC.s1,
      border: const Border(
        top: BorderSide(color: AC.border, width: 0.5),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        tabs.length,
            (i) => _NavItem(
          icon: icons[i],
          label: tabs[i],
          active: i == current,
          onTap: () => onTap(i),
        ),
      ),
    ),
  );
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: 200.ms);
    _s = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _c, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _c.forward().then((_) => _c.reverse());
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: widget.onTap,
    child: AnimatedBuilder(
      animation: _s,
      builder: (_, child) =>
          Transform.scale(scale: _s.value, child: child),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: 250.ms,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: widget.active ? AC.redGrad : null,
                borderRadius: Rd.smA,
                boxShadow: widget.active
                    ? [
                  BoxShadow(
                    color: AC.red.withOpacity(0.4),
                    blurRadius: 10,
                  )
                ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                color: widget.active ? Colors.white : AC.t3,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.active ? AC.red : AC.t3,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GridPaint extends CustomPainter {
  final double opacity;

  const _GridPaint({required this.opacity});

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 0.5;

    for (double x = 0; x < s.width; x += 30) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (double y = 0; y < s.height; y += 30) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// lib/features/workshop/_ws_shared.dart
// ─────────────────────────────────────────────────────────────────────────────
// Dark premium design tokens, shared widgets and mock re-exports for the
// Workshop module. All WsColor values are mapped to AC dark palette.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';

export '../../shared/models/models.dart'
    show WsBookingData, WsServiceItem, WsPayoutData, WsMock, RequestStatus;
export '../../shared/services/mock_data.dart'
    show AppData, AppDataSource, WorkshopProfileData;

// ══════════════════════════════════════════════════════════════════════════════
// DARK WORKSHOP COLORS
// ══════════════════════════════════════════════════════════════════════════════

class WsColor {
  WsColor._();

  static const bg = AC.bg;
  static const surface = AC.s2;
  static const surface2 = AC.s1;
  static const card = AC.s2;

  static const burgundy = AC.red;
  static const burgundyDark = AC.redDark;

  static const gold = AC.gold;
  static const goldLight = AC.goldLight;

  static const success = AC.success;
  static const successDim = Color(0xFF14532D);
  static const warning = AC.warning;
  static const warningDim = Color(0xFF78350F);
  static const info = AC.info;
  static const infoDim = Color(0xFF1E3A5F);
  static const error = AC.error;
  static const errorDim = Color(0xFF7F1D1D);

  static const t1 = AC.t1;
  static const t2 = AC.t2;
  static const t3 = AC.t3;
  static const t4 = AC.t4;

  static const border = AC.border;
  static const border2 = AC.border2;

  static const LinearGradient redGrad = AC.redGrad;
  static const LinearGradient goldGrad = AC.goldGrad;
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

class WsBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const WsBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => Container(
    height: 60 + MediaQuery.of(context).padding.top,
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
    decoration: const BoxDecoration(
      color: AC.s1,
      border: Border(
        bottom: BorderSide(color: AC.border, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        showBack
            ? GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 56,
            height: 60,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AC.t1,
            ),
          ),
        )
            : const SizedBox(width: 20),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AC.t1,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    ),
  );
}

class WsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;
  final VoidCallback? onTap;

  const WsCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Rd.lgA,
        border: Border.all(
          color: glowColor != null ? glowColor!.withOpacity(0.35) : AC.border,
          width: glowColor != null ? 1.2 : 0.8,
        ),
        boxShadow: glowColor != null
            ? [
          BoxShadow(
            color: glowColor!.withOpacity(0.22),
            blurRadius: 18,
            spreadRadius: -3,
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );

    return onTap != null
        ? GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    )
        : card;
  }
}

class WsBtn extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool outline;
  final bool gold;
  final bool small;
  final IconData? icon;

  const WsBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.outline = false,
    this.gold = false,
    this.small = false,
    this.icon,
  });

  @override
  State<WsBtn> createState() => _WsBtnState();
}

class _WsBtnState extends State<WsBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: 100.ms);
    _s = Tween(begin: 1.0, end: 0.94).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.small ? 42.0 : 52.0;
    final fs = widget.small ? 13.0 : 14.5;

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: widget.outline
            ? Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: Rd.mdA,
            border: Border.all(
              color: widget.gold ? AC.gold : AC.red,
              width: 1.3,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.gold ? AC.gold : AC.red,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.w600,
                    color: widget.gold ? AC.gold : AC.red,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        )
            : Container(
          height: h,
          decoration: BoxDecoration(
            gradient: widget.gold ? AC.goldGrad : AC.redGrad,
            borderRadius: Rd.mdA,
            boxShadow: [
              BoxShadow(
                color:
                (widget.gold ? AC.gold : AC.red).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: fs,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WsChip extends StatelessWidget {
  final RequestStatus status;

  const WsChip(this.status, {super.key});

  Color get _bg {
    switch (status) {
      case RequestStatus.accepted:
        return AC.success.withOpacity(0.12);
      case RequestStatus.inProgress:
        return AC.warning.withOpacity(0.12);
      case RequestStatus.repairInProgress:
        return AC.warning.withOpacity(0.12);
      case RequestStatus.completed:
        return AC.info.withOpacity(0.12);
      case RequestStatus.diagnosticsReady:
        return AC.purple.withOpacity(0.12);
      case RequestStatus.cancelled:
        return AC.error.withOpacity(0.12);
      case RequestStatus.pending:
        return AC.red.withOpacity(0.10);
    }
  }

  Color get _fg {
    switch (status) {
      case RequestStatus.accepted:
        return AC.success;
      case RequestStatus.inProgress:
        return AC.warning;
      case RequestStatus.repairInProgress:
        return AC.warning;
      case RequestStatus.completed:
        return AC.info;
      case RequestStatus.diagnosticsReady:
        return AC.purple;
      case RequestStatus.cancelled:
        return AC.error;
      case RequestStatus.pending:
        return AC.red;
    }
  }

  String get _label => RequestStatus.label(status);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: Rd.fullA,
      border: Border.all(color: _fg.withOpacity(0.35), width: 0.8),
    ),
    child: Text(
      _label,
      style: TextStyle(
        color: _fg,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
}

class WsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const WsInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: WsColor.t3),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: WsColor.t1,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class WsDiv extends StatelessWidget {
  const WsDiv({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 0.5, color: AC.border);
}

class WsStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const WsStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
      ),
      borderRadius: Rd.lgA,
      border: Border.all(color: color.withOpacity(0.2), width: 0.8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: Rd.smA,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AC.t1,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AC.t3)),
      ],
    ),
  );
}

class WsIconBox extends StatelessWidget {
  final IconData icon;
  final double size;

  const WsIconBox(this.icon, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AC.redGrad,
      borderRadius: Rd.mdA,
    ),
    child: Icon(
      icon,
      color: Colors.white,
      size: size * 0.44,
    ),
  );
}

class WsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showDiagTab;

  const WsBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showDiagTab = true,
  });

  static const _items = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard'),
    (icon: Icons.inbox_rounded, label: 'Requests'),
    (icon: Icons.build_rounded, label: 'Jobs'),
    (icon: Icons.radar_rounded, label: 'Diagnose'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: AC.s1,
      border: Border(top: BorderSide(color: AC.border, width: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black54,
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: List.generate(_items.length, (i) {
            final sel = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: sel ? AC.redGrad : null,
                        borderRadius: Rd.smA,
                        boxShadow: sel
                            ? [
                          BoxShadow(
                            color: AC.red.withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ]
                            : null,
                      ),
                      child: Icon(
                        _items[i].icon,
                        size: 20,
                        color: sel ? Colors.white : AC.t3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _items[i].label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? AC.red : AC.t3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

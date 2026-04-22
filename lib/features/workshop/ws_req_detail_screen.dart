import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import 'ws_diagnostics_screen.dart';
import 'ws_chat_screen.dart';
import '../../core/theme/app_theme.dart';

class WsReqDetailScreen extends StatefulWidget {
  final WsBookingData booking;

  const WsReqDetailScreen({
    super.key,
    required this.booking,
  });

  @override
  State<WsReqDetailScreen> createState() => _WsReqDetailScreenState();
}

class _WsReqDetailScreenState extends State<WsReqDetailScreen> {
  late RequestStatus _status;

  @override
  void initState() {
    super.initState();
    _status = widget.booking.status;
  }

  void _accept() => setState(() => _status = RequestStatus.accepted);

  void _start() => setState(() => _status = RequestStatus.inProgress);

  void _markDiagnosticsReady() =>
      setState(() => _status = RequestStatus.diagnosticsReady);

  void _startRepair() =>
      setState(() => _status = RequestStatus.repairInProgress);

  void _complete() => setState(() => _status = RequestStatus.completed);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: WsBar(
      title: 'Request Details',
      showBack: true,
      actions: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WsChatScreen(
                bookingId: widget.booking.id,
                customerName: widget.booking.customerName,
              ),
            ),
          ),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AC.s2,
              borderRadius: Rd.smA,
              border: Border.all(color: AC.border),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AC.t2,
              size: 18,
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            children: [
              _StatusBanner(status: _status)
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 16),

              WsCard(
                glowColor: AC.warning,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const WsIconBox(
                          Icons.build_circle_rounded,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.serviceName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AC.t1,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              WsChip(_status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const WsDiv(),
                    const SizedBox(height: 14),
                    WsInfoRow(label: 'Date', value: widget.booking.date),
                    const SizedBox(height: 8),
                    WsInfoRow(label: 'Time', value: widget.booking.time),
                    const SizedBox(height: 8),
                    WsInfoRow(
                      label: 'Vehicle',
                      value: widget.booking.vehicleInfo,
                    ),
                    const SizedBox(height: 10),
                    const WsDiv(),
                    const SizedBox(height: 10),
                    WsInfoRow(
                      label: 'Total',
                      value: '\$${widget.booking.price.toInt()}',
                      bold: true,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 60.ms),

              const SizedBox(height: 14),

              WsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CUSTOMER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AC.t3,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AC.redGrad,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.booking.customerName.isNotEmpty
                                  ? widget.booking.customerName[0]
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.booking.customerName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AC.t1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.booking.customerPhone,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AC.t3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AC.success.withOpacity(0.12),
                            borderRadius: Rd.fullA,
                            border: Border.all(
                              color: AC.success.withOpacity(0.35),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: AC.success,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '2.4 km',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AC.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 120.ms),

              const SizedBox(height: 14),

              WsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVICE NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AC.t3,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Customer reported unusual engine behavior and requested a full inspection before proceeding with repair. Review diagnostics before finalizing the work order.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AC.t2,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 180.ms),

              const SizedBox(height: 14),

              if (_status == RequestStatus.inProgress ||
                  _status == RequestStatus.diagnosticsReady ||
                  _status == RequestStatus.repairInProgress ||
                  _status == RequestStatus.completed)
                WsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WORKFLOW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AC.t3,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StepTile(
                        title: 'Request Accepted',
                        done: _status.index >= RequestStatus.accepted.index,
                      ),
                      _StepTile(
                        title: 'Service Started',
                        done:
                        _status.index >= RequestStatus.inProgress.index,
                      ),
                      _StepTile(
                        title: 'Diagnostics Ready',
                        done: _status.index >=
                            RequestStatus.diagnosticsReady.index,
                      ),
                      _StepTile(
                        title: 'Repair In Progress',
                        done: _status.index >=
                            RequestStatus.repairInProgress.index,
                      ),
                      _StepTile(
                        title: 'Completed',
                        done:
                        _status.index >= RequestStatus.completed.index,
                        isLast: true,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: 240.ms),

              const SizedBox(height: 30),
            ],
          ),
        ),
        _ActionFooter(
          status: _status,
          onAccept: _accept,
          onStart: _start,
          onOpenDiagnostics: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WsDiagnosticsScreen(
                  linkedRequestId: widget.booking.id,
                ),
              ),
            );
            if (!mounted) return;
            _markDiagnosticsReady();
          },
          onStartRepair: _startRepair,
          onComplete: _complete,
        ),
      ],
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  final RequestStatus status;

  const _StatusBanner({required this.status});

  Color get _color {
    switch (status) {
      case RequestStatus.accepted:
        return AC.success;
      case RequestStatus.inProgress:
        return AC.warning;
      case RequestStatus.diagnosticsReady:
        return AC.purple;
      case RequestStatus.repairInProgress:
        return AC.warning;
      case RequestStatus.completed:
        return AC.info;
      case RequestStatus.cancelled:
        return AC.error;
      case RequestStatus.pending:
        return AC.red;
    }
  }

  IconData get _icon {
    switch (status) {
      case RequestStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case RequestStatus.inProgress:
        return Icons.autorenew_rounded;
      case RequestStatus.diagnosticsReady:
        return Icons.analytics_rounded;
      case RequestStatus.repairInProgress:
        return Icons.build_circle_outlined;
      case RequestStatus.completed:
        return Icons.task_alt_rounded;
      case RequestStatus.cancelled:
        return Icons.cancel_outlined;
      case RequestStatus.pending:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: Rd.lgA,
      border: Border.all(color: _color.withOpacity(0.35)),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.14),
            borderRadius: Rd.mdA,
          ),
          child: Icon(_icon, color: _color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Status: ${RequestStatus.label(status)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AC.t1,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StepTile extends StatelessWidget {
  final String title;
  final bool done;
  final bool isLast;

  const _StepTile({
    required this.title,
    required this.done,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AC.success : AC.s2,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? AC.success : AC.border,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : Icons.circle_outlined,
              size: 13,
              color: done ? Colors.white : AC.t3,
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 28,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: done ? AC.success.withOpacity(0.5) : AC.border,
            ),
        ],
      ),
      const SizedBox(width: 12),
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: done ? AC.t1 : AC.t3,
          ),
        ),
      ),
    ],
  );
}

class _ActionFooter extends StatelessWidget {
  final RequestStatus status;
  final VoidCallback onAccept;
  final VoidCallback onStart;
  final VoidCallback onOpenDiagnostics;
  final VoidCallback onStartRepair;
  final VoidCallback onComplete;

  const _ActionFooter({
    required this.status,
    required this.onAccept,
    required this.onStart,
    required this.onOpenDiagnostics,
    required this.onStartRepair,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> actions = [];

    if (status == RequestStatus.pending) {
      actions = [
        Expanded(
          child: _PrimaryBtn(
            label: 'Accept Request',
            icon: Icons.check_rounded,
            onTap: onAccept,
          ),
        ),
      ];
    } else if (status == RequestStatus.accepted) {
      actions = [
        Expanded(
          child: _OutlineBtn(
            label: 'Chat',
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PrimaryBtn(
            label: 'Start Service',
            icon: Icons.play_arrow_rounded,
            onTap: onStart,
          ),
        ),
      ];
    } else if (status == RequestStatus.inProgress) {
      actions = [
        Expanded(
          child: _PrimaryBtn(
            label: 'Run Diagnostics',
            icon: Icons.analytics_rounded,
            onTap: onOpenDiagnostics,
          ),
        ),
      ];
    } else if (status == RequestStatus.diagnosticsReady) {
      actions = [
        Expanded(
          child: _PrimaryBtn(
            label: 'Start Repair',
            icon: Icons.build_rounded,
            onTap: onStartRepair,
          ),
        ),
      ];
    } else if (status == RequestStatus.repairInProgress) {
      actions = [
        Expanded(
          child: _PrimaryBtn(
            label: 'Complete Job',
            icon: Icons.task_alt_rounded,
            onTap: onComplete,
          ),
        ),
      ];
    } else if (status == RequestStatus.completed) {
      actions = [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AC.success.withOpacity(0.12),
              borderRadius: Rd.mdA,
              border: Border.all(color: AC.success.withOpacity(0.35)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: AC.success, size: 18),
                SizedBox(width: 8),
                Text(
                  'Job Completed',
                  style: TextStyle(
                    color: AC.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: AC.s1,
        border: Border(top: BorderSide(color: AC.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: actions),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: AC.redGrad,
        borderRadius: Rd.mdA,
        boxShadow: [
          BoxShadow(
            color: AC.red.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: AC.s2,
        borderRadius: Rd.mdA,
        border: Border.all(color: AC.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AC.t2, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AC.t2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
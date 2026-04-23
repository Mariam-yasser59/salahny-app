import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class DiagHistoryScreen extends StatefulWidget {
  const DiagHistoryScreen({super.key});

  @override
  State<DiagHistoryScreen> createState() => _DiagHistoryScreenState();
}

class _DiagHistoryScreenState extends State<DiagHistoryScreen> {
  String _filter = 'All';
  final _filters = ['All', 'Healthy', 'Warning', 'Critical'];

  List<DiagnosticReport> get _filtered {
    if (_filter == 'All') return AppData.i.diagnosticHistory;
    return AppData.i.diagnosticHistory
        .where((r) => r.riskLevel.label == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const SAppBar(title: 'Diagnostics History'),
    body: Column(
      children: [
        Container(
          height: 48,
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _filter = _filters[i]),
              child: AnimatedContainer(
                duration: 220.ms,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  gradient: _filter == _filters[i] ? AC.redGrad : null,
                  color: _filter != _filters[i] ? AC.s2 : null,
                  borderRadius: Rd.fullA,
                  border: Border.all(
                    color: _filter == _filters[i] ? AC.red : AC.border,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _filter == _filters[i] ? Colors.white : AC.t3,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const EmptyState(
            icon: '🔍',
            title: 'No Records',
            sub: 'No diagnostic reports match this filter',
          )
              : ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _HistoryTile(report: _filtered[i])
                .animate()
                .fadeIn(duration: 350.ms, delay: (i * 60).ms)
                .slideY(begin: 0.2),
          ),
        ),
      ],
    ),
  );
}

class _HistoryTile extends StatelessWidget {
  final DiagnosticReport report;
  const _HistoryTile({required this.report});

  Color get _riskColor {
    switch (report.riskLevel) {
      case RiskLevel.healthy:
        return AC.success;
      case RiskLevel.critical:
        return AC.error;
      case RiskLevel.warning:
        return AC.warning;
    }
  }

  String get _riskLabel => report.riskLevel.label;

  IconData get _icon {
    switch (report.riskLevel) {
      case RiskLevel.healthy:
        return Icons.check_circle_rounded;
      case RiskLevel.critical:
        return Icons.error_rounded;
      case RiskLevel.warning:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pushNamed(context, R.diagResult),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Rd.lgA,
        border: Border.all(color: _riskColor.withOpacity(0.25), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _riskColor.withOpacity(0.12),
              borderRadius: Rd.mdA,
              border: Border.all(color: _riskColor.withOpacity(0.3)),
            ),
            child: Icon(_icon, color: _riskColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AC.t1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.date,
                  style: const TextStyle(fontSize: 12, color: AC.t3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.12),
                  borderRadius: Rd.fullA,
                  border: Border.all(color: _riskColor.withOpacity(0.3)),
                ),
                child: Text(
                  _riskLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _riskColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${report.health.toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ),
              const Text(
                'Health',
                style: TextStyle(fontSize: 10, color: AC.t3),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

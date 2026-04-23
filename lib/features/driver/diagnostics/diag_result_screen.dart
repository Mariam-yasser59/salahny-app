import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class DiagResultScreen extends StatelessWidget {
  const DiagResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final report = AppData.i.latestDiagnosticReport;
    final ai = report.aiPrediction;

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(
        title: 'AI Diagnostic Report',
        actions: [
          _BarAction(Icons.share_outlined, () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HealthCard(report: report)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3),
            const SizedBox(height: 20),
            if (ai != null) ...[
              _AiPredictionCard(ai: ai)
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 80.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 20),
            ],
            const _SectionLabel('Vehicle Vitals'),
            const SizedBox(height: 12),
            _VitalsGrid(vitals: report.vitals)
                .animate()
                .fadeIn(duration: 400.ms, delay: 140.ms),
            const SizedBox(height: 20),
            if (report.faultCodes.isNotEmpty) ...[
              _SectionLabel('OBD Fault Codes (${report.faultCodes.length})'),
              const SizedBox(height: 12),
              ...report.faultCodes.asMap().entries.map(
                    (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FaultCodeTile(code: e.value)
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (160 + e.key * 50).ms),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const _SectionLabel('Recommendations'),
            const SizedBox(height: 12),
            ACard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: report.recommendations
                    .asMap()
                    .entries
                    .map<Widget>(
                      (e) => Padding(
                    padding: EdgeInsets.only(
                      bottom: e.key < report.recommendations.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: AC.redGrad,
                            borderRadius: Rd.fullA,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AC.t2,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .toList(),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 220.ms),
            const SizedBox(height: 24),
            AppBtn(
              label: 'Book Service Now',
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 18,
              ),
              onTap: () => Navigator.pushNamed(context, R.bookService),
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 12),
            AppBtn(
              label: 'View History',
              outline: true,
              icon: const Icon(Icons.history_rounded, color: AC.red, size: 18),
              onTap: () => Navigator.pushNamed(context, R.diagHistory),
            ).animate().fadeIn(duration: 400.ms, delay: 360.ms),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BarAction(this.icon, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AC.s2,
        borderRadius: Rd.smA,
        border: Border.all(color: AC.border),
      ),
      child: Icon(icon, color: AC.t2, size: 18),
    ),
  );
}

class _HealthCard extends StatelessWidget {
  final DiagnosticReport report;
  const _HealthCard({required this.report});

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

  String get _riskLabel => report.riskLevel.toUpperCase();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_riskColor.withOpacity(0.18), AC.s2, AC.s1],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: Rd.lgA,
      border: Border.all(color: _riskColor.withOpacity(0.35)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.15),
                  borderRadius: Rd.fullA,
                  border: Border.all(color: _riskColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _riskColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _riskLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: _riskColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                report.summary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AC.t1,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: AC.t3),
                  const SizedBox(width: 5),
                  Text(
                    report.date,
                    style: const TextStyle(fontSize: 12, color: AC.t3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _GaugePainter(value: report.health, color: _riskColor),
      ],
    ),
  );
}

class _GaugePainter extends StatelessWidget {
  final double value;
  final Color color;
  const _GaugePainter({required this.value, required this.color});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ArcPaint(value: value, color: color),
    child: SizedBox(
      width: 110,
      height: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${value.toInt()}%',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Text('Health', style: TextStyle(fontSize: 10, color: AC.t3)),
          const SizedBox(height: 4),
        ],
      ),
    ),
  );
}

class _ArcPaint extends CustomPainter {
  final double value;
  final Color color;
  const _ArcPaint({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 4);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bg = Paint()
      ..color = AC.border
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fg = Paint()
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.25), color],
        startAngle: math.pi,
        endAngle: math.pi * 2,
      ).createShader(rect)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, math.pi, math.pi, false, bg);
    canvas.drawArc(rect, math.pi, math.pi * (value / 100), false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPaint oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}

class _AiPredictionCard extends StatelessWidget {
  final AIPrediction ai;
  const _AiPredictionCard({required this.ai});

  Color get _urgencyColor {
    switch (ai.urgency) {
      case RiskLevel.critical:
        return AC.error;
      case RiskLevel.warning:
        return AC.warning;
      case RiskLevel.healthy:
        return AC.success;
    }
  }

  @override
  Widget build(BuildContext context) => ACard(
    padding: const EdgeInsets.all(18),
    glow: true,
    glowColor: _urgencyColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), AC.red],
                ),
                borderRadius: Rd.mdA,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Prediction',
                    style: TextStyle(fontSize: 12, color: AC.t3),
                  ),
                  Text(
                    ai.issue,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AC.t1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _urgencyColor.withOpacity(0.12),
                borderRadius: Rd.fullA,
                border: Border.all(color: _urgencyColor.withOpacity(0.35)),
              ),
              child: Text(
                ai.urgency.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _urgencyColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Div(),
        const SizedBox(height: 14),
        Row(
          children: [
            _MiniInfo(
              title: 'Confidence',
              value: '${(ai.confidence * 100).toInt()}%',
              color: AC.gold,
            ),
            const SizedBox(width: 10),
            _MiniInfo(
              title: 'Repair',
              value: ai.repairCategory,
              color: AC.info,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          ai.recommendedFix,
          style: const TextStyle(
            fontSize: 13,
            color: AC.t2,
            height: 1.55,
          ),
        ),
      ],
    ),
  );
}

class _MiniInfo extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MiniInfo({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: Rd.mdA,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AC.t3)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _VitalsGrid extends StatelessWidget {
  final List<OBDVital> vitals;
  const _VitalsGrid({required this.vitals});

  Color _color(double v) {
    if (v >= 100) return AC.error;
    if (v >= 80) return AC.warning;
    return AC.success;
  }

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.45,
    children: vitals.map<Widget>((v) {
      final col = _color(v.value);
      return ACard(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${v.value.toStringAsFixed(v.value % 1 == 0 ? 0 : 1)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: col,
              ),
            ),
            Text(
              v.unit,
              style: TextStyle(fontSize: 10, color: col.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              v.key,
              style: const TextStyle(fontSize: 10, color: AC.t3),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList(),
  );
}

class _FaultCodeTile extends StatelessWidget {
  final OBDFaultCode code;
  const _FaultCodeTile({required this.code});

  Color get _c {
    switch (code.severity) {
      case RiskLevel.critical:
        return AC.error;
      case RiskLevel.warning:
        return AC.warning;
      case RiskLevel.healthy:
        return AC.success;
    }
  }

  @override
  Widget build(BuildContext context) => ACard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _c.withOpacity(0.12),
            borderRadius: Rd.mdA,
            border: Border.all(color: _c.withOpacity(0.3)),
          ),
          child: Icon(Icons.error_outline_rounded, color: _c, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                code.code,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                code.description,
                style: const TextStyle(fontSize: 12, color: AC.t3, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AC.t1,
    ),
  );
}
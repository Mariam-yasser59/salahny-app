import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';

class WsAiReportScreen extends StatelessWidget {
  final String? linkedRequestId;
  const WsAiReportScreen({super.key, this.linkedRequestId});

  @override
  Widget build(BuildContext context) {
    final report = DiagnosticReport.mock;
    final ai = report.aiPrediction!;

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: WsBar(
        title: 'AI Diagnostic Report',
        showBack: true,
        actions: [
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AC.s2,
                borderRadius: Rd.smA,
                border: Border.all(color: AC.border),
              ),
              child: const Icon(Icons.share_outlined, color: AC.t2, size: 18),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(report: report, ai: ai)
                      .animate()
                      .fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  _ConfidenceCard(confidence: ai.confidence)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 80.ms),
                  const SizedBox(height: 16),
                  const _SectionLabel('Technical Explanation'),
                  const SizedBox(height: 10),
                  WsCard(
                    child: Text(
                      ai.technicalNote,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AC.t2,
                        height: 1.6,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 140.ms),
                  const SizedBox(height: 16),
                  const _SectionLabel('Recommended Fix'),
                  const SizedBox(height: 10),
                  _RecommendedFixCard(ai: ai)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 16),
                  if (report.faultCodes.isNotEmpty) ...[
                    const _SectionLabel('OBD Fault Codes'),
                    const SizedBox(height: 10),
                    ...report.faultCodes.asMap().entries.map(
                          (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _FaultRow(code: e.value)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (220 + e.key * 50).ms),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const _SectionLabel('Vehicle Vitals'),
                  const SizedBox(height: 10),
                  _VitalsGrid(vitals: report.vitals)
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 300.ms),
                  const SizedBox(height: 16),
                  if (linkedRequestId != null)
                    _LinkedBanner(requestId: linkedRequestId!)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 360.ms),
                ],
              ),
            ),
          ),
          _ActionFooter(
            ai: ai,
            onComplete: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final DiagnosticReport report;
  final AIPrediction ai;
  const _SummaryCard({required this.report, required this.ai});

  Color get _urgColor {
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [_urgColor.withOpacity(0.16), AC.s2, AC.s1],
      ),
      borderRadius: Rd.lgA,
      border: Border.all(color: _urgColor.withOpacity(0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), AC.red],
                ),
                borderRadius: Rd.mdA,
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Analysis Complete',
                    style: TextStyle(fontSize: 13, color: AC.t3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ai.issue,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AC.t1,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatBubble(
              '${report.health.toInt()}%',
              'Health',
              report.health >= 80
                  ? AC.success
                  : report.health >= 60
                  ? AC.warning
                  : AC.error,
            ),
            const SizedBox(width: 10),
            _StatBubble(
              '${(ai.confidence * 100).toInt()}%',
              'Confidence',
              AC.gold,
            ),
            const SizedBox(width: 10),
            _StatBubble(ai.urgency.toUpperCase(), 'Urgency', _urgColor),
          ],
        ),
      ],
    ),
  );
}

class _StatBubble extends StatelessWidget {
  final String val;
  final String lbl;
  final Color color;
  const _StatBubble(this.val, this.lbl, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: Rd.mdA,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(lbl, style: const TextStyle(fontSize: 10, color: AC.t3)),
        ],
      ),
    ),
  );
}

class _ConfidenceCard extends StatelessWidget {
  final double confidence;
  const _ConfidenceCard({required this.confidence});

  @override
  Widget build(BuildContext context) => WsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI Prediction Confidence',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AC.t1,
              ),
            ),
            const Spacer(),
            Text(
              '${(confidence * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AC.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: Rd.fullA,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: confidence),
            duration: 800.ms,
            curve: Curves.easeOut,
            builder: (_, val, __) => LinearProgressIndicator(
              value: val,
              minHeight: 10,
              backgroundColor: AC.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AC.gold),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RecommendedFixCard extends StatelessWidget {
  final AIPrediction ai;
  const _RecommendedFixCard({required this.ai});

  @override
  Widget build(BuildContext context) => WsCard(
    glowColor: AC.info,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ai.recommendedFix,
          style: const TextStyle(fontSize: 13, color: AC.t2, height: 1.6),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AC.info.withOpacity(0.08),
            borderRadius: Rd.mdA,
            border: Border.all(color: AC.info.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.build_circle_outlined, color: AC.info, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ai.repairCategory,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AC.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FaultRow extends StatelessWidget {
  final OBDFaultCode code;
  const _FaultRow({required this.code});

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
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _c.withOpacity(0.12),
            borderRadius: Rd.mdA,
            border: Border.all(color: _c.withOpacity(0.3)),
          ),
          child: Icon(Icons.error_outline_rounded, color: _c, size: 20),
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
                style: const TextStyle(fontSize: 12, color: AC.t3),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VitalsGrid extends StatelessWidget {
  final List<OBDVital> vitals;
  const _VitalsGrid({required this.vitals});

  Color _col(double value) {
    if (value >= 100) return AC.error;
    if (value >= 80) return AC.warning;
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
      final c = _col(v.value);
      return WsCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${v.value.toStringAsFixed(v.value % 1 == 0 ? 0 : 1)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            Text(
              v.unit,
              style: TextStyle(fontSize: 9, color: c.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              v.key,
              style: const TextStyle(fontSize: 9, color: AC.t3),
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

class _LinkedBanner extends StatelessWidget {
  final String requestId;
  const _LinkedBanner({required this.requestId});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AC.purple.withOpacity(0.10),
      borderRadius: Rd.mdA,
      border: Border.all(color: AC.purple.withOpacity(0.28)),
    ),
    child: Row(
      children: [
        const Icon(Icons.link_rounded, color: AC.purple, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Linked to request #$requestId',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AC.purple,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionFooter extends StatelessWidget {
  final AIPrediction ai;
  final VoidCallback onComplete;
  const _ActionFooter({required this.ai, required this.onComplete});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    decoration: const BoxDecoration(
      color: AC.s1,
      border: Border(top: BorderSide(color: AC.border, width: 0.5)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          WsBtn(
            label: 'Create Repair Task',
            icon: Icons.build_rounded,
            onTap: onComplete,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WsBtn(
                  label: 'Send to Driver',
                  icon: Icons.send_rounded,
                  outline: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: WsBtn(
                  label: 'Done',
                  icon: Icons.check_rounded,
                  gold: true,
                  onTap: onComplete,
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: AC.t1,
    ),
  );
}
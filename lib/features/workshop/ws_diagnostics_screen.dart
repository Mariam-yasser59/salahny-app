// lib/features/workshop/ws_diagnostics_screen.dart
// Phase 7B: Full OBD/AI Diagnostics flow for workshop side

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import 'ws_ai_report_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';

class WsDiagnosticsScreen extends StatefulWidget {
  final String? linkedRequestId;
  const WsDiagnosticsScreen({super.key, this.linkedRequestId});
  @override
  State<WsDiagnosticsScreen> createState() => _WsDiagnosticsScreenState();
}

class _WsDiagnosticsScreenState extends State<WsDiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  int _source = -1; // 0=live, 1=upload, 2=manual
  bool _scanning = false;
  late AnimationController _scanAnim;

  // Manual entry controllers
  late final TextEditingController _rpmCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _mapCtrl;
  late final TextEditingController _mafCtrl;
  late final TextEditingController _o2Ctrl;
  late final TextEditingController _codesCtrl;

  @override
  void initState() {
    super.initState();
    final report = AppData.i.latestDiagnosticReport;
    String vital(String key, String fallback) {
      final match = report.vitals.where(
        (v) => v.key.toLowerCase().contains(key.toLowerCase()),
      );
      return match.isEmpty ? fallback : match.first.value.toString();
    }

    _rpmCtrl = TextEditingController(text: vital('RPM', ''));
    _tempCtrl = TextEditingController(text: vital('Coolant', ''));
    _mapCtrl = TextEditingController(text: vital('MAP', ''));
    _mafCtrl = TextEditingController(text: vital('MAF', ''));
    _o2Ctrl = TextEditingController(text: vital('O2', ''));
    _codesCtrl = TextEditingController(
      text: report.faultCodes.map((c) => c.code).join(', '),
    );
    _scanAnim = AnimationController(vsync: this, duration: 2200.ms);
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _rpmCtrl.dispose(); _tempCtrl.dispose(); _mapCtrl.dispose();
    _mafCtrl.dispose(); _o2Ctrl.dispose();  _codesCtrl.dispose();
    super.dispose();
  }

  void _runAnalysis() {
    setState(() => _scanning = true);
    _scanAnim.repeat();
    Future.delayed(3200.ms, () {
      if (!mounted) return;
      _scanAnim.stop(); _scanAnim.reset();
      setState(() => _scanning = false);
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => WsAiReportScreen(linkedRequestId: widget.linkedRequestId)));
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'OBD / AI Diagnostics', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────────────────────────────────
          _Header(linkedRequestId: widget.linkedRequestId)
              .animate().fadeIn(duration: 350.ms),
          const SizedBox(height: 24),

          // ─── Source Selection ────────────────────────────────────────────
          const _Label('Select Data Source'),
          const SizedBox(height: 12),
          _SourceGrid(selected: _source, onSelect: (i) => setState(() => _source = i))
              .animate().fadeIn(duration: 350.ms, delay: 80.ms),
          const SizedBox(height: 24),

          // ─── Source-Specific UI ──────────────────────────────────────────
          if (_source == 0) _LiveOBDPanel().animate().fadeIn(duration: 300.ms),
          if (_source == 1) _UploadPanel(onTap: _runAnalysis).animate().fadeIn(duration: 300.ms),
          if (_source == 2) _ManualPanel(
            rpmCtrl: _rpmCtrl, tempCtrl: _tempCtrl, mapCtrl: _mapCtrl,
            mafCtrl: _mafCtrl, o2Ctrl: _o2Ctrl,   codesCtrl: _codesCtrl,
          ).animate().fadeIn(duration: 300.ms),

          if (_source >= 0) ...[
            const SizedBox(height: 28),

            // ─── Scanning animation ──────────────────────────────────────
            if (_scanning) _ScanningOverlay(controller: _scanAnim)
                .animate().fadeIn(duration: 250.ms),

            if (!_scanning) AppBtn(
              label: _source == 1 ? 'Upload & Analyze' : 'Run AI Analysis',
              icon: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
              onTap: _runAnalysis,
            ).animate().fadeIn(duration: 300.ms),
          ],
        ],
      ),
    ),
  );
}

// ─── HEADER ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String? linkedRequestId;
  const _Header({this.linkedRequestId});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [const Color(0xFF7C3AED).withOpacity(0.2), AC.s2]),
      borderRadius: Rd.lgA,
      border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
    ),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), AC.red]),
          borderRadius: Rd.mdA,
        ),
        child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('AI-Powered Vehicle Diagnostics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.t1)),
        Text(
          linkedRequestId != null
              ? 'Linked to request #$linkedRequestId'
              : 'Select data source to begin analysis',
          style: const TextStyle(fontSize: 12, color: AC.t3),
        ),
      ])),
      const GoldBadge('AI Engine', icon: Icons.auto_awesome_rounded),
    ]),
  );
}

// ─── SOURCE GRID ──────────────────────────────────────────────────────────────
class _SourceGrid extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SourceGrid({required this.selected, required this.onSelect});

  static const _sources = [
    (icon: Icons.bluetooth_connected_rounded,  label: 'Live OBD',    sub: 'Connect OBD-II device',    color: AC.info),
    (icon: Icons.upload_file_rounded,          label: 'Upload File',  sub: 'CSV / JSON OBD log',       color: AC.success),
    (icon: Icons.edit_note_rounded,            label: 'Manual Entry', sub: 'Enter values manually',    color: AC.warning),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: _sources.asMap().entries.map((e) {
      final s    = e.value;
      final sel  = selected == e.key;
      return GestureDetector(
        onTap: () => onSelect(e.key),
        child: AnimatedContainer(
          duration: 220.ms,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(colors: [s.color.withOpacity(0.18), AC.s2])
                : const LinearGradient(colors: [Color(0xFF1E1E1E), Color(0xFF161616)]),
            borderRadius: Rd.lgA,
            border: Border.all(color: sel ? s.color.withOpacity(0.5) : AC.border, width: sel ? 1.2 : 0.8),
            boxShadow: sel ? [BoxShadow(color: s.color.withOpacity(0.2), blurRadius: 14)] : null,
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: s.color.withOpacity(0.14), borderRadius: Rd.mdA),
              child: Icon(s.icon, color: s.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sel ? s.color : AC.t1)),
              Text(s.sub, style: const TextStyle(fontSize: 12, color: AC.t3)),
            ])),
            AnimatedContainer(
              duration: 220.ms,
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? s.color : Colors.transparent,
                border: Border.all(color: sel ? s.color : AC.border2, width: 2),
              ),
              child: sel ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
          ]),
        ),
      );
    }).toList(),
  );
}

// ─── LIVE OBD PANEL ───────────────────────────────────────────────────────────
class _LiveOBDPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WsCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('OBD Connection Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AC.t1)),
      const SizedBox(height: 14),
      const WsDiv(),
      const SizedBox(height: 14),
      ...[
        ('Bluetooth',    'Connected',  true),
        ('OBD Adapter',  'ELM-327',    true),
        ('Protocol',     'ISO 15765',  true),
        ('Vehicle ECU',  'Responding', true),
        ('Live Data',    'Streaming',  true),
      ].map((row) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(
              color: row.$3 ? AC.success : AC.error, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(row.$1, style: const TextStyle(fontSize: 13, color: AC.t3)),
          const Spacer(),
          Text(row.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: row.$3 ? AC.success : AC.error)),
        ]),
      )),
    ]),
  );
}

// ─── UPLOAD PANEL ────────────────────────────────────────────────────────────
class _UploadPanel extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadPanel({required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AC.s2,
        borderRadius: Rd.lgA,
        border: Border.all(color: AC.success.withOpacity(0.3), width: 1.5),
      ),
      child: Column(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: AC.success.withOpacity(0.12), borderRadius: Rd.lgA, border: Border.all(color: AC.success.withOpacity(0.35))),
          child: const Icon(Icons.add_circle_outline_rounded, size: 30, color: AC.success),
        ),
        const SizedBox(height: 14),
        const Text('Tap to Select OBD File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.t1)),
        const SizedBox(height: 6),
        const Text('Supports .csv, .json, .txt OBD log formats', style: TextStyle(fontSize: 12, color: AC.t3), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ─── MANUAL PANEL ────────────────────────────────────────────────────────────
class _ManualPanel extends StatelessWidget {
  final TextEditingController rpmCtrl, tempCtrl, mapCtrl, mafCtrl, o2Ctrl, codesCtrl;
  const _ManualPanel({
    required this.rpmCtrl, required this.tempCtrl, required this.mapCtrl,
    required this.mafCtrl, required this.o2Ctrl,   required this.codesCtrl,
  });

  @override
  Widget build(BuildContext context) => WsCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('MANUAL OBD VALUES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.t3, letterSpacing: 1)),
      const SizedBox(height: 16),

      Row(children: [
        Expanded(child: _Field('RPM', 'e.g. 2200', rpmCtrl)),
        const SizedBox(width: 12),
        Expanded(child: _Field('Engine Temp (°C)', 'e.g. 91', tempCtrl)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Field('MAP (kPa)', 'e.g. 75', mapCtrl)),
        const SizedBox(width: 12),
        Expanded(child: _Field('MAF (g/s)', 'e.g. 14.2', mafCtrl)),
      ]),
      const SizedBox(height: 12),
      _Field('O2 Voltage (V)', 'e.g. 0.45', o2Ctrl),
      const SizedBox(height: 12),
      _Field('Fault Codes', 'e.g. P0420, P0171 (comma separated)', codesCtrl),
    ]),
  );
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  const _Field(this.label, this.hint, this.ctrl);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AC.t3)),
    const SizedBox(height: 6),
    TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.text,
      style: const TextStyle(fontSize: 13, color: AC.t1),
      decoration: InputDecoration(hintText: hint),
    ),
  ]);
}

// ─── SCANNING OVERLAY ────────────────────────────────────────────────────────
class _ScanningOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanningOverlay({required this.controller});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(children: [
      SizedBox(
        width: 160, height: 160,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Stack(alignment: Alignment.center, children: [
              ...List.generate(3, (i) {
                final delay = i * 0.33;
                final prog  = (controller.value - delay).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: 0.4 + prog * 0.9,
                  child: Opacity(opacity: (1 - prog) * 0.5,
                    child: Container(width: 160, height: 160,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        border: Border.all(color: AC.red, width: 1.5))),
                  ),
                );
              }),
            ]),
          ),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(gradient: AC.redGrad, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AC.red.withOpacity(0.55), blurRadius: 30)]),
            child: RotationTransition(
              turns: controller,
              child: const Icon(Icons.radar_rounded, color: Colors.white, size: 40),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Analyzing Vehicle Data…',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AC.red)),
      const SizedBox(height: 6),
      const Text('AI model is processing sensor readings', style: TextStyle(fontSize: 12, color: AC.t3)),
      const SizedBox(height: 24),
    ]),
  );
}

// ─── LABEL ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.t1, letterSpacing: -0.2));
}

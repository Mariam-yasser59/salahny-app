// lib/features/workshop/ws_diagnostics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import 'ws_ai_report_screen.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../features/driver/diagnostics/services/diagnostics_service.dart';
import '../../shared/widgets/app_widgets.dart';
import 'package:file_picker/file_picker.dart';

class WsDiagnosticsScreen extends StatefulWidget {
  final String? linkedRequestId;
  const WsDiagnosticsScreen({super.key, this.linkedRequestId});
  @override
  State<WsDiagnosticsScreen> createState() => _WsDiagnosticsScreenState();
}

class _WsDiagnosticsScreenState extends State<WsDiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  int _source = -1; // 0=upload, 1=manual
  bool _scanning = false;
  late AnimationController _scanAnim;
  final _diagnosticsService = DiagnosticsService();
  final _formKey = GlobalKey<FormState>();

  // ── Required ───────────────────────────────────────────────────────────────
  final _rpm = TextEditingController();
  final _coolant = TextEditingController();
  final _speed = TextEditingController();
  // ── Engine ─────────────────────────────────────────────────────────────────
  final _voltage = TextEditingController();
  final _runTime = TextEditingController();
  final _engineLoad = TextEditingController();
  final _throttle = TextEditingController();
  final _timingAdvance = TextEditingController();
  // ── Fuel System ────────────────────────────────────────────────────────────
  final _stFuelTrim = TextEditingController();
  final _ltFuelTrim = TextEditingController();
  final _fuelTank = TextEditingController();
  final _fuelAirRatio = TextEditingController();
  // ── Air / Pressure ─────────────────────────────────────────────────────────
  final _intakeManifoldPressure = TextEditingController();
  final _intakeAirTemp = TextEditingController();
  final _barometricPressure = TextEditingController();
  // ── Throttle / Pedal ───────────────────────────────────────────────────────
  final _absThrottleB = TextEditingController();
  final _relThrottlePos = TextEditingController();
  final _pedalD = TextEditingController();
  final _pedalE = TextEditingController();
  final _commandedThrottle = TextEditingController();
  // ── Catalyst ───────────────────────────────────────────────────────────────
  final _catTempS1 = TextEditingController();
  final _catTempS2 = TextEditingController();
  // ── Evaporative ────────────────────────────────────────────────────────────
  final _evapPurge = TextEditingController();
  final _codesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(vsync: this, duration: 2200.ms);

    // Pre-fill from the latest diagnostic report if available
    final report = AppData.i.latestDiagnosticReport;
    String vital(String key, String fallback) {
      final match = report.vitals.where(
        (v) => v.key.toLowerCase().contains(key.toLowerCase()),
      );
      return match.isEmpty ? fallback : match.first.value.toString();
    }

    _rpm.text = vital('RPM', '');
    _coolant.text = vital('COOLANT', '');
    _speed.text = vital('SPEED', '');
    _codesCtrl.text = report.faultCodes.map((c) => c.code).join(', ');
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    _rpm.dispose();
    _coolant.dispose();
    _speed.dispose();
    _voltage.dispose();
    _runTime.dispose();
    _engineLoad.dispose();
    _throttle.dispose();
    _timingAdvance.dispose();
    _stFuelTrim.dispose();
    _ltFuelTrim.dispose();
    _fuelTank.dispose();
    _fuelAirRatio.dispose();
    _intakeManifoldPressure.dispose();
    _intakeAirTemp.dispose();
    _barometricPressure.dispose();
    _absThrottleB.dispose();
    _relThrottlePos.dispose();
    _pedalD.dispose();
    _pedalE.dispose();
    _commandedThrottle.dispose();
    _catTempS1.dispose();
    _catTempS2.dispose();
    _evapPurge.dispose();
    _codesCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.linkedRequestId == null || widget.linkedRequestId!.isEmpty) {
      AppErrorHandler.showMessage(
        context,
        'Open diagnostics from a booking so the result can be linked correctly.',
      );
      return;
    }
    setState(() => _scanning = true);
    _scanAnim.repeat();
    final report = await AppErrorHandler.guard(
      context,
      () => _diagnosticsService.scanWorkshopBooking(
        bookingId: widget.linkedRequestId!,
        sensorReadings: _buildSensorReadings(),
        faultCodes: _codesCtrl.text
            .split(',')
            .map((c) => c.trim().toUpperCase())
            .where((c) => c.isNotEmpty)
            .toList(growable: false),
      ),
      fallbackMessage: 'AI diagnostics could not run right now.',
    );
    if (!mounted) return;
    _scanAnim.stop();
    _scanAnim.reset();
    setState(() => _scanning = false);
    if (report == null) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            WsAiReportScreen(linkedRequestId: widget.linkedRequestId),
      ),
    );
    if (!mounted || result == null) return;
    Navigator.pop(context, result);
  }

  Map<String, double> _buildSensorReadings() => {
    'ENGINE_RPM': double.parse(_rpm.text.trim()),
    'COOLANT_TEMPERATURE': double.parse(_coolant.text.trim()),
    'VEHICLE_SPEED': double.parse(_speed.text.trim()),
    'CONTROL_MODULE_VOLTAGE': double.parse(_voltage.text.trim()),
    'ENGINE_RUN_TIME': double.parse(_runTime.text.trim()),
    'ENGINE_LOAD': double.parse(_engineLoad.text.trim()),
    'THROTTLE': double.parse(_throttle.text.trim()),
    'TIMING_ADVANCE': double.parse(_timingAdvance.text.trim()),
    'SHORT_TERM_FUEL_TRIM_BANK_1': double.parse(_stFuelTrim.text.trim()),
    'LONG_TERM_FUEL_TRIM_BANK_1': double.parse(_ltFuelTrim.text.trim()),
    'FUEL_TANK': double.parse(_fuelTank.text.trim()),
    'FUEL_AIR_COMMANDED_EQUIV_RATIO': double.parse(_fuelAirRatio.text.trim()),
    'INTAKE_MANIFOLD_PRESSURE': double.parse(
      _intakeManifoldPressure.text.trim(),
    ),
    'INTAKE_AIR_TEMP': double.parse(_intakeAirTemp.text.trim()),
    'ABSOLUTE_BAROMETRIC_PRESSURE': double.parse(
      _barometricPressure.text.trim(),
    ),
    'ABSOLUTE_THROTTLE_B': double.parse(_absThrottleB.text.trim()),
    'RELATIVE_THROTTLE_POSITION': double.parse(_relThrottlePos.text.trim()),
    'PEDAL_D': double.parse(_pedalD.text.trim()),
    'PEDAL_E': double.parse(_pedalE.text.trim()),
    'COMMANDED_THROTTLE_ACTUATOR': double.parse(_commandedThrottle.text.trim()),
    'CATALYST_TEMPERATURE_BANK1_SENSOR1': double.parse(_catTempS1.text.trim()),
    'CATALYST_TEMPERATURE_BANK1_SENSOR2': double.parse(_catTempS2.text.trim()),
    'COMMANDED_EVAPORATIVE_PURGE': double.tryParse(_evapPurge.text.trim()) ?? 0,
  };

  Future<void> _uploadFile() async {
    if (widget.linkedRequestId == null || widget.linkedRequestId!.isEmpty) {
      AppErrorHandler.showMessage(
        context,
        'Open diagnostics from a booking first.',
      );
      return;
    }
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json'],
      withData: true,
    );
    if (!mounted) return;
    final file = picked?.files.firstOrNull;
    if (file == null) return;
    setState(() => _scanning = true);
    final report = await AppErrorHandler.guard(
      context,
      () => _diagnosticsService.uploadWorkshopObdFile(
        bookingId: widget.linkedRequestId!,
        file: file,
      ),
      fallbackMessage: 'Could not upload this OBD file.',
    );
    if (!mounted) return;
    _scanAnim.stop();
    _scanAnim.reset();
    setState(() => _scanning = false);
    if (report != null) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WsAiReportScreen(linkedRequestId: widget.linkedRequestId),
        ),
      );
      if (!mounted || result == null) return;
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const WsBar(title: 'OBD / AI Diagnostics', showBack: true),
    body: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              linkedRequestId: widget.linkedRequestId,
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 24),
            const _Label('Select Data Source'),
            const SizedBox(height: 12),
            _SourceGrid(
              selected: _source,
              onSelect: (i) => setState(() => _source = i),
            ).animate().fadeIn(duration: 350.ms, delay: 80.ms),
            const SizedBox(height: 24),
            if (_source == 0)
              _UploadPanel(
                onTap: _uploadFile,
              ).animate().fadeIn(duration: 300.ms),
            if (_source == 1)
              _ManualPanel(
                rpm: _rpm,
                coolant: _coolant,
                speed: _speed,
                voltage: _voltage,
                runTime: _runTime,
                engineLoad: _engineLoad,
                throttle: _throttle,
                timingAdvance: _timingAdvance,
                stFuelTrim: _stFuelTrim,
                ltFuelTrim: _ltFuelTrim,
                fuelTank: _fuelTank,
                fuelAirRatio: _fuelAirRatio,
                intakeManifoldPressure: _intakeManifoldPressure,
                intakeAirTemp: _intakeAirTemp,
                barometricPressure: _barometricPressure,
                absThrottleB: _absThrottleB,
                relThrottlePos: _relThrottlePos,
                pedalD: _pedalD,
                pedalE: _pedalE,
                commandedThrottle: _commandedThrottle,
                catTempS1: _catTempS1,
                catTempS2: _catTempS2,
                evapPurge: _evapPurge,
                codesCtrl: _codesCtrl,
              ).animate().fadeIn(duration: 300.ms),
            if (_source >= 0) ...[
              const SizedBox(height: 28),
              if (_scanning)
                _ScanningOverlay(
                  controller: _scanAnim,
                ).animate().fadeIn(duration: 250.ms),
              if (!_scanning && _source == 1)
                AppBtn(
                  label: 'Run AI Analysis',
                  icon: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onTap: _runAnalysis,
                ).animate().fadeIn(duration: 300.ms),
            ],
          ],
        ),
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
      gradient: LinearGradient(
        colors: [const Color(0xFF7C3AED).withValues(alpha: 0.2), AC.s2],
      ),
      borderRadius: Rd.lgA,
      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), AC.red]),
            borderRadius: Rd.mdA,
          ),
          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI-Powered Vehicle Diagnostics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AC.t1,
                ),
              ),
              Text(
                linkedRequestId != null
                    ? 'Linked to request #$linkedRequestId'
                    : 'Select data source to begin analysis',
                style: const TextStyle(fontSize: 12, color: AC.t3),
              ),
            ],
          ),
        ),
        const GoldBadge('AI Engine', icon: Icons.auto_awesome_rounded),
      ],
    ),
  );
}

// ─── SOURCE GRID ─────────────────────────────────────────────────────────────
class _SourceGrid extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _SourceGrid({required this.selected, required this.onSelect});

  static const _sources = [
    (
      icon: Icons.upload_file_rounded,
      label: 'Upload File',
      sub: 'CSV / JSON OBD log',
      color: AC.success,
    ),
    (
      icon: Icons.edit_note_rounded,
      label: 'Manual Entry',
      sub: 'Enter all 23 OBD values',
      color: AC.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: _sources.asMap().entries.map((e) {
      final s = e.value;
      final sel = selected == e.key;
      return GestureDetector(
        onTap: () => onSelect(e.key),
        child: AnimatedContainer(
          duration: 220.ms,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: sel
                ? LinearGradient(
                    colors: [s.color.withValues(alpha: 0.18), AC.s2],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
                  ),
            borderRadius: Rd.lgA,
            border: Border.all(
              color: sel ? s.color.withValues(alpha: 0.5) : AC.border,
              width: sel ? 1.2 : 0.8,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: s.color.withValues(alpha: 0.2),
                      blurRadius: 14,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.14),
                  borderRadius: Rd.mdA,
                ),
                child: Icon(s.icon, color: s.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: sel ? s.color : AC.t1,
                      ),
                    ),
                    Text(
                      s.sub,
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: 220.ms,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? s.color : Colors.transparent,
                  border: Border.all(
                    color: sel ? s.color : AC.border2,
                    width: 2,
                  ),
                ),
                child: sel
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      );
    }).toList(),
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
        border: Border.all(
          color: AC.success.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AC.success.withValues(alpha: 0.12),
              borderRadius: Rd.lgA,
              border: Border.all(color: AC.success.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              size: 30,
              color: AC.success,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tap to Select OBD File',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AC.t1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Supports .csv and .json OBD log formats',
            style: TextStyle(fontSize: 12, color: AC.t3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// ─── MANUAL PANEL — all 23 model features ────────────────────────────────────
class _ManualPanel extends StatelessWidget {
  final TextEditingController rpm, coolant, speed;
  final TextEditingController voltage,
      runTime,
      engineLoad,
      throttle,
      timingAdvance;
  final TextEditingController stFuelTrim, ltFuelTrim, fuelTank, fuelAirRatio;
  final TextEditingController intakeManifoldPressure,
      intakeAirTemp,
      barometricPressure;
  final TextEditingController absThrottleB,
      relThrottlePos,
      pedalD,
      pedalE,
      commandedThrottle;
  final TextEditingController catTempS1, catTempS2;
  final TextEditingController evapPurge, codesCtrl;

  const _ManualPanel({
    required this.rpm,
    required this.coolant,
    required this.speed,
    required this.voltage,
    required this.runTime,
    required this.engineLoad,
    required this.throttle,
    required this.timingAdvance,
    required this.stFuelTrim,
    required this.ltFuelTrim,
    required this.fuelTank,
    required this.fuelAirRatio,
    required this.intakeManifoldPressure,
    required this.intakeAirTemp,
    required this.barometricPressure,
    required this.absThrottleB,
    required this.relThrottlePos,
    required this.pedalD,
    required this.pedalE,
    required this.commandedThrottle,
    required this.catTempS1,
    required this.catTempS2,
    required this.evapPurge,
    required this.codesCtrl,
  });

  @override
  Widget build(BuildContext context) => WsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OBD-II SENSOR INPUTS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AC.t3,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 16),

        _GroupLabel('Required', AC.error),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Field('Engine RPM', 'e.g. 800', 'rpm', rpm)),
            const SizedBox(width: 12),
            Expanded(child: _Field('Coolant Temp', 'e.g. 90', '°C', coolant)),
          ],
        ),
        const SizedBox(height: 12),
        _Field('Vehicle Speed', 'e.g. 60', 'km/h', speed),
        const SizedBox(height: 16),

        _GroupLabel('Engine', AC.warning),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Field(
                'Control Module Voltage',
                'e.g. 14.2',
                'V',
                voltage,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field('Engine Run Time', 'e.g. 300', 's', runTime),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Field('Engine Load', 'e.g. 45', '%', engineLoad)),
            const SizedBox(width: 12),
            Expanded(
              child: _Field('Throttle Position', 'e.g. 20', '%', throttle),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Field('Timing Advance', 'e.g. 10', '°', timingAdvance),
        const SizedBox(height: 16),

        _GroupLabel('Fuel System', AC.gold),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Field(
                'Short-Term Fuel Trim B1',
                'e.g. -2.3',
                '%',
                stFuelTrim,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                'Long-Term Fuel Trim B1',
                'e.g. 1.5',
                '%',
                ltFuelTrim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Field('Fuel Tank Level', 'e.g. 65', '%', fuelTank),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                'Fuel/Air Equiv Ratio',
                'e.g. 1.00',
                'λ',
                fuelAirRatio,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _GroupLabel('Air & Pressure', AC.info),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Field(
                'Intake Manifold Pressure',
                'e.g. 101',
                'kPa',
                intakeManifoldPressure,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field('Intake Air Temp', 'e.g. 30', '°C', intakeAirTemp),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Field(
          'Absolute Barometric Pressure',
          'e.g. 101',
          'kPa',
          barometricPressure,
        ),
        const SizedBox(height: 16),

        _GroupLabel('Throttle & Pedal', AC.success),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Field(
                'Absolute Throttle B',
                'e.g. 18',
                '%',
                absThrottleB,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field(
                'Relative Throttle Pos',
                'e.g. 12',
                '%',
                relThrottlePos,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Field('Pedal Position D', 'e.g. 22', '%', pedalD)),
            const SizedBox(width: 12),
            Expanded(child: _Field('Pedal Position E', 'e.g. 22', '%', pedalE)),
          ],
        ),
        const SizedBox(height: 12),
        _Field(
          'Commanded Throttle Actuator',
          'e.g. 20',
          '%',
          commandedThrottle,
        ),
        const SizedBox(height: 16),

        _GroupLabel('Catalyst Temperature', AC.error),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Field('Catalyst Temp B1S1', 'e.g. 520', '°C', catTempS1),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Field('Catalyst Temp B1S2', 'e.g. 490', '°C', catTempS2),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _GroupLabel('Evaporative System', AC.success),
        const SizedBox(height: 10),
        _Field(
          'Commanded Evaporative Purge',
          'e.g. 50',
          '%',
          evapPurge,
          optional: true,
        ),
        const SizedBox(height: 16),

        _GroupLabel('DTC Fault Codes', AC.error),
        const SizedBox(height: 6),
        const Text(
          'Enter codes from your OBD scanner, separated by commas.',
          style: TextStyle(fontSize: 11, color: AC.t3, height: 1.5),
        ),
        const SizedBox(height: 10),
        AppField(
          label: 'Fault Codes (optional)',
          hint: 'P0300, P0420, U0100',
          ctrl: codesCtrl,
        ),
      ],
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupLabel(this.label, this.color);
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1.1,
        ),
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  final String label, hint, unit;
  final TextEditingController ctrl;
  final bool optional;
  const _Field(
    this.label,
    this.hint,
    this.unit,
    this.ctrl, {
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) => AppField(
    label: label,
    hint: hint,
    ctrl: ctrl,
    keyboard: const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    suffix: unit.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text(
              unit,
              style: const TextStyle(fontSize: 12, color: AC.t3),
            ),
          )
        : null,
    validator: (value) {
      final trimmed = (value ?? '').trim();
      if (optional && trimmed.isEmpty) return null;
      return double.tryParse(trimmed) == null ? 'Enter a number' : null;
    },
  );
}

// ─── SCANNING OVERLAY ────────────────────────────────────────────────────────
class _ScanningOverlay extends StatelessWidget {
  final AnimationController controller;
  const _ScanningOverlay({required this.controller});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: controller,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (i) {
                    final delay = i * 0.33;
                    final prog = (controller.value - delay).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.4 + prog * 0.9,
                      child: Opacity(
                        opacity: (1 - prog) * 0.5,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AC.red, width: 1.5),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AC.red.withValues(alpha: 0.55),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: RotationTransition(
                  turns: controller,
                  child: const Icon(
                    Icons.radar_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Analyzing Vehicle Data…',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AC.red,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'AI model is processing all 23 sensor readings',
          style: TextStyle(fontSize: 12, color: AC.t3),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

// ─── LABEL ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AC.t1,
      letterSpacing: -0.2,
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../vehicles/services/vehicle_service.dart';
import 'services/diagnostics_service.dart';
import 'package:file_picker/file_picker.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});
  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scan;
  bool _scanning = false;
  bool _loadingVehicles = true;
  final _service = DiagnosticsService();
  final _vehicleService = VehicleService();
  // ── Required ────────────────────────────────────────────────────────────────
  final _rpm = TextEditingController();
  final _coolant = TextEditingController();
  final _speed = TextEditingController();
  // ── Engine ──────────────────────────────────────────────────────────────────
  final _voltage = TextEditingController();
  final _runTime = TextEditingController();
  final _engineLoad = TextEditingController();
  final _throttle = TextEditingController();
  final _timingAdvance = TextEditingController();
  // ── Fuel System ─────────────────────────────────────────────────────────────
  final _stFuelTrim = TextEditingController();
  final _ltFuelTrim = TextEditingController();
  final _fuelTank = TextEditingController();
  final _fuelAirRatio = TextEditingController();
  // ── Air / Pressure ──────────────────────────────────────────────────────────
  final _intakeManifoldPressure = TextEditingController();
  final _intakeAirTemp = TextEditingController();
  final _barometricPressure = TextEditingController();
  // ── Throttle / Pedal ────────────────────────────────────────────────────────
  final _absThrottleB = TextEditingController();
  final _relThrottlePos = TextEditingController();
  final _pedalD = TextEditingController();
  final _pedalE = TextEditingController();
  final _commandedThrottle = TextEditingController();
  // ── Catalyst ────────────────────────────────────────────────────────────────
  final _catTempS1 = TextEditingController();
  final _catTempS2 = TextEditingController();
  // ── Evaporative ─────────────────────────────────────────────────────────────
  final _evapPurge = TextEditingController();
  final _faultCodes = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedVehicleId;
  @override
  void initState() {
    super.initState();
    _scan = AnimationController(vsync: this, duration: 2000.ms);
    _loadVehicles();
  }

  @override
  void dispose() {
    _scan.dispose();
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
    _faultCodes.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final vehicles = await AppErrorHandler.guard(
      context,
      () => _vehicleService.getVehicles(),
      fallbackMessage: 'Could not load your vehicles.',
    );
    if (!mounted) return;
    setState(() {
      _loadingVehicles = false;
      _selectedVehicleId =
          vehicles?.firstOrNull?.id ?? AppCache.vehicles.firstOrNull?.id;
    });
  }

  Future<void> _start() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
      AppErrorHandler.showMessage(
        context,
        'Add a vehicle before running a diagnostic scan.',
      );
      return;
    }
    setState(() => _scanning = true);
    _scan.repeat();
    final report = await AppErrorHandler.guard(
      context,
      () => _service.scan(
        vehicleId: _selectedVehicleId!,
        sensorReadings: {
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
          'FUEL_AIR_COMMANDED_EQUIV_RATIO': double.parse(
            _fuelAirRatio.text.trim(),
          ),
          'INTAKE_MANIFOLD_PRESSURE': double.parse(
            _intakeManifoldPressure.text.trim(),
          ),
          'INTAKE_AIR_TEMP': double.parse(_intakeAirTemp.text.trim()),
          'ABSOLUTE_BAROMETRIC_PRESSURE': double.parse(
            _barometricPressure.text.trim(),
          ),
          'ABSOLUTE_THROTTLE_B': double.parse(_absThrottleB.text.trim()),
          'RELATIVE_THROTTLE_POSITION': double.parse(
            _relThrottlePos.text.trim(),
          ),
          'PEDAL_D': double.parse(_pedalD.text.trim()),
          'PEDAL_E': double.parse(_pedalE.text.trim()),
          'COMMANDED_THROTTLE_ACTUATOR': double.parse(
            _commandedThrottle.text.trim(),
          ),
          'CATALYST_TEMPERATURE_BANK1_SENSOR1': double.parse(
            _catTempS1.text.trim(),
          ),
          'CATALYST_TEMPERATURE_BANK1_SENSOR2': double.parse(
            _catTempS2.text.trim(),
          ),
          'COMMANDED_EVAPORATIVE_PURGE': double.parse(_evapPurge.text.trim()),
        },
        faultCodes: _faultCodes.text
            .split(',')
            .map((c) => c.trim().toUpperCase())
            .where((c) => c.isNotEmpty)
            .toList(growable: false),
      ),
      fallbackMessage: 'The diagnostic scan could not be completed.',
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    _scan.stop();
    _scan.reset();
    if (report != null) {
      Navigator.pushNamed(context, R.diagResult);
    }
  }

  Future<void> _upload() async {
    if (_selectedVehicleId == null || _selectedVehicleId!.isEmpty) {
      AppErrorHandler.showMessage(context, 'Select a vehicle first.');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'json'],
      withData: true,
    );
    if (!mounted) return;
    final file = result?.files.firstOrNull;
    if (file == null) return;
    setState(() => _scanning = true);
    final report = await AppErrorHandler.guard(
      context,
      () => _service.uploadObdFile(vehicleId: _selectedVehicleId!, file: file),
      fallbackMessage: 'Could not upload this OBD file.',
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    if (report != null) Navigator.pushNamed(context, R.diagResult);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const SAppBar(title: 'AI Diagnostics'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              'Connect & Scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AC.t1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time OBD-II + AI analysis',
              style: TextStyle(fontSize: 13, color: AC.t3),
            ),
            const SizedBox(height: 36),
            PulseRing(
              color: _scanning ? AC.red : AC.border,
              size: 220,
              child:
                  Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          gradient: _scanning
                              ? AC.redGrad
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF2A2A2A),
                                    Color(0xFF1E1E1E),
                                  ],
                                ),
                          shape: BoxShape.circle,
                          boxShadow: _scanning
                              ? [
                                  BoxShadow(
                                    color: AC.red.withValues(alpha: 0.55),
                                    blurRadius: 40,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          color: _scanning ? Colors.white : AC.t3,
                          size: 60,
                        ),
                      )
                      .animate(target: _scanning ? 1 : 0)
                      .rotate(
                        end: 1.0,
                        duration: 2000.ms,
                        curve: Curves.linear,
                      ),
            ),
            const SizedBox(height: 20),
            Text(
              _scanning ? 'Analyzing your vehicle…' : 'Ready to Scan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _scanning ? AC.red : AC.t2,
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 8),
            Text(
              _scanning
                  ? 'Please wait, do not close the app'
                  : 'Ensure your OBD-II adapter is connected',
              style: const TextStyle(fontSize: 13, color: AC.t3),
            ),
            const SizedBox(height: 32),
            ACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OBD-II Inputs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _VehiclePicker(
                    loading: _loadingVehicles,
                    selectedVehicleId: _selectedVehicleId,
                    onChanged: (value) =>
                        setState(() => _selectedVehicleId = value),
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(label: 'Required', color: AC.error),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Engine RPM',
                          hint: 'e.g. 800',
                          unit: 'rpm',
                          ctrl: _rpm,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Coolant Temp',
                          hint: 'e.g. 90',
                          unit: '°C',
                          ctrl: _coolant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SensorField(
                    label: 'Vehicle Speed',
                    hint: 'e.g. 60',
                    unit: 'km/h',
                    ctrl: _speed,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(label: 'Engine', color: AC.warning),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Control Module Voltage',
                          hint: 'e.g. 14.2',
                          unit: 'V',
                          ctrl: _voltage,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Engine Run Time',
                          hint: 'e.g. 300',
                          unit: 's',
                          ctrl: _runTime,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Engine Load',
                          hint: 'e.g. 45',
                          unit: '%',
                          ctrl: _engineLoad,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Throttle Position',
                          hint: 'e.g. 20',
                          unit: '%',
                          ctrl: _throttle,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SensorField(
                    label: 'Timing Advance',
                    hint: 'e.g. 10',
                    unit: '°',
                    ctrl: _timingAdvance,
                    optional: false,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(label: 'Fuel System', color: AC.gold),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Short-Term Fuel Trim B1',
                          hint: 'e.g. -2.3',
                          unit: '%',
                          ctrl: _stFuelTrim,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Long-Term Fuel Trim B1',
                          hint: 'e.g. 1.5',
                          unit: '%',
                          ctrl: _ltFuelTrim,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Fuel Tank Level',
                          hint: 'e.g. 65',
                          unit: '%',
                          ctrl: _fuelTank,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Fuel/Air Equiv Ratio',
                          hint: 'e.g. 1.00',
                          unit: 'λ',
                          ctrl: _fuelAirRatio,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(label: 'Air & Pressure', color: AC.info),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Intake Manifold Pressure',
                          hint: 'e.g. 101',
                          unit: 'kPa',
                          ctrl: _intakeManifoldPressure,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Intake Air Temp',
                          hint: 'e.g. 30',
                          unit: '°C',
                          ctrl: _intakeAirTemp,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SensorField(
                    label: 'Absolute Barometric Pressure',
                    hint: 'e.g. 101',
                    unit: 'kPa',
                    ctrl: _barometricPressure,
                    optional: false,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(
                    label: 'Throttle & Pedal',
                    color: AC.success,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Absolute Throttle B',
                          hint: 'e.g. 18',
                          unit: '%',
                          ctrl: _absThrottleB,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Relative Throttle Pos',
                          hint: 'e.g. 12',
                          unit: '%',
                          ctrl: _relThrottlePos,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Pedal Position D',
                          hint: 'e.g. 22',
                          unit: '%',
                          ctrl: _pedalD,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Pedal Position E',
                          hint: 'e.g. 22',
                          unit: '%',
                          ctrl: _pedalE,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SensorField(
                    label: 'Commanded Throttle Actuator',
                    hint: 'e.g. 20',
                    unit: '%',
                    ctrl: _commandedThrottle,
                    optional: false,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(
                    label: 'Catalyst Temperature',
                    color: AC.error,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SensorField(
                          label: 'Catalyst Temp B1S1',
                          hint: 'e.g. 520',
                          unit: '°C',
                          ctrl: _catTempS1,
                          optional: false,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SensorField(
                          label: 'Catalyst Temp B1S2',
                          hint: 'e.g. 490',
                          unit: '°C',
                          ctrl: _catTempS2,
                          optional: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(
                    label: 'Evaporative System',
                    color: AC.success,
                  ),
                  const SizedBox(height: 10),
                  _SensorField(
                    label: 'Commanded Evaporative Purge',
                    hint: 'e.g. 50',
                    unit: '%',
                    ctrl: _evapPurge,
                  ),
                  const SizedBox(height: 16),
                  const _GroupLabel(label: 'DTC Fault Codes', color: AC.error),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter codes read from your OBD scanner, separated by commas. Each code will be looked up and defined automatically.',
                    style: TextStyle(fontSize: 11, color: AC.t3, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  AppField(
                    label: 'Fault Codes (optional)',
                    hint: 'P0300, P0420, U0100',
                    ctrl: _faultCodes,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppBtn(
              label: _scanning ? 'Scanning...' : 'Start Full Scan',
              loading: _scanning,
              onTap: _scanning ? null : _start,
              icon: _scanning
                  ? null
                  : const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
            const SizedBox(height: 12),
            AppBtn(
              label: 'Upload OBD File',
              outline: true,
              onTap: _scanning ? null : _upload,
              icon: const Icon(
                Icons.upload_file_rounded,
                color: AC.red,
                size: 18,
              ),
            ),
            const SizedBox(height: 28),
            AppBtn(
              label: 'View Scan History',
              outline: true,
              onTap: () => Navigator.pushNamed(context, R.diagHistory),
              icon: const Icon(Icons.history_rounded, color: AC.red, size: 18),
            ),
            const SizedBox(height: 36),
            _ConnectionCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

class _SensorField extends StatelessWidget {
  final String label;
  final String hint;
  final String unit;
  final TextEditingController ctrl;
  final bool optional;

  const _SensorField({
    required this.label,
    required this.ctrl,
    this.hint = '0',
    this.unit = '',
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

class _GroupLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupLabel({required this.label, required this.color});

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

class _VehiclePicker extends StatelessWidget {
  final bool loading;
  final String? selectedVehicleId;
  final ValueChanged<String?> onChanged;
  const _VehiclePicker({
    required this.loading,
    required this.selectedVehicleId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vehicles = AppCache.vehicles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AC.t2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AC.s1,
            borderRadius: Rd.mdA,
            border: Border.all(color: AC.border),
          ),
          child: loading
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AC.red,
                    ),
                  ),
                )
              : vehicles.isEmpty
              ? const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No vehicles found',
                    style: TextStyle(fontSize: 13, color: AC.t3),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedVehicleId,
                    isExpanded: true,
                    dropdownColor: AC.s2,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AC.t3,
                    ),
                    style: const TextStyle(
                      color: AC.t1,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: vehicles
                        .map(
                          (vehicle) => DropdownMenuItem<String>(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.fullName} - ${vehicle.plate}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ACard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OBD-II Input Mode',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AC.t1,
          ),
        ),
        const SizedBox(height: 16),
        const Div(),
        const SizedBox(height: 16),
        const Text(
          'Enter your vehicle sensor readings manually below. '
          'Values are sent to the AI engine for real-time analysis.',
          style: TextStyle(fontSize: 12, color: AC.t3, height: 1.5),
        ),
        const SizedBox(height: 12),
        ...[
          ('Input Source', 'Manual / OBD Reader', AC.info),
          ('AI Engine', 'Random Forest Model', AC.success),
          ('Data Storage', 'MongoDB Atlas', AC.success),
        ].map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: e.$3,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(e.$1, style: const TextStyle(fontSize: 13, color: AC.t3)),
                const Spacer(),
                Text(
                  e.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: e.$3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

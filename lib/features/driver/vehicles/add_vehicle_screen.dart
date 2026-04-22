import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _plate = TextEditingController();

  final _fk = GlobalKey<FormState>();

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Add Vehicle'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _fk,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: AC.redGrad,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AC.red.withOpacity(0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ).animate().scale(
                begin: const Offset(0, 0),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
              const SizedBox(height: 32),
              AppField(
                label: 'Make',
                hint: 'Toyota, Ford, BMW…',
                ctrl: _make,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              AppField(
                label: 'Model',
                hint: 'Camry, F-150, 3 Series…',
                ctrl: _model,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 280.ms),
              const SizedBox(height: 16),
              AppField(
                label: 'Year',
                hint: '2022',
                ctrl: _year,
                keyboard: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 360.ms),
              const SizedBox(height: 16),
              AppField(
                label: 'License Plate',
                hint: '7XYZ 421',
                ctrl: _plate,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 440.ms),
              const SizedBox(height: 36),
              AppBtn(
                label: 'Add Vehicle',
                onTap: () {
                  if (_fk.currentState!.validate()) {
                    Navigator.pop(context);
                  }
                },
              ).animate().fadeIn(delay: 520.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
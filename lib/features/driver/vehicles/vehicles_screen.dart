import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'services/vehicle_service.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final _service = VehicleService();
  bool _loading = true;
  List<VehicleModel> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final vehicles = await _service.getVehicles();
      if (mounted) setState(() => _vehicles = vehicles);
    } catch (_) {
      if (mounted) setState(() => _vehicles = AppCache.vehicles);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(
          title: 'My Vehicles',
          actions: [
            GestureDetector(
              onTap: () async {
                await Navigator.pushNamed(context, R.addVehicle);
                _load();
              },
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.smA),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _vehicles.isEmpty
                    ? const EmptyState(icon: '🚗', title: 'No Vehicles', sub: 'Add your first vehicle')
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        itemCount: _vehicles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final v = _vehicles[i];
                          return VehicleCard(
                            make: v.make,
                            model: v.model,
                            year: v.year,
                            plate: v.plate,
                            health: v.health.toDouble(),
                            onTap: () async {
                              await _service.deleteVehicle(v.id);
                              await _load();
                            },
                          ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.2, end: 0, delay: (i * 100).ms);
                        },
                      ),
              ),
      );
}

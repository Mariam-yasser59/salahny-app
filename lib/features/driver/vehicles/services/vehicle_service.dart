import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/app_cache.dart';

class VehicleService {
  VehicleService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<VehicleModel>> getVehicles() async {
    final response = await _client.get('/vehicles') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final vehicles = items.map(_mapVehicle).toList(growable: false);
    AppCache.setRemoteVehicles(vehicles);
    return vehicles;
  }

  Future<VehicleModel> createVehicle({
    required String make,
    required String model,
    required String year,
    required String plate,
    String color = 'White',
    String fuel = 'Gasoline',
    int mileage = 0,
  }) async {
    final response =
        await _client.post('/vehicles', {
              'make': make,
              'model': model,
              'year': year,
              'plate': plate,
              'color': color,
              'fuel': fuel,
              'mileage': mileage,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final vehicle = _mapVehicle(data);
    final current = AppCache.vehicles.toList(growable: true);
    current.insert(0, vehicle);
    AppCache.setRemoteVehicles(current);
    if (current.length == 1 || AppCache.preferredVehicleId == null) {
      await AppCache.savePreferredVehicleId(vehicle.id);
    }
    return vehicle;
  }

  Future<void> deleteVehicle(String id) async {
    await _client.delete('/vehicles/$id');
    final updated = AppCache.vehicles.where((v) => v.id != id).toList();
    AppCache.setRemoteVehicles(updated);
    if (updated.isNotEmpty && AppCache.preferredVehicleId == null) {
      await AppCache.savePreferredVehicleId(updated.first.id);
    }
  }

  VehicleModel _mapVehicle(Map<String, dynamic> json) {
    return VehicleModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      plate: json['plate']?.toString() ?? '',
      color: json['color']?.toString() ?? 'White',
      fuel: json['fuel']?.toString() ?? 'Gasoline',
      health: (json['health'] as num?)?.toDouble() ?? 100,
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
    );
  }
}

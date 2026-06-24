import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/app_cache.dart';

class UserProfileService {
  UserProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<UserModel> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final response =
        await _client.put('/users/me', {
              'name': name,
              'email': email,
              'phone': phone,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final user = UserModel(
      id: (data['id'] ?? data['_id'] ?? AppCache.currentUser.id).toString(),
      name: data['name']?.toString() ?? name,
      email: data['email']?.toString() ?? email,
      phone: data['phone']?.toString() ?? phone,
      role: data['role']?.toString() ?? AppCache.currentUser.role,
      walletBalance: AppCache.currentUser.walletBalance,
      rating: AppCache.currentUser.rating,
      totalBookings:
          (data['totalBookings'] as num?)?.toInt() ??
          AppCache.currentUser.totalBookings,
      vehicleCount: AppCache.currentUser.vehicleCount,
      activeSubscription: AppCache.currentUser.activeSubscription,
    );
    AppCache.setCurrentUser(user);
    return user;
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get('/users/me') as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final subscription = data['activeSubscription'] as Map<String, dynamic>?;
    final user = UserModel(
      id: (data['id'] ?? data['_id'] ?? '').toString(),
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      role: data['role']?.toString() ?? 'driver',
      walletBalance: AppCache.currentUser.walletBalance,
      rating: AppCache.currentUser.rating,
      totalBookings: AppCache.currentUser.totalBookings,
      vehicleCount:
          (data['vehicleCount'] as num?)?.toInt() ?? AppCache.vehicles.length,
      activeSubscription: subscription == null
          ? null
          : ActiveSubscription(
              packageName: subscription['packageName']?.toString() ?? '',
              startsAt:
                  DateTime.tryParse(
                    subscription['startsAt']?.toString() ?? '',
                  ) ??
                  DateTime.now(),
              endsAt:
                  DateTime.tryParse(subscription['endsAt']?.toString() ?? '') ??
                  DateTime.now(),
              remainingDays:
                  (subscription['remainingDays'] as num?)?.toInt() ?? 0,
            ),
    );
    AppCache.setCurrentUser(user);
    return user;
  }

  Future<List<VehicleModel>> getVehicles() async {
    final response =
        await _client.get('/users/me/vehicles') as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    return items
        .map((item) => _mapVehicle(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<VehicleModel> addVehicle({
    required String make,
    required String model,
    required String year,
    required String plate,
  }) async {
    final response =
        await _client.post('/users/me/vehicles', {
              'make': make,
              'model': model,
              'year': year,
              'plate': plate,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final vehicle = _mapVehicle(data);
    await AppCache.saveVehicle(
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      plate: vehicle.plate,
    );
    return vehicle;
  }

  VehicleModel _mapVehicle(Map<String, dynamic> json) {
    return VehicleModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      plate: json['plate']?.toString() ?? '',
      color: json['color']?.toString() ?? 'Custom',
      fuel: json['fuel']?.toString() ?? 'Gasoline',
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      health: (json['health'] as num?)?.toDouble() ?? 100,
    );
  }
}

import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';

class ServiceApi {
  ServiceApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ServiceModel>> getServices() async {
    final response =
        await _client.get('/public/services', auth: false)
            as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    final services = items
        .map((item) => _mapService(item as Map<String, dynamic>))
        .toList(growable: false);
    AppCache.setRemoteServices(services);
    return services;
  }

  Future<List<PackageModel>> getPackages() async {
    final response =
        await _client.get('/public/packages', auth: false)
            as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    final packages = items
        .map((item) => _mapPackage(item as Map<String, dynamic>))
        .toList(growable: false);
    AppCache.setRemotePackages(packages);
    return packages;
  }

  Future<Map<String, dynamic>> createRequest(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    return await _client.post(endpoint, payload) as Map<String, dynamic>;
  }

  ServiceModel _mapService(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Maintenance',
      description: json['description']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🔧',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMins: (json['durationMins'] as num?)?.toInt() ?? 60,
      isPopular: json['isPopular'] == true,
    );
  }

  PackageModel _mapPackage(Map<String, dynamic> json) {
    final months = (json['durationMonths'] as num?)?.toInt() ?? 1;
    return PackageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      duration: months == 1 ? 'month' : '$months months',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice:
          (json['originalPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          0,
      features: (json['features'] as List<dynamic>? ?? const [])
          .map((feature) => feature.toString())
          .toList(growable: false),
      isPopular: json['isPopular'] == true,
    );
  }
}

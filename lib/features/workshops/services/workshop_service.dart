import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';

class WorkshopService {
  WorkshopService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<WorkshopModel>> getWorkshops({
    double? latitude,
    double? longitude,
    String search = '',
  }) async {
    final params = <String, String>{};
    if (latitude != null && longitude != null) {
      params['latitude'] = latitude.toString();
      params['longitude'] = longitude.toString();
    }
    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final endpoint = query.isEmpty
        ? '/public/workshops'
        : '/public/workshops?$query';
    final response =
        await _client.get(endpoint, auth: false) as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    final workshops = items
        .map((item) => _mapWorkshop(item as Map<String, dynamic>))
        .toList(growable: false);
    AppCache.setRemoteWorkshops(workshops);
    return workshops;
  }

  Future<Map<String, dynamic>> createWorkshop(
    Map<String, dynamic> payload,
  ) async {
    final response =
        await _client.post('/workshops', payload) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data;
  }

  WorkshopModel _mapWorkshop(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final serviceDetails =
        (json['serviceDetails'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map((item) => item['name']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty && name != '[object Object]')
            .toList(growable: false);
    final services = (json['services'] as List<dynamic>? ?? const [])
        .map((item) => item.toString().trim())
        .where((name) => name.isNotEmpty && name != '[object Object]')
        .toList(growable: false);
    final specialty = serviceDetails.isNotEmpty
        ? serviceDetails.first
        : services.isNotEmpty
        ? services.first
        : 'Full Service';
    final serviceNames = <String>{
      ...serviceDetails,
      ...services,
    }.where((name) => name.trim().isNotEmpty).toList(growable: false);
    return WorkshopModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      address: json['location']?.toString() ?? '',
      phone: owner?['phone']?.toString() ?? '',
      specialty: specialty,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      distance: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      isOpen: true,
      isVerified: json['isVerified'] == true,
      availableSlots: (json['availableSlots'] as List<dynamic>? ?? const [])
          .map((slot) => DateTime.tryParse(slot.toString()))
          .whereType<DateTime>()
          .map((slot) => slot.toLocal())
          .toList(growable: false),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceNames: serviceNames,
    );
  }
}

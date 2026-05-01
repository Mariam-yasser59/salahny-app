import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';

class WorkshopService {
  WorkshopService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<WorkshopModel>> getWorkshops() async {
    final response = await _client.get('/workshops', auth: false) as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    final workshops = items
        .map((item) => _mapWorkshop(item as Map<String, dynamic>))
        .toList(growable: false);
    MockData.setRemoteWorkshops(workshops);
    return workshops;
  }

  Future<Map<String, dynamic>> createWorkshop(Map<String, dynamic> payload) async {
    final response = await _client.post('/workshops', payload) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data;
  }

  WorkshopModel _mapWorkshop(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;
    final services = json['services'] as List<dynamic>? ?? const [];
    return WorkshopModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      address: json['location']?.toString() ?? '',
      phone: owner?['phone']?.toString() ?? '',
      specialty: services.isNotEmpty ? services.first.toString() : 'Full Service',
      rating: 4.8,
      distance: 1.2,
      isOpen: true,
      isVerified: true,
    );
  }
}

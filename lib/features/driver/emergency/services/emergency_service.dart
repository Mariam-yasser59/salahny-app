import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';

class EmergencyService {
  EmergencyService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  Future<EmergencyRequestModel> createRequest({
    required String emergencyType,
    required String issueDescription,
    required String address,
    double? latitude,
    double? longitude,
    String locationNotes = '',
    String? vehicleId,
    String phone = '',
    String vehicleLabel = '',
  }) async {
    final response =
        await _client.post('/emergency', {
              'emergencyType': emergencyType,
              'issueDescription': issueDescription,
              'address': address,
              if (latitude != null) 'latitude': latitude,
              if (longitude != null) 'longitude': longitude,
              'locationNotes': locationNotes,
              if (vehicleId != null) 'vehicleId': vehicleId,
              'phone': phone,
              'vehicleLabel': vehicleLabel,
            })
            as Map<String, dynamic>;
    return _map(response['data'] as Map<String, dynamic>);
  }

  Future<List<EmergencyRequestModel>> myRequests() async {
    final response = await _client.get('/emergency/my') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_map)
        .toList(growable: false);
  }

  Future<EmergencyRequestModel> cancel(String id, {String reason = ''}) async {
    final response =
        await _client.patch('/emergency/$id/cancel', {'reason': reason})
            as Map<String, dynamic>;
    return _map(response['data'] as Map<String, dynamic>);
  }

  EmergencyRequestModel _map(Map<String, dynamic> json) {
    final workshop = json['assignedWorkshop'] as Map<String, dynamic>?;
    return EmergencyRequestModel(
      id: (json['id'] ?? json['emergencyRequestId'] ?? '').toString(),
      emergencyType: json['emergencyType']?.toString() ?? 'other',
      issueDescription: json['issueDescription']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationNotes: json['locationNotes']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      assignedWorkshopName: workshop?['name']?.toString(),
      assignedWorkshopPhone: workshop?['phone']?.toString(),
      distanceKm: (workshop?['distanceKm'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

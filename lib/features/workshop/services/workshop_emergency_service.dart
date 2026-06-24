import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class WorkshopEmergencyService {
  final _client = ApiClient();
  Future<List<EmergencyRequestModel>> getAssigned() async {
    final response =
        await _client.get('/emergency/workshop/assigned')
            as Map<String, dynamic>;
    return (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (json) => EmergencyRequestModel(
            id: json['id']?.toString() ?? '',
            emergencyType: json['emergencyType']?.toString() ?? '',
            issueDescription: json['issueDescription']?.toString() ?? '',
            address: json['address']?.toString() ?? '',
            latitude: (json['latitude'] as num?)?.toDouble(),
            longitude: (json['longitude'] as num?)?.toDouble(),
            locationNotes: json['locationNotes']?.toString() ?? '',
            status: json['status']?.toString() ?? '',
            assignedWorkshopName: null,
            assignedWorkshopPhone: null,
            distanceKm: null,
            createdAt:
                DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                DateTime.now(),
          ),
        )
        .toList(growable: false);
  }

  Future<void> update(String id, String status) async {
    if (status == 'accepted_by_workshop') {
      await _client.patch('/emergency/$id/accept', {});
    } else if (status == 'rejected') {
      await _client.patch('/emergency/$id/reject', {});
    } else {
      await _client.patch('/emergency/$id/status', {'status': status});
    }
  }
}

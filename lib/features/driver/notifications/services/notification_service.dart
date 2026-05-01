import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/mock_data.dart';

class NotificationService {
  NotificationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<NotificationModel>> getNotifications() async {
    final response = await _client.get('/notifications') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final notifications = items
        .map(
          (item) => NotificationModel(
            id: (item['id'] ?? '').toString(),
            title: item['title']?.toString() ?? '',
            body: item['body']?.toString() ?? '',
            type: item['type']?.toString() ?? 'system',
            time: DateTime.tryParse(item['time']?.toString() ?? '') ?? DateTime.now(),
            isRead: item['isRead'] == true,
          ),
        )
        .toList(growable: false);
    MockData.setRemoteNotifications(notifications);
    return notifications;
  }

  Future<void> markRead(String id) async {
    await _client.patch('/notifications/$id/read', {});
  }
}

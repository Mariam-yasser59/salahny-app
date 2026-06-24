import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/app_cache.dart';

class NotificationService {
  NotificationService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<NotificationModel>> getNotifications() async {
    final response =
        await _client.get('/notifications') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final notifications = items.map(mapNotification).toList(growable: false);
    AppCache.setRemoteNotifications(notifications);
    return notifications;
  }

  Future<void> markRead(String id) async {
    await _client.patch('/notifications/$id/read', {});
  }

  Future<void> markAllRead() async {
    await _client.patch('/notifications/read-all', {});
  }

  Future<int> unreadCount() async {
    final response =
        await _client.get('/notifications/unread-count')
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? const {};
    return int.tryParse(
          (data['unreadCount'] ?? data['unread'] ?? '0').toString(),
        ) ??
        0;
  }

  Future<void> saveDeviceToken({
    required String token,
    String platform = 'unknown',
  }) async {
    await _client.post('/notifications/device-token', {
      'token': token,
      'platform': platform,
    });
  }

  NotificationModel mapNotification(Map<String, dynamic> item) =>
      NotificationModel(
        id: (item['id'] ?? '').toString(),
        title: item['title']?.toString() ?? '',
        body: (item['body'] ?? item['message'])?.toString() ?? '',
        type: item['type']?.toString() ?? 'system',
        time:
            DateTime.tryParse(item['time']?.toString() ?? '') ?? DateTime.now(),
        isRead: item['isRead'] == true,
        data: (item['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

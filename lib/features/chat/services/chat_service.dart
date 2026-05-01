import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ChatMessage>> getBookingMessages(String bookingId) async {
    final response = await _client.get('/chat/bookings/$bookingId/messages')
        as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(_mapMessage).toList(growable: false);
  }

  Future<ChatMessage> sendBookingMessage(String bookingId, String text) async {
    final response = await _client.post(
      '/chat/bookings/$bookingId/messages',
      {'text': text},
    ) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return _mapMessage(data);
  }

  Future<String> askAi({
    required String message,
    String? bookingId,
  }) async {
    final response = await _client.post('/chat/ai', {
      'message': message,
      if (bookingId != null) 'bookingId': bookingId,
    }) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data['reply']?.toString() ?? '';
  }

  Future<void> shareDiagnostic({
    required String bookingId,
    required String summary,
    required String recommendation,
  }) async {
    await _client.post('/chat/bookings/$bookingId/share-diagnostic', {
      'summary': summary,
      'recommendation': recommendation,
    });
  }

  ChatMessage _mapMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      text: json['text']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      isMe: json['isMe'] == true,
    );
  }
}

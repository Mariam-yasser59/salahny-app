import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';

class ChatService {
  ChatService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<ChatMessage>> getBookingMessages(String bookingId) async {
    final response =
        await _client.get('/chat/bookings/$bookingId/messages')
            as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(mapMessage).toList(growable: false);
  }

  Future<BookingChatContext> getBookingContext(String bookingId) async {
    final response =
        await _client.get('/chat/bookings/$bookingId/context')
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return BookingChatContext.fromJson(data);
  }

  Future<ChatMessage> sendBookingMessage(String bookingId, String text) async {
    final response =
        await _client.post('/chat/bookings/$bookingId/messages', {'text': text})
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return mapMessage(data);
  }

  Future<String> askAi({required String message, String? bookingId}) async {
    final response =
        await _client.post('/chatbot/message', {
              'message': message,
              if (bookingId != null) 'bookingId': bookingId,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data['reply']?.toString() ?? response['reply']?.toString() ?? '';
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

  Future<List<ChatMessage>> getAdminWorkshopMessages(String workshopId) async {
    final response =
        await _client.get('/admin/workshops/$workshopId/messages')
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final items = (data['messages'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(mapMessage).toList(growable: false);
  }

  Future<ChatMessage> sendAdminWorkshopMessage({
    required String workshopId,
    required String text,
  }) async {
    final response =
        await _client.post('/admin/workshops/$workshopId/messages', {
              'text': text,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return mapMessage(data);
  }

  Future<List<ChatMessage>> getWorkshopAdminMessages() async {
    final response =
        await _client.get('/workshop-portal/admin/messages')
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final items = (data['messages'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(mapMessage).toList(growable: false);
  }

  Future<ChatMessage> sendWorkshopAdminMessage(String text) async {
    final response =
        await _client.post('/workshop-portal/admin/messages', {'text': text})
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return mapMessage(data);
  }

  Future<List<ChatMessage>> getDriverAdminMessages() async {
    final response =
        await _client.get('/direct-messages/admin') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(mapMessage).toList(growable: false);
  }

  Future<ChatMessage> sendDriverAdminMessage(String text) async {
    final response =
        await _client.post('/direct-messages/admin', {'text': text})
            as Map<String, dynamic>;
    return mapMessage(response['data'] as Map<String, dynamic>? ?? response);
  }

  ChatMessage mapMessage(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      text: json['text']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      isMe: json['isMe'] == true,
    );
  }
}

class BookingChatContext {
  const BookingChatContext({
    required this.bookingId,
    required this.peerName,
    required this.peerPhone,
    required this.peerRole,
  });

  final String bookingId;
  final String peerName;
  final String peerPhone;
  final String peerRole;

  factory BookingChatContext.fromJson(Map<String, dynamic> json) {
    final peer = json['peer'] as Map<String, dynamic>? ?? const {};
    return BookingChatContext(
      bookingId: (json['bookingId'] ?? '').toString(),
      peerName: (peer['name'] ?? '').toString(),
      peerPhone: (peer['phone'] ?? '').toString(),
      peerRole: (peer['role'] ?? '').toString(),
    );
  }
}

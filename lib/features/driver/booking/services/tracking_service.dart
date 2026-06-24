import '../../../../core/network/api_client.dart';

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.etaMinutes,
    required this.note,
    required this.time,
  });

  final double latitude;
  final double longitude;
  final int etaMinutes;
  final String note;
  final DateTime time;
}

class TrackingService {
  final _client = ApiClient();

  Future<List<TrackingPoint>> getUpdates(String bookingId) async {
    final response =
        await _client.get('/tracking/$bookingId') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items.map(mapPoint).toList();
  }

  Future<void> postUpdate({
    required String bookingId,
    required double latitude,
    required double longitude,
    int etaMinutes = 0,
    String note = '',
  }) async {
    await _client.post('/tracking/$bookingId', {
      'latitude': latitude,
      'longitude': longitude,
      'etaMinutes': etaMinutes,
      'note': note,
    });
  }

  TrackingPoint mapPoint(Map<String, dynamic> item) => TrackingPoint(
    latitude: (item['latitude'] as num?)?.toDouble() ?? 0,
    longitude: (item['longitude'] as num?)?.toDouble() ?? 0,
    etaMinutes: (item['etaMinutes'] as num?)?.toInt() ?? 0,
    note: item['note']?.toString() ?? '',
    time: DateTime.tryParse(item['time']?.toString() ?? '') ?? DateTime.now(),
  );
}

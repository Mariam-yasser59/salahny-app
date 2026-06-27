import '../../../core/network/api_client.dart';

class RatingService {
  RatingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> submitRating({
    required String bookingId,
    required int rating,
    String comment = '',
  }) async {
    await _client.post('/reviews', {
      'bookingId': bookingId,
      'rating': rating,
      'comment': comment.trim(),
    });
  }
}

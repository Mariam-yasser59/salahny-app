import '../../../core/network/api_client.dart';

class RatingService {
  RatingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> submitRating({
    required String bookingId,
    required int rating,
    String comment = '',
    String ratingType = 'workshop_by_customer',
  }) async {
    final cleanComment = comment.trim();
    try {
      await _client.post('/reviews', {
        'bookingId': bookingId,
        'rating': rating,
        'comment': cleanComment,
      });
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      await _client.post('/ratings', {
        'bookingId': bookingId,
        'ratingType': ratingType,
        'stars': rating,
        'comment': cleanComment,
      });
    }
  }
}

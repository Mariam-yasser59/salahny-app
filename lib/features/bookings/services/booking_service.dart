import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';

class BookingService {
  BookingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<BookingModel>> getBookings() async {
    final response = await _client.get('/bookings') as Map<String, dynamic>;
    final items = response['data'] as List<dynamic>? ?? const [];
    final bookings = items
        .map((item) => _mapBooking(item as Map<String, dynamic>))
        .toList(growable: false);
    AppCache.setRemoteBookings(bookings);
    AppCache.setCurrentUser(
      AppCache.currentUser.copyWith(totalBookings: bookings.length),
    );
    return bookings;
  }

  Future<BookingModel> createBooking(Map<String, dynamic> payload) async {
    final response =
        await _client.post('/bookings', payload) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final booking = _mapBooking(data);
    final current = AppCache.bookings.toList(growable: true);
    current.insert(0, booking);
    AppCache.setRemoteBookings(current);
    AppCache.setCurrentUser(
      AppCache.currentUser.copyWith(totalBookings: current.length),
    );
    return booking;
  }

  Future<BookingModel> updateBookingStatus(String id, String status) async {
    final response =
        await _client.patch('/bookings/$id/status', {'status': status})
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return _mapBooking(data);
  }

  BookingModel _mapBooking(Map<String, dynamic> json) {
    final workshop = json['workshop'] as Map<String, dynamic>?;
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    return BookingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      serviceName: json['service']?.toString() ?? '',
      workshopName: workshop?['name']?.toString() ?? '',
      status: _statusLabel(json['status']?.toString() ?? 'pending'),
      date: date == null
          ? appShortDate()
          : appShortDate(date.difference(DateTime.now()).inDays),
      time: date == null ? '10:00 AM' : _formatTime(date),
      slotIso: date?.toIso8601String() ?? '',
      price: (json['total'] as num?)?.toDouble() ?? 0,
      driverReviewed:
          (json['reviewState'] as Map<String, dynamic>?)?['driverReviewed'] ==
          true,
      workshopReviewed:
          (json['reviewState'] as Map<String, dynamic>?)?['workshopReviewed'] ==
          true,
      driverRating:
          ((json['reviewState'] as Map<String, dynamic>?)?['driverRating']
                  as num?)
              ?.toDouble(),
      workshopRating:
          ((json['reviewState'] as Map<String, dynamic>?)?['workshopRating']
                  as num?)
              ?.toDouble(),
    );
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'accepted':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'diagnostics_ready':
        return 'Diagnostics Ready';
      case 'repair_in_progress':
        return 'Repair In Progress';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

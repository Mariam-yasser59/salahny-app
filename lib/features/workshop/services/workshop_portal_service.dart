import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';

class WorkshopPortalService {
  WorkshopPortalService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> syncDashboard() async {
    final response =
        await _client.get('/workshop-portal/dashboard') as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final profileJson = data['profile'] as Map<String, dynamic>? ?? const {};
    final bookingsJson = (data['bookings'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();

    MockData.setRemoteWorkshopPortal(
      profile: WorkshopProfileData(
        id: profileJson['id']?.toString() ?? '',
        name: profileJson['name']?.toString() ?? '',
        initials: profileJson['initials']?.toString() ?? 'WS',
        specialty: profileJson['specialty']?.toString() ?? 'Full Service',
        rating: (profileJson['rating'] as num?)?.toDouble() ?? 4.8,
        isOpen: profileJson['isOpen'] == true,
        isVerified: profileJson['isVerified'] == true,
        monthlyRevenue:
            (profileJson['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        revenuePeriod: profileJson['revenuePeriod']?.toString() ?? 'Current period',
        payoutMethod: profileJson['payoutMethod']?.toString() ?? 'Bank Transfer',
      ),
      bookings: bookingsJson.map(_mapBooking).toList(growable: false),
    );
  }

  Future<List<WsBookingData>> getBookings() async {
    final response =
        await _client.get('/workshop-portal/bookings') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final bookings = items.map(_mapBooking).toList(growable: false);
    MockData.setRemoteWorkshopPortal(
      profile: MockData.workshopProfile,
      bookings: bookings,
    );
    return bookings;
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _client.patch('/workshop-portal/bookings/$id/status', {'status': status});
  }

  WsBookingData _mapBooking(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['date']?.toString() ?? '');
    return WsBookingData(
      id: (json['id'] ?? '').toString(),
      serviceName: json['serviceName']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      vehicleInfo: json['vehicleInfo']?.toString() ?? '',
      date: _formatDate(timestamp),
      time: _formatTime(timestamp),
      status: _parseStatus(json['status']?.toString()),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  RequestStatus _parseStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
      case 'rejected':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return appShortDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '10:00 AM';
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

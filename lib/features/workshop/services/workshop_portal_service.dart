import '../../../core/network/api_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';

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

    AppCache.setRemoteWorkshopPortal(
      profile: WorkshopProfileData(
        id: profileJson['id']?.toString() ?? '',
        name: profileJson['name']?.toString() ?? '',
        initials: profileJson['initials']?.toString() ?? 'WS',
        specialty: profileJson['specialty']?.toString() ?? 'Full Service',
        rating: (profileJson['rating'] as num?)?.toDouble() ?? 4.8,
        isOpen: profileJson['isOpen'] == true,
        isVerified: profileJson['isVerified'] == true,
        accountStatus: profileJson['accountStatus']?.toString() ?? 'pending',
        address: profileJson['address']?.toString() ?? '',
        latitude: (profileJson['latitude'] as num?)?.toDouble(),
        longitude: (profileJson['longitude'] as num?)?.toDouble(),
        monthlyRevenue:
            (profileJson['monthlyRevenue'] as num?)?.toDouble() ?? 0,
        revenuePeriod:
            profileJson['revenuePeriod']?.toString() ?? 'Current period',
        payoutMethod:
            profileJson['payoutMethod']?.toString() ?? 'Bank Transfer',
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
    AppCache.setRemoteWorkshopPortal(
      profile: AppCache.workshopProfile,
      bookings: bookings,
    );
    return bookings;
  }

  Future<Map<String, dynamic>> getEarnings() async {
    final response =
        await _client.get('/workshop-portal/earnings') as Map<String, dynamic>;
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  Future<void> updateBookingStatus(String id, String status) async {
    await _client.patch('/workshop-portal/bookings/$id/status', {
      'status': status,
    });
    await syncDashboard();
  }

  Future<void> updateProfileLocation({
    required String workshopId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    await _client.put('/workshops/$workshopId', {
      'location': address,
      'latitude': latitude,
      'longitude': longitude,
    });
    await syncDashboard();
  }

  Future<List<WsServiceItem>> getServices() async {
    final response =
        await _client.get('/workshop-portal/services') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final services = items.map(_mapService).toList(growable: false);
    AppCache.setRemoteWorkshopPortal(
      profile: AppCache.workshopProfile,
      bookings: AppCache.workshopBookings,
      services: services,
    );
    return services;
  }

  Future<List<DateTime>> getSlots() async {
    final response =
        await _client.get('/workshop-portal/slots') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>? ?? const [])
        .map((slot) => DateTime.tryParse(slot.toString()))
        .whereType<DateTime>()
        .map((slot) => slot.toLocal())
        .toList(growable: false);
  }

  Future<List<DateTime>> updateSlots(List<DateTime> slots) async {
    final response =
        await _client.put('/workshop-portal/slots', {
              'slots': slots
                  .map((slot) => slot.toUtc().toIso8601String())
                  .toList(),
            })
            as Map<String, dynamic>;
    return (response['data'] as List<dynamic>? ?? const [])
        .map((slot) => DateTime.tryParse(slot.toString()))
        .whereType<DateTime>()
        .map((slot) => slot.toLocal())
        .toList(growable: false);
  }

  Future<WsServiceItem> addService(WsServiceItem item) async {
    final response =
        await _client.post('/workshop-portal/services', {
              'name': item.name,
              'emoji': item.emoji,
              'durationMins': item.durationMins,
              'price': item.price,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final added = _mapService(data);
    final current = AppCache.workshopServices.toList(growable: true);
    current.add(added);
    AppCache.setRemoteWorkshopServices(current);
    return added;
  }

  Future<void> deleteService(String serviceId) async {
    await _client.delete('/workshop-portal/services/$serviceId');
    final updated = AppCache.workshopServices
        .where((s) => s.id != serviceId)
        .toList();
    AppCache.setRemoteWorkshopServices(updated);
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

  WsServiceItem _mapService(Map<String, dynamic> json) {
    return WsServiceItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      emoji: json['emoji']?.toString() ?? 'Service',
      name: json['name']?.toString() ?? '',
      durationMins: (json['durationMins'] as num?)?.toInt() ?? 60,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  RequestStatus _parseStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'in_progress':
        return RequestStatus.inProgress;
      case 'diagnostics_ready':
        return RequestStatus.diagnosticsReady;
      case 'repair_in_progress':
        return RequestStatus.repairInProgress;
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

import '../../../core/network/api_client.dart';
import '../../../shared/models/admin_models.dart';
import '../../../shared/services/mock_data.dart';

class AdminService {
  AdminService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> syncDashboard() async {
    final response = await _client.get('/admin/dashboard') as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;

    final drivers = ((data['drivers'] as List<dynamic>?) ?? const [])
        .map((item) => _mapDriver(item as Map<String, dynamic>))
        .toList(growable: false);
    final workshops = ((data['workshops'] as List<dynamic>?) ?? const [])
        .map((item) => _mapWorkshop(item as Map<String, dynamic>))
        .toList(growable: false);
    final bookings = ((data['bookings'] as List<dynamic>?) ?? const [])
        .map((item) => _mapBooking(item as Map<String, dynamic>))
        .toList(growable: false);
    final services = ((data['services'] as List<dynamic>?) ?? const [])
        .map((item) => _mapService(item as Map<String, dynamic>))
        .toList(growable: false);
    final packages = ((data['packages'] as List<dynamic>?) ?? const [])
        .map((item) => _mapPackage(item as Map<String, dynamic>))
        .toList(growable: false);
    final logs = ((data['logs'] as List<dynamic>?) ?? const [])
        .map((item) => _mapLog(item as Map<String, dynamic>))
        .toList(growable: false);

    MockData.setRemoteAdminDrivers(drivers);
    MockData.setRemoteAdminWorkshops(workshops);
    MockData.setRemoteAdminBookings(bookings);
    MockData.setRemoteManagedServices(services);
    MockData.setRemoteManagedPackages(packages);
    MockData.setRemoteActivityLogs(logs);

    return data;
  }

  Future<void> refreshDrivers() async {
    final response =
        await _client.get('/admin/users?role=driver') as Map<String, dynamic>;
    final items = ((response['data'] as List<dynamic>?) ?? const [])
        .map((item) => _mapDriver(item as Map<String, dynamic>))
        .toList(growable: false);
    MockData.setRemoteAdminDrivers(items);
  }

  Future<void> refreshWorkshops() async {
    final response =
        await _client.get('/admin/users?role=workshop') as Map<String, dynamic>;
    final items = ((response['data'] as List<dynamic>?) ?? const [])
        .map((item) => _mapWorkshop(item as Map<String, dynamic>))
        .toList(growable: false);
    MockData.setRemoteAdminWorkshops(items);
  }

  Future<void> updateWorkshop({
    required String id,
    AdminAccountStatus? status,
    bool? isVerified,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) {
      payload['accountStatus'] = _accountStatusValue(status);
    }
    if (isVerified != null) {
      payload['isVerified'] = isVerified;
    }
    await _client.put('/workshops/$id', payload);
  }

  Future<void> deleteWorkshop(String id) async {
    await _client.delete('/workshops/$id');
  }

  Future<void> refreshBookings() async {
    final response = await _client.get('/admin/bookings') as Map<String, dynamic>;
    final items = ((response['data'] as List<dynamic>?) ?? const [])
        .map((item) => _mapBooking(item as Map<String, dynamic>))
        .toList(growable: false);
    MockData.setRemoteAdminBookings(items);
  }

  Future<void> refreshLogs() async {
    final response = await _client.get('/admin/logs') as Map<String, dynamic>;
    final items = ((response['data'] as List<dynamic>?) ?? const [])
        .map((item) => _mapLog(item as Map<String, dynamic>))
        .toList(growable: false);
    MockData.setRemoteActivityLogs(items);
  }

  Future<void> updateUserStatus(String id, AdminAccountStatus status) async {
    await _client.patch('/admin/users/$id/status', {'status': _accountStatusValue(status)});
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('/admin/users/$id');
  }

  Future<void> updateBookingStatus(String id, AdminBookingStatus status) async {
    await _client.patch('/admin/bookings/$id/status', {'status': status.label});
  }

  Future<void> createService(ManagedService service) async {
    await _client.post('/services', {
      'name': service.name,
      'category': service.category,
      'description': service.description,
      'emoji': service.emoji,
      'price': service.price,
      'durationMins': service.durationMins,
      'isPopular': service.isPopular,
      'isEnabled': service.isEnabled,
    });
  }

  Future<void> updateService(ManagedService service) async {
    await _client.put('/services/${service.id}', {
      'name': service.name,
      'category': service.category,
      'description': service.description,
      'emoji': service.emoji,
      'price': service.price,
      'durationMins': service.durationMins,
      'isPopular': service.isPopular,
      'isEnabled': service.isEnabled,
    });
  }

  Future<void> deleteService(String id) async {
    await _client.delete('/services/$id');
  }

  Future<void> createPackage(ManagedPackage pkg) async {
    await _client.post('/packages', {
      'name': pkg.name,
      'tagline': pkg.tagline,
      'durationMonths': _durationToMonths(pkg.duration),
      'price': pkg.price,
      'originalPrice': pkg.originalPrice,
      'features': pkg.features,
      'isPopular': pkg.isPopular,
      'isEnabled': pkg.isEnabled,
    });
  }

  Future<void> updatePackage(ManagedPackage pkg) async {
    await _client.put('/packages/${pkg.id}', {
      'name': pkg.name,
      'tagline': pkg.tagline,
      'durationMonths': _durationToMonths(pkg.duration),
      'price': pkg.price,
      'originalPrice': pkg.originalPrice,
      'features': pkg.features,
      'isPopular': pkg.isPopular,
      'isEnabled': pkg.isEnabled,
    });
  }

  Future<void> deletePackage(String id) async {
    await _client.delete('/packages/$id');
  }

  DriverUser _mapDriver(Map<String, dynamic> json) {
    return DriverUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      status: _parseAccountStatus(json['status']?.toString()),
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  WorkshopUser _mapWorkshop(Map<String, dynamic> json) {
    return WorkshopUser(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      specialty: json['specialty']?.toString() ?? 'Full Service',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalJobs: (json['totalJobs'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      isVerified: json['isVerified'] == true,
      status: _parseAccountStatus(json['status']?.toString()),
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  AdminBooking _mapBooking(Map<String, dynamic> json) {
    final timestamp = DateTime.tryParse(json['date']?.toString() ?? '');
    return AdminBooking(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      driverId: json['driverId']?.toString() ?? '',
      driverName: json['driverName']?.toString() ?? '',
      workshopId: json['workshopId']?.toString() ?? '',
      workshopName: json['workshopName']?.toString() ?? '',
      serviceId: json['serviceId']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      status: _parseBookingStatus(json['status']?.toString()),
      date: _formatDate(timestamp),
      time: _formatTime(timestamp),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash on Service',
    );
  }

  ManagedService _mapService(Map<String, dynamic> json) {
    return ManagedService(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '🔧',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationMins: (json['durationMins'] as num?)?.toInt() ?? 60,
      isPopular: json['isPopular'] == true,
      isEnabled: json['isEnabled'] != false,
    );
  }

  ManagedPackage _mapPackage(Map<String, dynamic> json) {
    return ManagedPackage(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      duration: json['duration']?.toString() ?? 'month',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0,
      features: (json['features'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      isPopular: json['isPopular'] == true,
      isEnabled: json['isEnabled'] != false,
    );
  }

  ActivityLogEntry _mapLog(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      actor: json['actor']?.toString() ?? 'System',
      action: json['action']?.toString() ?? '',
      target: json['target']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
    );
  }

  AdminAccountStatus _parseAccountStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'pending':
        return AdminAccountStatus.pending;
      case 'suspended':
        return AdminAccountStatus.suspended;
      case 'rejected':
        return AdminAccountStatus.rejected;
      case 'deleted':
        return AdminAccountStatus.deleted;
      default:
        return AdminAccountStatus.active;
    }
  }

  AdminBookingStatus _parseBookingStatus(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'active':
      case 'accepted':
        return AdminBookingStatus.active;
      case 'completed':
        return AdminBookingStatus.completed;
      case 'cancelled':
      case 'rejected':
        return AdminBookingStatus.cancelled;
      default:
        return AdminBookingStatus.pending;
    }
  }

  String _accountStatusValue(AdminAccountStatus status) {
    switch (status) {
      case AdminAccountStatus.pending:
        return 'pending';
      case AdminAccountStatus.suspended:
        return 'suspended';
      case AdminAccountStatus.rejected:
        return 'rejected';
      case AdminAccountStatus.deleted:
        return 'deleted';
      case AdminAccountStatus.active:
        return 'active';
    }
  }

  int _durationToMonths(String duration) {
    final match = RegExp(r'(\d+)').firstMatch(duration);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return duration.toLowerCase().contains('year') ? 12 : 1;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
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

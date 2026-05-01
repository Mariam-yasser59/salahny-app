import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salahny_fixed/core/network/api_client.dart';
import 'package:salahny_fixed/features/admin/admin_dashboard_screen.dart';
import 'package:salahny_fixed/features/admin/services/admin_service.dart';
import 'package:salahny_fixed/shared/models/admin_models.dart';
import 'package:salahny_fixed/shared/services/mock_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await MockData.logout();
  });

  group('Admin credentials', () {
    test('accepts the hidden super admin credentials', () {
      expect(
        MockData.validateAdminCredentials('admin@salahny.com', 'admin123'),
        isTrue,
      );
    });

    test('trims the email before checking hidden super admin credentials', () {
      expect(
        MockData.validateAdminCredentials('  admin@salahny.com  ', 'admin123'),
        isTrue,
      );
    });

    test('rejects invalid hidden super admin credentials', () {
      expect(
        MockData.validateAdminCredentials('admin@salahny.com', 'wrong'),
        isFalse,
      );
      expect(
        MockData.validateAdminCredentials('driver@salahny.com', 'admin123'),
        isFalse,
      );
    });
  });

  group('Admin model mapping', () {
    test('WorkshopUser converts to WorkshopModel correctly', () {
      final workshop = WorkshopUser(
        id: 'w-1',
        name: 'Cairo Auto Care',
        email: 'owner@cairo.com',
        phone: '01000000000',
        address: 'Nasr City',
        specialty: 'Diagnostics',
        rating: 4.7,
        totalJobs: 42,
        revenue: 1500,
        isVerified: true,
        status: AdminAccountStatus.active,
        joinedAt: DateTime(2026, 1, 1),
      );

      final model = workshop.toWorkshopModel(distance: 2.4);

      expect(model.id, 'w-1');
      expect(model.name, 'Cairo Auto Care');
      expect(model.distance, 2.4);
      expect(model.isVerified, isTrue);
      expect(model.jobsDone, 42);
      expect(model.isOpen, isTrue);
    });

    test('AdminBooking converts to BookingModel with status label', () {
      const booking = AdminBooking(
        id: 'b-1',
        driverId: 'd-1',
        driverName: 'Mariam',
        workshopId: 'w-1',
        workshopName: 'Cairo Auto Care',
        serviceId: 's-1',
        serviceName: 'Oil Change',
        status: AdminBookingStatus.active,
        date: 'May 1',
        time: '10:00 AM',
        total: 450,
        paymentMethod: 'Cash on Service',
      );

      final model = booking.toBookingModel();

      expect(model.id, 'b-1');
      expect(model.status, 'Active');
      expect(model.price, 450);
      expect(model.serviceName, 'Oil Change');
    });

    test('ManagedService converts to ServiceModel correctly', () {
      const service = ManagedService(
        id: 's-1',
        name: 'Brake Service',
        category: 'Brakes',
        description: 'Pads and inspection',
        emoji: 'BS',
        price: 199,
        durationMins: 90,
        isPopular: true,
      );

      final model = service.toServiceModel();

      expect(model.id, 's-1');
      expect(model.name, 'Brake Service');
      expect(model.price, 199);
      expect(model.isPopular, isTrue);
    });

    test('ManagedPackage converts to PackageModel correctly', () {
      const package = ManagedPackage(
        id: 'p-1',
        name: 'Premium',
        tagline: 'Best value',
        duration: '3 months',
        price: 99,
        originalPrice: 129,
        features: ['Priority support', 'Discounts'],
        isPopular: true,
      );

      final model = package.toPackageModel();

      expect(model.id, 'p-1');
      expect(model.duration, '3 months');
      expect(model.features, contains('Priority support'));
      expect(model.isPopular, isTrue);
    });
  });

  group('AdminService', () {
    test('syncDashboard maps dashboard payload into MockData caches', () async {
      final client = _FakeApiClient(
        getResponses: {
          '/admin/dashboard': {
            'data': {
              'drivers': [
                {
                  'id': 'd-1',
                  'name': 'Driver One',
                  'email': 'driver1@test.com',
                  'phone': '01011111111',
                  'status': 'active',
                  'totalBookings': 3,
                  'walletBalance': 120.0,
                  'joinedAt': '2026-05-01T10:00:00.000Z',
                },
              ],
              'workshops': [
                {
                  'id': 'w-1',
                  'name': 'Workshop One',
                  'email': 'workshop@test.com',
                  'phone': '01022222222',
                  'address': 'Cairo',
                  'specialty': 'Full Service',
                  'rating': 4.8,
                  'totalJobs': 10,
                  'revenue': 500.0,
                  'isVerified': true,
                  'status': 'active',
                  'joinedAt': '2026-05-01T10:00:00.000Z',
                },
              ],
              'bookings': [
                {
                  'id': 'b-1',
                  'driverId': 'd-1',
                  'driverName': 'Driver One',
                  'workshopId': 'w-1',
                  'workshopName': 'Workshop One',
                  'serviceId': 's-1',
                  'serviceName': 'Oil Change',
                  'status': 'accepted',
                  'date': '2026-05-01T10:00:00.000Z',
                  'total': 89.0,
                  'paymentMethod': 'Cash on Service',
                },
              ],
              'services': [
                {
                  'id': 's-1',
                  'name': 'Oil Change',
                  'category': 'Maintenance',
                  'description': 'Synthetic oil',
                  'emoji': 'OC',
                  'price': 89.0,
                  'durationMins': 45,
                  'isPopular': true,
                  'isEnabled': true,
                },
              ],
              'packages': [
                {
                  'id': 'p-1',
                  'name': 'Premium',
                  'tagline': 'Best value',
                  'duration': '3 months',
                  'price': 99.0,
                  'originalPrice': 129.0,
                  'features': ['Priority support'],
                  'isPopular': true,
                  'isEnabled': true,
                },
              ],
              'logs': [
                {
                  'id': 'l-1',
                  'timestamp': '2026-05-01T10:00:00.000Z',
                  'actor': 'Super Admin',
                  'action': 'Updated service',
                  'target': 'Oil Change',
                  'details': 'Price changed',
                },
              ],
            },
          },
        },
      );

      final service = AdminService(client: client);
      final data = await service.syncDashboard();

      expect((data['drivers'] as List).length, 1);
      expect(MockData.drivers, hasLength(1));
      expect(MockData.adminWorkshops, hasLength(1));
      expect(MockData.adminBookings, hasLength(1));
      expect(MockData.managedServices, hasLength(1));
      expect(MockData.managedPackages, hasLength(1));
      expect(MockData.activityLogs, hasLength(1));
      expect(MockData.adminBookings.first.status, AdminBookingStatus.active);
    });

    test('refreshDrivers stores mapped remote driver data', () async {
      final client = _FakeApiClient(
        getResponses: {
          '/admin/users?role=driver': {
            'data': [
              {
                'id': 'd-5',
                'name': 'Remote Driver',
                'email': 'remote@test.com',
                'phone': '01099999999',
                'status': 'pending',
                'totalBookings': 0,
                'walletBalance': 0.0,
                'joinedAt': '2026-05-01T10:00:00.000Z',
              },
            ],
          },
        },
      );

      await AdminService(client: client).refreshDrivers();

      expect(MockData.drivers, hasLength(1));
      expect(MockData.drivers.first.name, 'Remote Driver');
      expect(MockData.drivers.first.status, AdminAccountStatus.pending);
    });

    test('updateUserStatus sends expected payload', () async {
      final client = _FakeApiClient();

      await AdminService(client: client).updateUserStatus(
        'driver-7',
        AdminAccountStatus.suspended,
      );

      expect(client.lastPatchPath, '/admin/users/driver-7/status');
      expect(client.lastPatchBody, {'status': 'suspended'});
    });

    test('updateBookingStatus sends booking label payload', () async {
      final client = _FakeApiClient();

      await AdminService(client: client).updateBookingStatus(
        'booking-7',
        AdminBookingStatus.completed,
      );

      expect(client.lastPatchPath, '/admin/bookings/booking-7/status');
      expect(client.lastPatchBody, {'status': 'Completed'});
    });

    test('createPackage converts year duration to 12 months', () async {
      final client = _FakeApiClient();
      const package = ManagedPackage(
        id: 'p-2',
        name: 'Fleet',
        tagline: 'Annual plan',
        duration: 'year',
        price: 599,
        originalPrice: 899,
        features: ['Dedicated manager'],
      );

      await AdminService(client: client).createPackage(package);

      expect(client.lastPostPath, '/packages');
      expect(client.lastPostBody?['durationMonths'], 12);
      expect(client.lastPostBody?['name'], 'Fleet');
    });
  });

  group('Admin widgets', () {
    testWidgets('admin dashboard view renders command center summary',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SuperAdminDashboardView()),
        ),
      );
      await tester.pump();

      expect(find.text('Platform command center'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Total Drivers'), findsOneWidget);
      expect(find.text('Pending Approvals'), findsOneWidget);
    });
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    this.getResponses = const {},
    this.postResponses = const {},
    this.putResponses = const {},
    this.patchResponses = const {},
    this.deleteResponses = const {},
  });

  final Map<String, dynamic> getResponses;
  final Map<String, dynamic> postResponses;
  final Map<String, dynamic> putResponses;
  final Map<String, dynamic> patchResponses;
  final Map<String, dynamic> deleteResponses;

  String? lastGetPath;
  String? lastPostPath;
  String? lastPutPath;
  String? lastPatchPath;
  String? lastDeletePath;
  Map<String, dynamic>? lastPostBody;
  Map<String, dynamic>? lastPutBody;
  Map<String, dynamic>? lastPatchBody;

  @override
  Future<dynamic> get(String path, {bool auth = true}) async {
    lastGetPath = path;
    return getResponses[path] ?? {'data': []};
  }

  @override
  Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return postResponses[path] ?? {'success': true};
  }

  @override
  Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    lastPutPath = path;
    lastPutBody = body;
    return putResponses[path] ?? {'success': true};
  }

  @override
  Future<dynamic> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    lastPatchPath = path;
    lastPatchBody = body;
    return patchResponses[path] ?? {'success': true};
  }

  @override
  Future<dynamic> delete(String path, {bool auth = true}) async {
    lastDeletePath = path;
    return deleteResponses[path] ?? {'success': true};
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:salahny_fixed/core/network/api_client.dart';
import 'package:salahny_fixed/features/admin/services/admin_service.dart';
import 'package:salahny_fixed/shared/models/admin_models.dart';
import 'package:salahny_fixed/shared/services/mock_data.dart';

void main() {
  group('Test — Happy Path', () {
    test('admin credentials succeed with the hidden admin account', () {
      expect(
        MockData.validateAdminCredentials('admin@salahny.com', 'admin123'),
        isTrue,
      );
    });

    test('admin can create a package payload correctly', () async {
      final client = _MatrixFakeApiClient();
      const package = ManagedPackage(
        id: 'pkg-happy',
        name: 'Premium Plus',
        tagline: 'Best value for drivers',
        duration: '3 months',
        price: 199,
        originalPrice: 249,
        features: ['Priority support', 'Service discounts'],
        isPopular: true,
      );

      await AdminService(client: client).createPackage(package);

      expect(client.lastPostPath, '/packages');
      expect(client.lastPostBody?['name'], 'Premium Plus');
      expect(client.lastPostBody?['durationMonths'], 3);
      expect(client.lastPostBody?['features'], contains('Priority support'));
    });

    test('admin can refresh workshop data from backend', () async {
      final client = _MatrixFakeApiClient(
        getResponses: {
          '/admin/users?role=workshop': {
            'data': [
              {
                'id': 'w-happy',
                'name': 'Prime Workshop',
                'email': 'prime@shop.com',
                'phone': '01045678901',
                'address': 'Cairo',
                'specialty': 'Diagnostics',
                'rating': 4.9,
                'totalJobs': 20,
                'revenue': 3200.0,
                'isVerified': true,
                'status': 'active',
                'joinedAt': '2026-05-01T10:00:00.000Z',
              },
            ],
          },
        },
      );

      await AdminService(client: client).refreshWorkshops();

      expect(MockData.adminWorkshops, hasLength(1));
      expect(MockData.adminWorkshops.first.name, 'Prime Workshop');
      expect(MockData.adminWorkshops.first.status, AdminAccountStatus.active);
    });
  });

  group('Test — Edge Cases', () {
    test('admin credentials accept trimmed email input', () {
      expect(
        MockData.validateAdminCredentials('  admin@salahny.com  ', 'admin123'),
        isTrue,
      );
    });

    test('package yearly duration is normalized to 12 months', () async {
      final client = _MatrixFakeApiClient();
      const package = ManagedPackage(
        id: 'pkg-edge',
        name: 'Fleet Annual',
        tagline: 'Annual billing',
        duration: 'year',
        price: 599,
        originalPrice: 799,
        features: ['Dedicated manager'],
      );

      await AdminService(client: client).updatePackage(package);

      expect(client.lastPutPath, '/packages/pkg-edge');
      expect(client.lastPutBody?['durationMonths'], 12);
    });

    test('empty remote logs response does not crash admin sync', () async {
      final client = _MatrixFakeApiClient(
        getResponses: {
          '/admin/logs': {'data': []},
        },
      );

      await AdminService(client: client).refreshLogs();

      expect(MockData.activityLogs, isEmpty);
    });
  });

  group('Test — Negative Cases', () {
    test('admin credentials reject wrong password', () {
      expect(
        MockData.validateAdminCredentials('admin@salahny.com', 'wrong-pass'),
        isFalse,
      );
    });

    test('admin credentials reject non-admin email', () {
      expect(
        MockData.validateAdminCredentials('driver@salahny.com', 'admin123'),
        isFalse,
      );
    });

    test('malformed backend workshop payload falls back safely', () async {
      final client = _MatrixFakeApiClient(
        getResponses: {
          '/admin/users?role=workshop': {
            'data': [
              {
                'id': 'w-bad',
                'name': null,
                'email': null,
                'phone': null,
                'address': null,
                'specialty': null,
                'rating': null,
                'totalJobs': null,
                'revenue': null,
                'isVerified': false,
                'status': 'unknown-status',
                'joinedAt': 'not-a-date',
              },
            ],
          },
        },
      );

      await AdminService(client: client).refreshWorkshops();

      expect(MockData.adminWorkshops, hasLength(1));
      expect(MockData.adminWorkshops.first.name, '');
      expect(MockData.adminWorkshops.first.status, AdminAccountStatus.active);
      expect(MockData.adminWorkshops.first.specialty, 'Full Service');
    });
  });
}

class _MatrixFakeApiClient extends ApiClient {
  _MatrixFakeApiClient({
    this.getResponses = const {},
    this.postResponses = const {},
    this.putResponses = const {},
  });

  final Map<String, dynamic> getResponses;
  final Map<String, dynamic> postResponses;
  final Map<String, dynamic> putResponses;

  String? lastPostPath;
  String? lastPutPath;
  Map<String, dynamic>? lastPostBody;
  Map<String, dynamic>? lastPutBody;

  @override
  Future<dynamic> get(String path, {bool auth = true}) async {
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
}

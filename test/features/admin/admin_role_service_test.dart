import 'package:flutter_test/flutter_test.dart';
import 'package:salahny_fixed/core/network/api_client.dart';
import 'package:salahny_fixed/features/admin/services/admin_service.dart';
import 'package:salahny_fixed/shared/models/admin_models.dart';
import 'package:salahny_fixed/shared/services/app_cache.dart';

void main() {
  group('AdminService package management', () {
    test('createPackage sends package payload with duration in months', () async {
      final client = _FakeApiClient();
      const package = ManagedPackage(
        id: 'pkg-1',
        name: 'Premium Care',
        tagline: 'Priority support',
        duration: '6 months',
        price: 249,
        originalPrice: 299,
        features: ['Priority booking', '2 free inspections'],
        isPopular: true,
      );

      await AdminService(client: client).createPackage(package);

      expect(client.lastPostPath, '/packages');
      expect(client.lastPostBody, {
        'name': 'Premium Care',
        'tagline': 'Priority support',
        'durationMonths': 6,
        'price': 249.0,
        'originalPrice': 299.0,
        'features': ['Priority booking', '2 free inspections'],
        'isPopular': true,
        'isEnabled': true,
      });
    });

    test('updatePackage converts yearly duration to 12 months', () async {
      final client = _FakeApiClient();
      const package = ManagedPackage(
        id: 'pkg-2',
        name: 'Fleet Max',
        tagline: 'Annual cover',
        duration: 'yearly',
        price: 799,
        originalPrice: 999,
        features: ['Fleet dashboard', 'Priority hotline'],
      );

      await AdminService(client: client).updatePackage(package);

      expect(client.lastPutPath, '/packages/pkg-2');
      expect(client.lastPutBody?['durationMonths'], 12);
      expect(client.lastPutBody?['name'], 'Fleet Max');
    });

    test('deletePackage targets the selected package endpoint', () async {
      final client = _FakeApiClient();

      await AdminService(client: client).deletePackage('pkg-9');

      expect(client.lastDeletePath, '/packages/pkg-9');
    });
  });

  group('AdminService remote mapping', () {
    test('refreshWorkshops stores mapped workshop list from backend', () async {
      final client = _FakeApiClient(
        getResponses: {
          '/admin/users?role=workshop': {
            'data': [
              {
                'id': 'w-9',
                'name': 'Alex Motors',
                'email': 'alex@motors.com',
                'phone': '01012345678',
                'address': 'Giza',
                'specialty': 'Engine',
                'rating': 4.5,
                'totalJobs': 18,
                'revenue': 2200.0,
                'isVerified': true,
                'status': 'active',
                'joinedAt': '2026-05-01T10:00:00.000Z',
              },
            ],
          },
        },
      );

      await AdminService(client: client).refreshWorkshops();

      expect(AppCache.adminWorkshops, hasLength(1));
      expect(AppCache.adminWorkshops.first.name, 'Alex Motors');
      expect(AppCache.adminWorkshops.first.status, AdminAccountStatus.active);
      expect(AppCache.adminWorkshops.first.isVerified, isTrue);
    });

    test('refreshLogs stores mapped admin activity logs from backend', () async {
      final client = _FakeApiClient(
        getResponses: {
          '/admin/logs': {
            'data': [
              {
                'id': 'log-22',
                'timestamp': '2026-05-01T10:00:00.000Z',
                'actor': 'Super Admin',
                'action': 'Package updated',
                'target': 'Premium Care',
                'details': 'Price updated to 249',
              },
            ],
          },
        },
      );

      await AdminService(client: client).refreshLogs();

      expect(AppCache.activityLogs, hasLength(1));
      expect(AppCache.activityLogs.first.action, 'Package updated');
      expect(AppCache.activityLogs.first.target, 'Premium Care');
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

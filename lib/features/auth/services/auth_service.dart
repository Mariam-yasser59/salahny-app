import '../../../core/network/api_client.dart';
import '../../../core/notifications/firebase_push_service.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? expectedRole,
  }) async {
    final response =
    await _client.post('/auth/login', {
      'email': email,
      'password': password,
      if (expectedRole != null) 'expectedRole': expectedRole,
    }, auth: false)
    as Map<String, dynamic>;

    final data = _unwrapData(response);
    await _saveAuth(data);
    return data;
  }

  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    final response =
    await _client.post('/auth/google', {
      'idToken': idToken,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (photoUrl != null) 'photoUrl': photoUrl,
    }, auth: false)
    as Map<String, dynamic>;

    final data = _unwrapData(response);
    await _saveAuth(data);
    return data;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    return await _client.post('/auth/forgot-password', {
      'email': email,
    }, auth: false)
    as Map<String, dynamic>;
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _client.post('/auth/reset-password', {
      'token': token,
      'password': password,
    }, auth: false);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response =
    await _client.post('/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    }, auth: false)
    as Map<String, dynamic>;

    final data = _unwrapData(response);
    await _saveAuth(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get('/users/me') as Map<String, dynamic>;
    return _unwrapData(response);
  }

  Future<void> deleteAccount() async {
    await _client.delete('/auth/me');
    await TokenStorage.clear();
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>?;

    await TokenStorage.saveSession(
      token: data['token']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString(),
      role: user?['role']?.toString(),
    );

    await FirebasePushService.instance.registerDeviceToken();
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is Map<String, dynamic>) {
      return data;
    }

    return response;
  }
}
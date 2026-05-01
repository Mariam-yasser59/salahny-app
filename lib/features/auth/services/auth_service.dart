import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      {'email': email, 'password': password},
      auth: false,
    ) as Map<String, dynamic>;
    final data = _unwrapData(response);
    await _saveAuth(data);
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _client.post(
      '/auth/register',
      {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      },
      auth: false,
    ) as Map<String, dynamic>;
    final data = _unwrapData(response);
    await _saveAuth(data);
    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get('/users/me') as Map<String, dynamic>;
    return _unwrapData(response);
  }

  Future<void> logout() async {
    await TokenStorage.clear();
  }

  Future<void> _saveAuth(Map<String, dynamic> data) async {
    final user = data['user'] as Map<String, dynamic>?;
    await TokenStorage.saveSession(
      token: data['token']?.toString() ?? '',
      role: user?['role']?.toString(),
    );
  }

  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }
}

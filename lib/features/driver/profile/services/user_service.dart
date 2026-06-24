import '../../../../core/network/api_client.dart';
import '../../../../shared/services/app_cache.dart';

class UserService {
  UserService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/users/me') as Map<String, dynamic>;
    final data = (response['data'] as Map<String, dynamic>?) ?? response;
    await AppCache.saveCurrentUser(
      name: data['name']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString(),
    );
    return data;
  }

  Future<Map<String, dynamic>> updateMe({
    required String name,
    required String phone,
    required String email,
  }) async {
    final response = await _client.patch('/users/me', {
      'name': name,
      'phone': phone,
      'email': email,
    }) as Map<String, dynamic>;
    final data = (response['data'] as Map<String, dynamic>?) ?? response;
    await AppCache.saveCurrentUser(
      name: data['name']?.toString() ?? name,
      phone: data['phone']?.toString() ?? phone,
      email: data['email']?.toString() ?? email,
      role: data['role']?.toString(),
    );
    return data;
  }
}

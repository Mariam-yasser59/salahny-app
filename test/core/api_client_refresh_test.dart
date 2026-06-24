import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salahny_fixed/core/network/api_client.dart';
import 'package:salahny_fixed/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retries once after refresh token rotation', () async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.saveSession(
      token: 'expired-token',
      refreshToken: 'refresh-1',
    );

    var profileAttempts = 0;
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        return http.Response(
          jsonEncode({
            'data': {'token': 'fresh-token', 'refreshToken': 'refresh-2'},
          }),
          200,
        );
      }
      profileAttempts += 1;
      if (profileAttempts == 1) {
        expect(request.headers['Authorization'], 'Bearer expired-token');
        return http.Response(jsonEncode({'message': 'expired'}), 401);
      }
      expect(request.headers['Authorization'], 'Bearer fresh-token');
      return http.Response(
        jsonEncode({
          'data': {'id': 'driver-1'},
        }),
        200,
      );
    });

    final result = await ApiClient(client: client).get('/users/me');

    expect((result as Map<String, dynamic>)['data']['id'], 'driver-1');
    expect(await TokenStorage.getToken(), 'fresh-token');
    expect(await TokenStorage.getRefreshToken(), 'refresh-2');
    expect(profileAttempts, 2);
  });
}

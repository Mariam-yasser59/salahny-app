import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<dynamic> get(String path, {bool auth = true}) {
    return _send('GET', path, auth: auth);
  }

  Future<dynamic> post(
      String path,
      Map<String, dynamic> body, {
        bool auth = true,
      }) {
    return _send('POST', path, body: body, auth: auth);
  }

  Future<dynamic> put(
      String path,
      Map<String, dynamic> body, {
        bool auth = true,
      }) {
    return _send('PUT', path, body: body, auth: auth);
  }

  Future<dynamic> patch(
      String path,
      Map<String, dynamic> body, {
        bool auth = true,
      }) {
    return _send('PATCH', path, body: body, auth: auth);
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _send('DELETE', path, auth: auth);
  }

  Future<dynamic> _send(
      String method,
      String path, {
        Map<String, dynamic>? body,
        bool auth = true,
      }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (auth) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final requestBody = body == null ? null : jsonEncode(body);
    late final http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: requestBody)
              .timeout(ApiConstants.timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: requestBody)
              .timeout(ApiConstants.timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: requestBody)
              .timeout(ApiConstants.timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(ApiConstants.timeout);
          break;
        default:
          response = await _client
              .get(uri, headers: headers)
              .timeout(ApiConstants.timeout);
      }
    } catch (_) {
      throw const ApiException(
        'Could not reach the Salahny server. Check the backend URL and network.',
      );
    }

    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (auth && response.statusCode == 401 && path != '/auth/refresh') {
      final refreshed = await _refreshSession();
      if (refreshed) {
        return _send(method, path, body: body, auth: auth);
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['detail'] ?? decoded['message'] ?? 'Request failed')
          .toString()
          : 'Request failed';

      throw ApiException(message, statusCode: response.statusCode);
    }

    return decoded;
  }

  Future<bool> _refreshSession() async {
    final refreshToken = await TokenStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _client
          .post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      )
          .timeout(ApiConstants.timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>? ?? decoded;

      await TokenStorage.saveSession(
        token: data['token']?.toString() ?? '',
        refreshToken: data['refreshToken']?.toString(),
      );

      return true;
    } catch (_) {
      return false;
    }
  }
}
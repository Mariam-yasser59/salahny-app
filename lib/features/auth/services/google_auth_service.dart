import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/network/api_client.dart';
import 'auth_service.dart';

class GoogleAuthService {
  GoogleAuthService({AuthService? authService})
      : _authService = authService ?? AuthService();

  static const _clientId = String.fromEnvironment('SALAHNY_GOOGLE_CLIENT_ID');

  static const _serverClientId = String.fromEnvironment(
    'SALAHNY_GOOGLE_SERVER_CLIENT_ID',
  );

  static const bool isConfigured =
      _clientId.length > 0 || _serverClientId.length > 0;

  final AuthService _authService;

  Future<Map<String, dynamic>> signIn() async {
    try {
      debugPrint('GOOGLE_LOGIN: started');
      debugPrint('GOOGLE_LOGIN: clientId=$_clientId');
      debugPrint('GOOGLE_LOGIN: serverClientId=$_serverClientId');

      if (!isConfigured) {
        throw const ApiException(
          'Google sign-in is not configured for this build.',
        );
      }

      final signIn = GoogleSignIn.instance;

      await signIn.initialize(
        clientId: _clientId.isEmpty ? null : _clientId,
        serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
      );

      debugPrint('GOOGLE_LOGIN: initialized');

      final account = await signIn.authenticate();

      debugPrint('GOOGLE_LOGIN: authenticated email=${account.email}');

      final idToken = account.authentication.idToken;

      debugPrint(
        'GOOGLE_LOGIN: idToken is ${idToken == null ? "NULL" : "NOT NULL"}',
      );

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException('Google did not return an ID token.');
      }

      debugPrint('GOOGLE_LOGIN: sending token to backend');

      final result = await _authService.googleLogin(
        idToken: idToken,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
      );

      debugPrint('GOOGLE_LOGIN: backend success');

      return result;
    } catch (e, st) {
      debugPrint('GOOGLE_LOGIN_ERROR: $e');
      debugPrint('GOOGLE_LOGIN_STACK: $st');
      rethrow;
    }
  }
}
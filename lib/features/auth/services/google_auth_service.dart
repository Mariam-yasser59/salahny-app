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

    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw const ApiException('Google did not return an ID token.');
    }

    return _authService.googleLogin(
      idToken: idToken,
      email: account.email,
      name: account.displayName,
      photoUrl: account.photoUrl,
    );
  }
}
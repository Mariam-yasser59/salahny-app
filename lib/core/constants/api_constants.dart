class ApiConstants {
  ApiConstants._();

  // Android emulator: http://10.0.2.2:5000
  // iOS simulator/desktop: http://localhost:5000
  // Real device: use your laptop IP, for example http://192.168.1.20:5000
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  static const Duration timeout = Duration(seconds: 20);
}

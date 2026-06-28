class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'SALAHNY_API_BASE_URL',
    defaultValue: 'https://salahnybackend-production.up.railway.app/api',
  );

  static const Duration timeout = Duration(seconds: 30);
}

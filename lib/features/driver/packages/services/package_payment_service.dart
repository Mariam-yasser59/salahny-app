import '../../../../core/network/api_client.dart';

class PackagePaymentService {
  PackagePaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> purchasePackage({
    required String packageId,
    required String paymentMethod,
  }) async {
    final response = await _client.post('/payments/packages', {
      'packageId': packageId,
      'paymentMethod': paymentMethod,
    }) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data;
  }
}

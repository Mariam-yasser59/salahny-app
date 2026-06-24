import '../../../../core/network/api_client.dart';

class PackagePaymentService {
  PackagePaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> getPaymentConfig() async {
    final response =
        await _client.get('/payments/config') as Map<String, dynamic>;
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  Future<Map<String, dynamic>> purchasePackage({
    required String packageId,
    required String paymentMethod,
    String? paymentIntentId,
  }) async {
    final response =
        await _client.post('/payments/packages', {
              'packageId': packageId,
              'paymentMethod': paymentMethod,
              if (paymentIntentId != null) 'paymentIntentId': paymentIntentId,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    return data;
  }

  Future<Map<String, dynamic>> createPaymentIntent({
    required String packageId,
  }) async {
    final response =
        await _client.post('/payments/packages/intent', {
              'packageId': packageId,
            })
            as Map<String, dynamic>;
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  Future<Map<String, dynamic>> completeDemoOnlineSubscriptionPayment({
    required String planId,
    required double amount,
    required String cardLast4,
  }) async {
    final response =
        await _client.post('/subscriptions/demo-online-payment', {
              'planId': planId,
              'amount': amount,
              'cardLast4': cardLast4,
            })
            as Map<String, dynamic>;
    return response;
  }
}

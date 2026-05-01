import '../../../../core/network/api_client.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/mock_data.dart';

class DiagnosticsService {
  DiagnosticsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<DiagnosticReport>> getHistory() async {
    final response = await _client.get('/diagnostics') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final reports = items.map(_mapReport).toList(growable: false);
    MockData.setRemoteDiagnostics(reports);
    return reports;
  }

  Future<DiagnosticReport> scan({required String vehicleId}) async {
    final response = await _client.post('/diagnostics/scan', {
      'vehicleId': vehicleId,
    }) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final report = _mapReport(data);
    MockData.setLatestDiagnosticReport(report);
    return report;
  }

  DiagnosticReport _mapReport(Map<String, dynamic> json) {
    return DiagnosticReport(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      vehicleId: json['vehicleId']?.toString() ?? '',
      date: _formatDate(DateTime.tryParse(json['date']?.toString() ?? '')),
      summary: json['summary']?.toString() ?? '',
      riskLevel: _parseRisk(json['riskLevel']?.toString()),
      health: (json['health'] as num?)?.toDouble() ?? 0,
      faultCodes: (json['faultCodes'] as List<dynamic>? ?? const [])
          .map(
            (item) => OBDFaultCode(
              code: (item as Map<String, dynamic>)['code']?.toString() ?? '',
              description: item['description']?.toString() ?? '',
              level: _parseRisk(item['level']?.toString()),
            ),
          )
          .toList(growable: false),
      vitals: (json['vitals'] as List<dynamic>? ?? const [])
          .map(
            (item) => OBDVital(
              key: (item as Map<String, dynamic>)['key']?.toString() ?? '',
              value: (item['value'] as num?)?.toDouble() ?? 0,
              unit: item['unit']?.toString() ?? '',
            ),
          )
          .toList(growable: false),
      recommendations: (json['recommendations'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      aiPrediction: (json['aiPrediction'] as Map<String, dynamic>?) == null
          ? null
          : AIPrediction(
              issue: json['aiPrediction']['issue']?.toString() ?? '',
              confidence:
                  (json['aiPrediction']['confidence'] as num?)?.toDouble() ?? 0,
              urgency: _parseRisk(json['aiPrediction']['urgency']?.toString()),
              recommendation:
                  json['aiPrediction']['recommendation']?.toString() ?? '',
              technicalNote:
                  json['aiPrediction']['technicalNote']?.toString() ?? '',
              estimatedRepair:
                  json['aiPrediction']['estimatedRepair']?.toString() ?? '',
            ),
    );
  }

  RiskLevel _parseRisk(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'critical':
        return RiskLevel.critical;
      case 'warning':
        return RiskLevel.warning;
      default:
        return RiskLevel.healthy;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return appShortDate();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

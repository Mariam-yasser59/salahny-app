import 'dart:convert';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/services/app_cache.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class DiagnosticsService {
  DiagnosticsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<DiagnosticReport>> getHistory() async {
    final response = await _client.get('/diagnostics') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final reports = items.map(_mapReport).toList(growable: false);
    AppCache.setRemoteDiagnostics(reports);
    return reports;
  }

  Future<DiagnosticReport> getAiReportById(String reportId) async {
    final response =
        await _client.get('/diagnostics/$reportId') as Map<String, dynamic>;
    final report = _mapReport(
      response['data'] as Map<String, dynamic>? ?? response,
    );
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> scan({
    required String vehicleId,
    Map<String, double>? sensorReadings,
    List<String>? faultCodes,
  }) async {
    final response =
        await _client.post('/diagnostics/scan', {
              'vehicleId': vehicleId,
              if (sensorReadings != null) 'sensorReadings': sensorReadings,
              if (faultCodes != null) 'faultCodes': faultCodes,
            })
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final report = _mapReport(data);
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> uploadObdFile({
    required String vehicleId,
    required PlatformFile file,
  }) async {
    final token = await TokenStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/diagnostics/upload-obd'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['vehicleId'] = vehicleId;
    request.files.add(await _multipartFile(file));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFromBody(body),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final report = _mapReport(decoded['data'] as Map<String, dynamic>);
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> scanWorkshopBooking({
    required String bookingId,
    required Map<String, double> sensorReadings,
    List<String>? faultCodes,
  }) async {
    final response =
        await _client.post('/diagnostics/workshop/$bookingId/run', {
              'sensorReadings': sensorReadings,
              if (faultCodes != null) 'faultCodes': faultCodes,
            })
            as Map<String, dynamic>;
    final report = _mapReport(
      response['data'] as Map<String, dynamic>? ?? response,
    );
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> uploadWorkshopObdFile({
    required String bookingId,
    required PlatformFile file,
  }) async {
    final token = await TokenStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        '${ApiConstants.baseUrl}/diagnostics/workshop/$bookingId/upload-obd',
      ),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await _multipartFile(file));
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _messageFromBody(body),
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final report = _mapReport(decoded['data'] as Map<String, dynamic>);
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> sendReportToDriver(String reportId) async {
    final response =
        await _client.post('/diagnostics/$reportId/send-to-driver', {})
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final reportJson = data['report'] as Map<String, dynamic>? ?? data;
    final report = _mapReport(reportJson);
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  Future<DiagnosticReport> createRepairTask(String reportId) async {
    final response =
        await _client.post('/diagnostics/$reportId/create-repair-task', {})
            as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final reportJson = data['report'] as Map<String, dynamic>? ?? data;
    final report = _mapReport(reportJson);
    AppCache.setLatestDiagnosticReport(report);
    return report;
  }

  DiagnosticReport _mapReport(Map<String, dynamic> json) {
    return DiagnosticReport(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      vehicleId: json['vehicleId']?.toString() ?? '',
      workshopId: json['workshopId']?.toString(),
      bookingId: json['bookingId']?.toString(),
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
              hasFault: json['aiPrediction']['hasFault'] == true,
              issue: json['aiPrediction']['issue']?.toString() ?? '',
              confidence:
                  (json['aiPrediction']['confidence'] as num?)?.toDouble() ?? 0,
              urgency: _parseRisk(json['aiPrediction']['urgency']?.toString()),
              explanation:
                  json['aiPrediction']['explanation']?.toString() ?? '',
              recommendation:
                  json['aiPrediction']['recommendation']?.toString() ?? '',
              technicalNote:
                  json['aiPrediction']['technicalNote']?.toString() ?? '',
              estimatedRepair:
                  json['aiPrediction']['estimatedRepair']?.toString() ?? '',
              modelSource:
                  json['aiPrediction']['modelSource']?.toString() ?? '',
            ),
      sentToDriverAt: DateTime.tryParse(
        json['sentToDriverAt']?.toString() ?? '',
      ),
      repairTaskCreatedAt: DateTime.tryParse(
        json['repairTaskCreatedAt']?.toString() ?? '',
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

  String _messageFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['detail'] ?? decoded['message'] ?? 'Request failed')
            .toString();
      }
    } catch (_) {}
    return body.isEmpty ? 'Request failed' : body;
  }

  Future<http.MultipartFile> _multipartFile(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null) {
      return http.MultipartFile.fromBytes('file', bytes, filename: file.name);
    }

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const ApiException('Selected OBD file could not be read.');
    }

    return http.MultipartFile.fromPath('file', path, filename: file.name);
  }
}

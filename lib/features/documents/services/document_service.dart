import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_client.dart';

class VerificationDocumentItem {
  const VerificationDocumentItem({
    required this.id,
    required this.kind,
    required this.originalName,
    required this.status,
    required this.aiVerificationStatus,
    required this.aiConfidence,
    required this.aiExtractedFields,
    required this.aiIssues,
  });
  final String id;
  final String kind;
  final String originalName;
  final String status;
  final String aiVerificationStatus;
  final double? aiConfidence;
  final Map<String, dynamic> aiExtractedFields;
  final List<String> aiIssues;
}

class DocumentService {
  final _client = ApiClient();

  Future<List<VerificationDocumentItem>> myDocuments() async {
    final response = await _client.get('/documents/me') as Map<String, dynamic>;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return items
        .map(
          (item) => VerificationDocumentItem(
            id: item['id']?.toString() ?? '',
            kind: item['kind']?.toString() ?? '',
            originalName: item['originalName']?.toString() ?? '',
            status: item['status']?.toString() ?? '',
            aiVerificationStatus:
                item['aiVerificationStatus']?.toString() ?? '',
            aiConfidence: (item['aiConfidence'] as num?)?.toDouble(),
            aiExtractedFields:
                (item['aiExtractedFields'] as Map<String, dynamic>?) ??
                const {},
            aiIssues: (item['aiIssues'] as List<dynamic>? ?? const [])
                .map((item) => item.toString())
                .toList(growable: false),
          ),
        )
        .toList();
  }

  Future<VerificationDocumentItem> upload({
    required String kind,
    required PlatformFile file,
  }) async {
    final token = await TokenStorage.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/documents'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['kind'] = kind;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
        contentType: _contentTypeFor(file),
      ),
    );
    final response = await request.send();
    final raw = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException('Could not upload document.');
    }
    final decoded = raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    final item = decoded['data'] as Map<String, dynamic>? ?? const {};
    return VerificationDocumentItem(
      id: item['id']?.toString() ?? '',
      kind: item['kind']?.toString() ?? '',
      originalName: item['originalName']?.toString() ?? '',
      status: item['status']?.toString() ?? '',
      aiVerificationStatus: item['aiVerificationStatus']?.toString() ?? '',
      aiConfidence: (item['aiConfidence'] as num?)?.toDouble(),
      aiExtractedFields:
          (item['aiExtractedFields'] as Map<String, dynamic>?) ?? const {},
      aiIssues: (item['aiIssues'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  MediaType _contentTypeFor(PlatformFile file) {
    switch (file.extension?.toLowerCase()) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'png':
        return MediaType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  Future<List<Map<String, dynamic>>> adminDocuments() async {
    final response =
        await _client.get('/admin/verifications') as Map<String, dynamic>;
    return (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  Future<Uri> documentViewUri(String id) async {
    final token = await TokenStorage.getToken();
    return Uri.parse(
      '${ApiConstants.baseUrl}/documents/$id/file',
    ).replace(queryParameters: {'token': token ?? ''});
  }

  Future<void> review(
    String id,
    String status, {
    String reviewNotes = '',
  }) async {
    await _client.patch(
      status == 'approved'
          ? '/admin/verifications/$id/approve'
          : '/admin/verifications/$id/reject',
      {'status': status, 'reviewNotes': reviewNotes},
    );
  }

  Future<void> reverify(String id, {bool admin = false}) async {
    await _client.post(
      admin ? '/admin/verifications/$id/reverify' : '/documents/$id/reverify',
      {},
    );
  }
}

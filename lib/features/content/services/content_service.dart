import '../../../core/network/api_client.dart';
import '../../../shared/models/admin_models.dart';
import '../../../shared/services/mock_data.dart';

class ContentService {
  ContentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AdminSettingsData> getPublicContent() async {
    final response =
        await _client.get('/content/public-content', auth: false) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final settings = AdminSettingsData(
      privacyPolicy: data['privacyPolicy']?.toString() ?? '',
      aboutContent: data['aboutContent']?.toString() ?? '',
      announcementTitle: data['announcementTitle']?.toString() ?? '',
      announcementBody: data['announcementBody']?.toString() ?? '',
      notificationsEnabled: data['notificationsEnabled'] == true,
    );
    MockData.setRemoteAdminSettings(settings);
    return settings;
  }

  Future<AdminSettingsData> getAdminSettings() async {
    final response = await _client.get('/content/admin/settings') as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final settings = AdminSettingsData(
      privacyPolicy: data['privacyPolicy']?.toString() ?? '',
      aboutContent: data['aboutContent']?.toString() ?? '',
      announcementTitle: data['announcementTitle']?.toString() ?? '',
      announcementBody: data['announcementBody']?.toString() ?? '',
      notificationsEnabled: data['notificationsEnabled'] == true,
    );
    MockData.setRemoteAdminSettings(settings);
    return settings;
  }

  Future<void> updateAdminSettings(AdminSettingsData settings) async {
    await _client.put('/content/admin/settings', {
      'privacyPolicy': settings.privacyPolicy,
      'aboutContent': settings.aboutContent,
      'announcementTitle': settings.announcementTitle,
      'announcementBody': settings.announcementBody,
      'notificationsEnabled': settings.notificationsEnabled,
    });
    MockData.setRemoteAdminSettings(settings);
  }

  Future<void> updateAdminPassword(String password) async {
    await _client.put('/content/admin/settings/password', {'password': password});
  }
}

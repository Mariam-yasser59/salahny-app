import 'package:flutter/material.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../content/services/content_service.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _contentService = ContentService();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppErrorHandler.guard<void>(
      context,
      () => _contentService.getPublicContent(),
      fallbackMessage: 'Could not load the privacy policy right now.',
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final privacy = MockData.adminSettings.privacyPolicy.trim();
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Privacy Policy'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ACard(
                    child: Text(
                      privacy.isEmpty
                          ? 'No privacy policy has been published yet.'
                          : privacy,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AC.t3,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

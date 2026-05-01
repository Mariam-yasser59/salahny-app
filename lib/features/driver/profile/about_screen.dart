import 'package:flutter/material.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../content/services/content_service.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
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
      fallbackMessage: 'Could not load the about content right now.',
    );
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final about = MockData.adminSettings.aboutContent.trim();
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'About'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AC.red))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: AC.redGrad,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AC.red.withOpacity(0.45),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'S',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'SALAHNY',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AC.t1,
                      letterSpacing: 3,
                    ),
                  ),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(fontSize: 13, color: AC.t3),
                  ),
                  const SizedBox(height: 20),
                  ACard(
                    child: Text(
                      about.isEmpty
                          ? 'No about content has been published yet.'
                          : about,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AC.t2,
                        height: 1.7,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

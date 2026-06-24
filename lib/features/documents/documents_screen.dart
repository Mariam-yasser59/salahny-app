import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _service = DocumentService();
  List<VerificationDocumentItem> _docs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await AppErrorHandler.guard(context, _service.myDocuments);
    if (!mounted) return;
    setState(() {
      _docs = docs ?? const [];
      _loading = false;
    });
  }

  Future<void> _upload(String kind) async {
    final picked = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final file = picked?.files.isEmpty == true ? null : picked?.files.first;
    if (file == null) return;
    await AppErrorHandler.guard<void>(
      context,
      () => _service.upload(kind: kind, file: file),
      fallbackMessage: 'Could not upload this document.',
    );
    await _load();
  }

  Future<void> _reverify(String id) async {
    await AppErrorHandler.guard<void>(
      context,
      () => _service.reverify(id),
      fallbackMessage: 'Could not re-run AI verification.',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isWorkshop = AppCache.currentUser.role == 'workshop';
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const SAppBar(title: 'Verification Documents'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppBtn(
              label: isWorkshop
                  ? 'Upload Commercial Register'
                  : 'Upload Driving License',
              onTap: () => _upload(
                isWorkshop ? 'commercial_registration' : 'driver_license',
              ),
            ),
            if (isWorkshop) ...[
              const SizedBox(height: 10),
              AppBtn(
                label: 'Upload Tax Card',
                outline: true,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tax Card is supporting only. Commercial Register is required for account approval.',
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AC.red),
                    )
                  : ListView.separated(
                      itemCount: _docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final d = _docs[i];
                        return ACard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.originalName,
                                style: const TextStyle(
                                  color: AC.t1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${d.kind} • ${d.status.replaceAll('_', ' ')}',
                                style: const TextStyle(color: AC.t3),
                              ),
                              const SizedBox(height: 8),
                              GoldBadge(
                                d.aiVerificationStatus
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                icon: Icons.document_scanner_outlined,
                              ),
                              if (d.aiConfidence != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'AI confidence: ${(d.aiConfidence! * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: AC.t2,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              if (d.aiIssues.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  d.aiIssues.join('\n'),
                                  style: const TextStyle(
                                    color: AC.warning,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              AppBtn(
                                label: 'Re-run AI Verification',
                                outline: true,
                                onTap: () => _reverify(d.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

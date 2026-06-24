import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../documents/services/document_service.dart';
import '_admin_shared.dart';

class AdminDocumentsScreen extends StatefulWidget {
  const AdminDocumentsScreen({super.key});
  @override
  State<AdminDocumentsScreen> createState() => _AdminDocumentsScreenState();
}

class _AdminDocumentsScreenState extends State<AdminDocumentsScreen> {
  final _service = DocumentService();
  List<Map<String, dynamic>> _docs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await AppErrorHandler.guard(context, _service.adminDocuments);
    if (!mounted) return;
    setState(() => _docs = docs ?? const []);
  }

  Future<void> _review(
    String id,
    String status, {
    String reviewNotes = '',
  }) async {
    await AppErrorHandler.guard<void>(
      context,
      () => _service.review(id, status, reviewNotes: reviewNotes),
      fallbackMessage: 'Could not review document.',
    );
    await _load();
  }

  Future<void> _reject(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AC.s1,
        title: const Text('Reject document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;
    await _review(id, 'rejected', reviewNotes: reason);
  }

  Future<void> _openDocument(String id) async {
    final uri = await _service.documentViewUri(id);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppErrorHandler.showMessage(context, 'Could not open this document.');
    }
  }

  Future<void> _reverify(String id) async {
    await AppErrorHandler.guard<void>(
      context,
      () => _service.reverify(id, admin: true),
      fallbackMessage: 'Could not re-run AI verification.',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) => AdminShell(
    title: 'Documents',
    child: ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final doc = _docs[i];
        return AdminSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc['originalName']?.toString() ?? '',
                style: const TextStyle(
                  color: AC.t1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${doc['kind']} - ${doc['status']}',
                style: const TextStyle(color: AC.t3),
              ),
              const SizedBox(height: 6),
              Text(
                'AI: ${doc['aiVerificationStatus'] ?? 'pending'}'
                '${doc['aiConfidence'] == null ? '' : ' - ${(((doc['aiConfidence'] as num?)?.toDouble() ?? 0) * 100).toStringAsFixed(0)}% confidence'}',
                style: const TextStyle(color: AC.t3),
              ),
              if ((doc['aiExtractedFields'] as Map?)?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  'Extracted: ${(doc['aiExtractedFields'] as Map).entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                  style: const TextStyle(color: AC.t3),
                ),
              ],
              if ((doc['aiIssues'] as List?)?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(
                  'Issues: ${(doc['aiIssues'] as List).join(', ')}',
                  style: const TextStyle(color: AC.warning),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${doc['owner']?['name'] ?? 'Unknown user'} - ${doc['owner']?['role'] ?? ''}',
                style: const TextStyle(color: AC.t3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _action(
                    'Open File',
                    () => _openDocument(
                      doc['_id']?.toString() ?? doc['id'].toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _action(
                    'Re-run AI',
                    () => _reverify(
                      doc['_id']?.toString() ?? doc['id'].toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _action(
                    'Approve',
                    () => _review(
                      doc['_id']?.toString() ?? doc['id'].toString(),
                      'approved',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _action(
                    'Reject',
                    () =>
                        _reject(doc['_id']?.toString() ?? doc['id'].toString()),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _action(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AC.s2, borderRadius: Rd.fullA),
      child: Text(label, style: const TextStyle(color: AC.t2)),
    ),
  );
}

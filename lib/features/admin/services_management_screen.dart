import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class ServicesManagementScreen extends StatefulWidget {
  const ServicesManagementScreen({super.key});

  @override
  State<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
  final _service = AdminService();

  Future<void> _refresh() async {
    await _service.syncDashboard();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final services = AppCache.managedServices;

    return AdminShell(
      title: 'Services',
      actions: [
        GestureDetector(
          onTap: () => _openEditor(context),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: AC.red, borderRadius: Rd.mdA),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemBuilder: (_, index) {
          final service = services[index];
          return AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(service.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AC.t1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${service.category} • ${service.durationMins} min',
                            style: const TextStyle(fontSize: 12, color: AC.t3),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(service.isEnabled ? 'Active' : 'Pending'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  service.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AC.t3,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'EGP ${service.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AC.gold,
                      ),
                    ),
                    const Spacer(),
                    _miniAction(
                      label: service.isEnabled ? 'Disable' : 'Enable',
                      onTap: () => AppErrorHandler.guard<void>(
                        context,
                        () async {
                          await _service.updateService(
                            service.copyWith(isEnabled: !service.isEnabled),
                          );
                          await _refresh();
                        },
                        fallbackMessage:
                            'Could not update this service right now.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniAction(
                      label: 'Edit',
                      onTap: () => _openEditor(context, service: service),
                    ),
                    const SizedBox(width: 8),
                    _miniAction(
                      label: 'Delete',
                      onTap: () => AppErrorHandler.guard<void>(
                        context,
                        () async {
                          await _service.deleteService(service.id);
                          await _refresh();
                        },
                        fallbackMessage:
                            'Could not delete this service right now.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: services.length,
      ),
    );
  }

  Widget _miniAction({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AC.s2,
          borderRadius: Rd.fullA,
          border: Border.all(color: AC.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AC.t2,
          ),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, {ManagedService? service}) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final categoryCtrl = TextEditingController(text: service?.category ?? '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    final priceCtrl = TextEditingController(
      text: service?.price.toStringAsFixed(0) ?? '',
    );
    final durationCtrl = TextEditingController(
      text: service?.durationMins.toString() ?? '60',
    );
    final emojiCtrl = TextEditingController(text: service?.emoji ?? '🔧');

    showAdminInfoDialog(
      context: context,
      title: service == null ? 'Add Service' : 'Edit Service',
      child: StatefulBuilder(
        builder: (context, setModalState) => Column(
          children: [
            AppField(label: 'Name', hint: 'Service name', ctrl: nameCtrl),
            const SizedBox(height: 12),
            AppField(label: 'Category', hint: 'Category', ctrl: categoryCtrl),
            const SizedBox(height: 12),
            AppField(
              label: 'Description',
              hint: 'Short description',
              ctrl: descCtrl,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppField(
                    label: 'Price',
                    hint: '89',
                    ctrl: priceCtrl,
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppField(
                    label: 'Duration',
                    hint: '45',
                    ctrl: durationCtrl,
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppField(label: 'Emoji', hint: '🔧', ctrl: emojiCtrl),
            const SizedBox(height: 18),
            AppBtn(
              label: service == null ? 'Create Service' : 'Save Changes',
              onTap: () {
                final next = ManagedService(
                  id:
                      service?.id ??
                      'svc_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  emoji: emojiCtrl.text.trim().isEmpty
                      ? '🔧'
                      : emojiCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                  durationMins: int.tryParse(durationCtrl.text.trim()) ?? 60,
                  isPopular: service?.isPopular ?? false,
                  isEnabled: service?.isEnabled ?? true,
                );
                AppErrorHandler.guard<void>(
                  context,
                  () async {
                    if (service == null) {
                      await _service.createService(next);
                    } else {
                      await _service.updateService(next);
                    }
                    await _refresh();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  fallbackMessage: 'Could not save this service right now.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

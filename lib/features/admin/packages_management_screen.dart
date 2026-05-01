import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class PackagesManagementScreen extends StatefulWidget {
  const PackagesManagementScreen({super.key});

  @override
  State<PackagesManagementScreen> createState() => _PackagesManagementScreenState();
}

class _PackagesManagementScreenState extends State<PackagesManagementScreen> {
  final _service = AdminService();

  Future<void> _refresh() async {
    await _service.syncDashboard();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final packages = MockData.managedPackages;

    return AdminShell(
      title: 'Packages',
      actions: [
        GestureDetector(
          onTap: () => _openEditor(context),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AC.gold,
              borderRadius: Rd.mdA,
            ),
            child: const Icon(Icons.add_rounded, color: AC.bg, size: 20),
          ),
        ),
      ],
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemBuilder: (_, index) {
          final pkg = packages[index];
          return AdminSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GoldBadge(pkg.name),
                    const Spacer(),
                    StatusChip(pkg.isEnabled ? 'Active' : 'Pending'),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  pkg.tagline,
                  style: const TextStyle(fontSize: 13, color: AC.t2),
                ),
                const SizedBox(height: 10),
                Text(
                  '\$${pkg.price.toStringAsFixed(0)} • ${pkg.duration}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AC.gold,
                  ),
                ),
                const SizedBox(height: 12),
                ...pkg.features.take(3).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $feature',
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniAction(
                      label: pkg.isEnabled ? 'Disable' : 'Enable',
                      onTap: () => AppErrorHandler.guard<void>(
                        context,
                        () async {
                          await _service.updatePackage(
                            pkg.copyWith(isEnabled: !pkg.isEnabled),
                          );
                          await _refresh();
                        },
                        fallbackMessage: 'Could not update this package right now.',
                      ),
                    ),
                    const SizedBox(width: 8),
                    _miniAction(
                      label: 'Edit',
                      onTap: () => _openEditor(context, pkg: pkg),
                    ),
                    const SizedBox(width: 8),
                    _miniAction(
                      label: 'Delete',
                      onTap: () => AppErrorHandler.guard<void>(
                        context,
                        () async {
                          await _service.deletePackage(pkg.id);
                          await _refresh();
                        },
                        fallbackMessage: 'Could not delete this package right now.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: packages.length,
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

  void _openEditor(BuildContext context, {ManagedPackage? pkg}) {
    final nameCtrl = TextEditingController(text: pkg?.name ?? '');
    final taglineCtrl = TextEditingController(text: pkg?.tagline ?? '');
    final durationCtrl = TextEditingController(text: pkg?.duration ?? '');
    final priceCtrl =
        TextEditingController(text: pkg?.price.toStringAsFixed(0) ?? '');
    final originalPriceCtrl =
        TextEditingController(text: pkg?.originalPrice.toStringAsFixed(0) ?? '');
    final featuresCtrl =
        TextEditingController(text: pkg?.features.join('\n') ?? '');

    showAdminInfoDialog(
      context: context,
      title: pkg == null ? 'Add Package' : 'Edit Package',
      child: Column(
        children: [
          AppField(label: 'Name', hint: 'Package name', ctrl: nameCtrl),
          const SizedBox(height: 12),
          AppField(label: 'Tagline', hint: 'Short summary', ctrl: taglineCtrl),
          const SizedBox(height: 12),
          AppField(label: 'Duration', hint: 'month / year', ctrl: durationCtrl),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppField(
                  label: 'Price',
                  hint: '79',
                  ctrl: priceCtrl,
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppField(
                  label: 'Original Price',
                  hint: '129',
                  ctrl: originalPriceCtrl,
                  keyboard: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppField(
            label: 'Features',
            hint: 'One feature per line',
            ctrl: featuresCtrl,
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          AppBtn(
            label: pkg == null ? 'Create Package' : 'Save Changes',
            gold: true,
            onTap: () {
              final next = ManagedPackage(
                id: pkg?.id ?? 'pkg_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim(),
                tagline: taglineCtrl.text.trim(),
                duration: durationCtrl.text.trim(),
                price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                originalPrice:
                    double.tryParse(originalPriceCtrl.text.trim()) ?? 0,
                features: featuresCtrl.text
                    .split('\n')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList(),
                isPopular: pkg?.isPopular ?? false,
                isEnabled: pkg?.isEnabled ?? true,
              );
              AppErrorHandler.guard<void>(
                context,
                () async {
                  if (pkg == null) {
                    await _service.createPackage(next);
                  } else {
                    await _service.updatePackage(next);
                  }
                  await _refresh();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                fallbackMessage: 'Could not save this package right now.',
              );
            },
          ),
        ],
      ),
    );
  }
}

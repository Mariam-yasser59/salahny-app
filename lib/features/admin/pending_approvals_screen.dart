import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/admin_service.dart';
import '_admin_shared.dart';

class PendingApprovalsScreen extends StatelessWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminShell(
    title: 'Pending Approvals',
    child: PendingApprovalsView(),
  );
}

class PendingApprovalsView extends StatefulWidget {
  const PendingApprovalsView({super.key});

  @override
  State<PendingApprovalsView> createState() => _PendingApprovalsViewState();
}

class _PendingApprovalsViewState extends State<PendingApprovalsView> {
  String _tab = 'Drivers';
  final _service = AdminService();

  Future<void> _refresh() async {
    await _service.refreshDrivers();
    await _service.refreshWorkshops();
    await _service.refreshLogs();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _updateDriver(String id, AdminAccountStatus status) async {
    final ok = await AppErrorHandler.guard<bool>(
      context,
      () async {
        await _service.updateUserStatus(id, status);
        await _refresh();
        return true;
      },
      fallbackMessage: 'Could not update this driver right now.',
    );
    if (!mounted || ok != true) return;
    setState(() {});
  }

  Future<void> _updateWorkshop(String id, AdminAccountStatus status) async {
    final ok = await AppErrorHandler.guard<bool>(
      context,
      () async {
        await _service.updateWorkshop(id: id, status: status);
        await _refresh();
        return true;
      },
      fallbackMessage: 'Could not update this workshop right now.',
    );
    if (!mounted || ok != true) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingDrivers = MockData.pendingDrivers;
    final pendingWorkshops = MockData.pendingWorkshops;

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AdminFilterPill(
                    label: 'Drivers (${pendingDrivers.length})',
                    selected: _tab == 'Drivers',
                    onTap: () => setState(() => _tab = 'Drivers'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AdminFilterPill(
                    label: 'Workshops (${pendingWorkshops.length})',
                    selected: _tab == 'Workshops',
                    onTap: () => setState(() => _tab = 'Workshops'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_tab == 'Drivers') ...[
              ...pendingDrivers.map((driver) => _DriverApprovalCard(
                    driver: driver,
                    onApprove: () => _updateDriver(driver.id, AdminAccountStatus.active),
                    onReject: () => _updateDriver(driver.id, AdminAccountStatus.rejected),
                  )),
            ] else ...[
              ...pendingWorkshops.map((workshop) => _WorkshopApprovalCard(
                    workshop: workshop,
                    onApprove: () => _updateWorkshop(workshop.id, AdminAccountStatus.active),
                    onReject: () => _updateWorkshop(workshop.id, AdminAccountStatus.rejected),
                  )),
            ],
            if ((_tab == 'Drivers' && pendingDrivers.isEmpty) ||
                (_tab == 'Workshops' && pendingWorkshops.isEmpty))
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: EmptyState(
                  icon: '✅',
                  title: 'No pending approvals',
                  sub: 'Everything in this queue has already been reviewed.',
                ),
              ),
          ],
        ),
      );
  }
}

class _DriverApprovalCard extends StatelessWidget {
  final DriverUser driver;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DriverApprovalCard({
    required this.driver,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              driver.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AC.t1,
              ),
            ),
            const SizedBox(height: 6),
            Text(driver.email, style: const TextStyle(fontSize: 12, color: AC.t3)),
            const SizedBox(height: 2),
            Text(driver.phone, style: const TextStyle(fontSize: 12, color: AC.t3)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppBtn(
                    label: 'Approve',
                    small: true,
                    onTap: onApprove,
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppBtn(
                    label: 'Reject',
                    small: true,
                    outline: true,
                    onTap: onReject,
                    icon: const Icon(Icons.close_rounded, color: AC.red, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkshopApprovalCard extends StatelessWidget {
  final WorkshopUser workshop;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _WorkshopApprovalCard({
    required this.workshop,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AdminSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workshop.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AC.t1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              workshop.specialty,
              style: const TextStyle(fontSize: 12, color: AC.t3),
            ),
            const SizedBox(height: 2),
            Text(
              workshop.address,
              style: const TextStyle(fontSize: 12, color: AC.t3),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: AppBtn(
                    label: 'Approve',
                    small: true,
                    onTap: onApprove,
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppBtn(
                    label: 'Reject',
                    small: true,
                    outline: true,
                    onTap: onReject,
                    icon: const Icon(Icons.close_rounded, color: AC.red, size: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

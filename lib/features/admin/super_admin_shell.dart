import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/mock_data.dart';
import 'services/admin_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_settings_screen.dart';
import 'bookings_management_screen.dart';
import 'drivers_management_screen.dart';
import 'pending_approvals_screen.dart';

class SuperAdminShell extends StatefulWidget {
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  int _index = 0;
  final _service = AdminService();

  static const _titles = [
    'Super Admin',
    'Approvals',
    'Drivers',
    'Bookings',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _sync();
  }

  Future<void> _sync() async {
    await AppErrorHandler.guard<void>(
      context,
      () => _service.syncDashboard(),
      fallbackMessage: 'Could not load admin data right now.',
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      SuperAdminDashboardView(),
      PendingApprovalsView(),
      DriversManagementView(),
      BookingsManagementView(),
      AdminSettingsView(),
    ];

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: AppBar(
        backgroundColor: AC.bg,
        elevation: 0,
        title: Text(
          _titles[_index],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AC.t1,
          ),
        ),
        actions: _index == 0
            ? [
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, R.saWorkshops),
                  icon: const Icon(Icons.garage_rounded, color: AC.t2),
                  tooltip: 'Workshops',
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, R.saServices),
                  icon: const Icon(Icons.build_circle_rounded, color: AC.t2),
                  tooltip: 'Services',
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, R.saPackages),
                  icon: const Icon(Icons.inventory_2_rounded, color: AC.t2),
                  tooltip: 'Packages',
                ),
                IconButton(
                  onPressed: () => Navigator.pushNamed(context, R.saLogs),
                  icon: const Icon(Icons.timeline_rounded, color: AC.t2),
                  tooltip: 'Logs',
                ),
              ]
            : _index == 4
                ? [
                    IconButton(
                      onPressed: () async {
                        await MockData.logout();
                        if (!mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          R.roleSelect,
                          (_) => false,
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, color: AC.t2),
                      tooltip: 'Logout',
                    ),
                  ]
                : null,
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AC.s1,
          indicatorColor: AC.red.withOpacity(0.16),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: states.contains(WidgetState.selected) ? AC.red : AC.t3,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AC.red : AC.t3,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.verified_user_rounded),
              label: 'Approvals',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Drivers',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/admin_models.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';
import '_admin_shared.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AdminShell(
    title: 'Admin Settings',
    child: AdminSettingsView(),
  );
}

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  late final TextEditingController _privacyCtrl;
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _announcementTitleCtrl;
  late final TextEditingController _announcementBodyCtrl;
  final _passwordCtrl = TextEditingController();
  bool _notificationsEnabled = MockData.adminSettings.notificationsEnabled;

  @override
  void initState() {
    super.initState();
    final settings = MockData.adminSettings;
    _privacyCtrl = TextEditingController(text: settings.privacyPolicy);
    _aboutCtrl = TextEditingController(text: settings.aboutContent);
    _announcementTitleCtrl =
        TextEditingController(text: settings.announcementTitle);
    _announcementBodyCtrl = TextEditingController(text: settings.announcementBody);
  }

  @override
  void dispose() {
    _privacyCtrl.dispose();
    _aboutCtrl.dispose();
    _announcementTitleCtrl.dispose();
    _announcementBodyCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ACard(
              glow: true,
              glowColor: AC.gold,
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AC.goldGrad,
                      borderRadius: Rd.lgA,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AC.bg,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MockData.superAdmin.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AC.t1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MockData.superAdmin.email,
                          style: const TextStyle(fontSize: 12, color: AC.t3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SecHeader(title: 'Platform Content'),
            const SizedBox(height: 12),
            AdminSectionCard(
              child: Column(
                children: [
                  AppField(
                    label: 'Announcement Title',
                    hint: 'Title',
                    ctrl: _announcementTitleCtrl,
                  ),
                  const SizedBox(height: 12),
                  AppField(
                    label: 'Announcement Body',
                    hint: 'Announcement details',
                    ctrl: _announcementBodyCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  AppField(
                    label: 'Privacy Policy',
                    hint: 'Privacy policy',
                    ctrl: _privacyCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  AppField(
                    label: 'About Content',
                    hint: 'About the platform',
                    ctrl: _aboutCtrl,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _notificationsEnabled,
                    activeColor: AC.red,
                    title: const Text(
                      'Admin notifications enabled',
                      style: TextStyle(color: AC.t1, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Allow in-app announcements and admin notices.',
                      style: TextStyle(color: AC.t3, fontSize: 12),
                    ),
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                  const SizedBox(height: 10),
                  AppBtn(
                    label: 'Save Settings',
                    onTap: () {
                      MockData.updateAdminSettings(
                        AdminSettingsData(
                          privacyPolicy: _privacyCtrl.text.trim(),
                          aboutContent: _aboutCtrl.text.trim(),
                          announcementTitle: _announcementTitleCtrl.text.trim(),
                          announcementBody: _announcementBodyCtrl.text.trim(),
                          notificationsEnabled: _notificationsEnabled,
                        ),
                      );
                      AppErrorHandler.showMessage(
                        context,
                        'Admin settings updated',
                        isError: false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SecHeader(title: 'Security'),
            const SizedBox(height: 12),
            AdminSectionCard(
              child: Column(
                children: [
                  AppField(
                    label: 'Change Admin Password',
                    hint: 'New password',
                    ctrl: _passwordCtrl,
                    obscure: true,
                  ),
                  const SizedBox(height: 14),
                  AppBtn(
                    label: 'Update Password',
                    gold: true,
                    onTap: () async {
                      if (_passwordCtrl.text.trim().length < 6) {
                        AppErrorHandler.showMessage(
                          context,
                          'Use at least 6 characters for the admin password',
                        );
                        return;
                      }
                      await MockData.changeAdminPassword(_passwordCtrl.text.trim());
                      _passwordCtrl.clear();
                      if (!mounted) return;
                      AppErrorHandler.showMessage(
                        context,
                        'Admin password updated',
                        isError: false,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AppBtn(
                    label: 'Logout',
                    outline: true,
                    onTap: () async {
                      await MockData.logout();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        R.roleSelect,
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

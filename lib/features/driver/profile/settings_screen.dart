import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/services/auth_service.dart';
import 'report_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notif = true;
  bool _location = true;
  bool _biometric = false;
  bool _dark = true;
  bool _emailAlerts = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: SAppBar(title: 'Settings'),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _Group('Notifications', [
          _Toggle(
            'Push Notifications',
            _notif,
                (v) => setState(() => _notif = v),
          ),
          _Toggle(
            'Email Alerts',
            _emailAlerts,
                (v) => setState(() => _emailAlerts = v),
          ),
        ]),

        const SizedBox(height: 12),

        _Group('Privacy & Security', [
          _Toggle(
            'Location Access',
            _location,
                (v) => setState(() => _location = v),
          ),
          _Toggle(
            'Biometric Login',
            _biometric,
                (v) => setState(() => _biometric = v),
          ),
        ]),

        const SizedBox(height: 12),

        _Group('Appearance', [
          _Toggle(
            'Dark Mode',
            _dark,
                (v) => setState(() => _dark = v),
          ),
        ]),

        const SizedBox(height: 12),

        _Group('Account', [
          ListTile(
            leading: const Icon(
              Icons.report_problem_outlined,
              color: AC.warning,
            ),
            title: const Text(
              'Report a Problem',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AC.t1,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AC.t3,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportScreen(),
                ),
              );
            },
          ),

          const Divider(
            height: 1,
            color: AC.border,
          ),

          ListTile(
            leading: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to permanently delete your account?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await AuthService().deleteAccount();

                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      R.roleSelect,
                          (_) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete account: $e'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ]),
      ],
    ),
  );
}

Widget _Group(String title, List<Widget> items) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AC.t3,
          letterSpacing: 0.5,
        ),
      ),
    ),
    ACard(
      padding: EdgeInsets.zero,
      child: Column(children: items),
    ),
  ],
);

Widget _Toggle(
    String title,
    bool val,
    ValueChanged<bool> onChange,
    ) =>
    ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AC.t1,
        ),
      ),
      trailing: Switch(
        value: val,
        onChanged: onChange,
        activeColor: AC.red,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Privacy Policy'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AC.t1,
            ),
          ),

          SizedBox(height: 16),

          _PrivacyCard(
            icon: Icons.lock_outline_rounded,
            title: 'Your Data is Protected',
            body:
            'Salahny keeps your personal information, booking details, workshop interactions, and payment metadata secure and visible only to authorized roles.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.person_outline_rounded,
            title: 'Information We Collect',
            body:
            'We may collect your name, email, phone number, vehicle details, booking history, location for nearby services, and app usage data to improve your experience.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.directions_car_filled_outlined,
            title: 'Vehicle Information',
            body:
            'Vehicle details such as make, model, plate number, mileage, and diagnostic information are used only to provide accurate maintenance, booking, and AI diagnosis services.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.location_on_outlined,
            title: 'Location Access',
            body:
            'Location is used to show nearby workshops, emergency assistance, and service providers. You can disable location access from your device settings at any time.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.payment_rounded,
            title: 'Payments and Transactions',
            body:
            'Payment-related information is handled securely. Salahny does not expose payment metadata to unauthorized users or third parties.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            body:
            'We may send notifications about bookings, service updates, reminders, offers, and important account activity. You can control notifications from Settings.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Access Control',
            body:
            'Drivers, workshops, and admins have different access levels. Each role can only view the information needed to perform its tasks inside the system.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.delete_outline_rounded,
            title: 'Account Deletion',
            body:
            'You can request to delete your account from Settings. Once deleted, your account data may be permanently removed from the system according to the app policy.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.security_rounded,
            title: 'Security Measures',
            body:
            'We use authentication, protected API routes, secure tokens, and role-based permissions to help protect your account and data.',
          ),

          SizedBox(height: 14),

          _PrivacyCard(
            icon: Icons.update_rounded,
            title: 'Policy Updates',
            body:
            'This Privacy Policy may be updated when new features are added. Continued use of Salahny means you agree to the updated policy.',
          ),

          SizedBox(height: 22),

          Text(
            'Last updated: 2026',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AC.t3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PrivacyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return ACard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AC.red.withOpacity(0.12),
              borderRadius: Rd.mdA,
            ),
            child: Icon(
              icon,
              color: AC.red,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AC.t3,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
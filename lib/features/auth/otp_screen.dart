import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/widgets/app_widgets.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppData.i.currentUser.role;
    final isWorkshop = role == 'workshop';
    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isWorkshop ? 'Workshop Submitted' : 'License Submitted',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AC.t1,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isWorkshop
                    ? 'Your workshop account and permit are waiting for admin approval.'
                    : 'Your driver account and license are waiting for admin approval.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AC.t3, height: 1.5),
              ),
              const SizedBox(height: 28),
              const ACard(
                child: Row(
                  children: [
                    Icon(Icons.fact_check_outlined, color: AC.gold),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can sign in after the verification document is approved.',
                        style: TextStyle(color: AC.t2, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppBtn(
                label: 'Back to Sign In',
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  R.login,
                  (_) => false,
                ),
                icon: const Icon(Icons.login_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

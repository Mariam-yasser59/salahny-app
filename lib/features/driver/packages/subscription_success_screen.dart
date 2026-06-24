import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'demo_subscription_payment_screen.dart';

class SubscriptionSuccessScreen extends StatelessWidget {
  const SubscriptionSuccessScreen({super.key});

  SubscriptionSuccessArgs? _args(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments as SubscriptionSuccessArgs?;

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    return Scaffold(
      backgroundColor: AC.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  gradient: AC.goldGrad,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AC.gold.withValues(alpha: 0.45),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AC.bg,
                  size: 58,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 28),
              const Text(
                'Subscription Activated Successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AC.t1,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ).animate().fadeIn(delay: 180.ms),
              const SizedBox(height: 10),
              const Text(
                'Your demo online card payment was completed. No real money was charged.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AC.t3, fontSize: 14, height: 1.45),
              ).animate().fadeIn(delay: 260.ms),
              const SizedBox(height: 26),
              ACard(
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Plan',
                      value: args?.planName ?? 'Subscription plan',
                      bold: true,
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Amount Paid',
                      value: 'EGP ${(args?.amount ?? 0).toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Transaction ID',
                      value: args?.transactionId.isNotEmpty == true
                          ? args!.transactionId
                          : 'Demo transaction',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 340.ms),
              const SizedBox(height: 30),
              AppBtn(
                label: 'Go to Dashboard',
                gold: true,
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  R.home,
                  (_) => false,
                ),
              ).animate().fadeIn(delay: 420.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  R.packages,
                  (route) => route.settings.name == R.home,
                ),
                child: const Text('Back to Subscription Plans'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

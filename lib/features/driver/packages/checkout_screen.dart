import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'demo_subscription_payment_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  PackageModel? _selectedPackage(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    final packages = AppData.i.packages;
    if (packages.isEmpty) return null;
    return packages.firstWhere((p) => p.id == id, orElse: () => packages.first);
  }

  @override
  Widget build(BuildContext context) {
    final pkg = _selectedPackage(context);
    if (pkg == null) {
      return const Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(title: 'Subscription Payment'),
        body: Center(
          child: EmptyState(
            icon: '?',
            title: 'No Packages Available',
            sub: 'Packages will appear after admin setup.',
          ),
        ),
      );
    }
    final discount = (pkg.originalPrice - pkg.price).clamp(0, double.infinity);

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const SAppBar(title: 'Subscription Payment'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ACard(
              glow: true,
              glowColor: AC.gold,
              child: Column(
                children: [
                  Row(
                    children: [
                      GoldBadge('${pkg.name} Plan'),
                      const Spacer(),
                      Text(
                        'EGP ${pkg.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AC.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${pkg.duration} - ${pkg.tagline}',
                    style: const TextStyle(fontSize: 13, color: AC.t3),
                  ),
                  const SizedBox(height: 12),
                  const Div(),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Subtotal',
                    value: 'EGP ${pkg.originalPrice.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  InfoRow(
                    label: 'Discount',
                    value: '-EGP ${discount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  const Div(),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Total',
                    value: 'EGP ${pkg.price.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: 24),
            const SecHeader(title: 'Online Card Payment'),
            const SizedBox(height: 12),
            ACard(
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AC.red.withValues(alpha: 0.12),
                      borderRadius: Rd.mdA,
                    ),
                    child: const Icon(Icons.credit_card_rounded, color: AC.red),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Online Card',
                          style: TextStyle(
                            color: AC.t1,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'No real money will be charged.',
                          style: TextStyle(color: AC.t3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AC.success),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 24),
            AppBtn(
              label: 'Pay Online',
              gold: true,
              onTap: () => Navigator.pushReplacementNamed(
                context,
                R.demoSubscriptionPayment,
                arguments: DemoSubscriptionPaymentArgs(
                  selectedPlanId: pkg.id,
                  selectedPlanName: pkg.name,
                  amount: pkg.price,
                  duration: pkg.duration,
                ),
              ),
            ).animate().fadeIn(delay: 180.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

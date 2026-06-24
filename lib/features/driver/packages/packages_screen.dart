import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../services/services/service_api.dart';
import '../profile/services/user_profile_service.dart';
import 'demo_subscription_payment_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _api = ServiceApi();
  final _profileService = UserProfileService();
  List<PackageModel> _items = AppData.i.packages;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getPackages();
      await _profileService.getProfile().catchError(
        (_) => AppCache.currentUser,
      );
      if (!mounted) return;
      setState(() => _items = data);
    } catch (_) {
      if (mounted) setState(() => _items = AppData.i.packages);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = AppCache.currentUser.activeSubscription;
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(
        title: 'Subscription Plans',
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded, color: AC.t1),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AC.red,
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              if (_loading)
                const LinearProgressIndicator(minHeight: 2, color: AC.red),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AC.redGrad,
                  borderRadius: Rd.lgA,
                  boxShadow: [
                    BoxShadow(
                      color: AC.red.withValues(alpha: 0.4),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    GoldBadge(
                      'Exclusive Deals',
                      icon: Icons.local_offer_rounded,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Choose Your Plan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Save more, worry less with Salahny subscriptions',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              if (active != null) ...[
                const SizedBox(height: 16),
                ACard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AC.success,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Active Subscription',
                              style: TextStyle(
                                color: AC.t3,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${active.packageName} - ${active.remainingDays} days left',
                              style: const TextStyle(
                                color: AC.t1,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ..._items.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child:
                      _PlanCard(
                            pkg: e.value,
                            isActive:
                                active?.packageName.toLowerCase() ==
                                e.value.name.toLowerCase(),
                            onPaymentReturned: _load,
                          )
                          .animate()
                          .fadeIn(delay: ((e.key + 1) * 100).ms)
                          .slideY(begin: 0.2, end: 0),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PackageModel pkg;
  final bool isActive;
  final Future<void> Function() onPaymentReturned;

  const _PlanCard({
    required this.pkg,
    required this.isActive,
    required this.onPaymentReturned,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: pkg.isPopular
          ? LinearGradient(colors: [AC.redDark.withValues(alpha: 0.35), AC.bg])
          : null,
      color: pkg.isPopular ? null : AC.s2,
      borderRadius: Rd.lgA,
      border: Border.all(
        color: pkg.isPopular ? AC.red : AC.border,
        width: pkg.isPopular ? 1.5 : 0.8,
      ),
      boxShadow: pkg.isPopular
          ? [BoxShadow(color: AC.red.withValues(alpha: 0.2), blurRadius: 22)]
          : null,
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AC.t1,
                      ),
                    ),
                    Text(
                      pkg.tagline,
                      style: const TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  ],
                ),
              ),
              if (pkg.isPopular) const GoldBadge('Most Popular'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EGP ${pkg.price.toInt()}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AC.t1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  ' / ${pkg.duration}',
                  style: const TextStyle(fontSize: 13, color: AC.t3),
                ),
              ),
              const Spacer(),
              if (pkg.originalPrice > pkg.price)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AC.success.withValues(alpha: 0.12),
                    borderRadius: Rd.fullA,
                    border: Border.all(
                      color: AC.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Save EGP ${(pkg.originalPrice - pkg.price).toInt()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AC.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Div(),
          const SizedBox(height: 14),
          ...pkg.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      gradient: AC.goldGrad,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: AC.bg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(f, style: const TextStyle(fontSize: 13, color: AC.t1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppBtn(
            label: isActive ? 'Current Active Plan' : 'Pay Online',
            gold: pkg.isPopular,
            onTap: isActive
                ? null
                : () async {
                    await Navigator.pushNamed(
                      context,
                      R.demoSubscriptionPayment,
                      arguments: DemoSubscriptionPaymentArgs(
                        selectedPlanId: pkg.id,
                        selectedPlanName: pkg.name,
                        amount: pkg.price,
                        duration: pkg.duration,
                      ),
                    );
                    await onPaymentReturned();
                  },
          ),
        ],
      ),
    ),
  );
}

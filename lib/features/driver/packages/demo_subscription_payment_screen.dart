import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/utils/payment_input_utils.dart';
import '../profile/services/user_profile_service.dart';
import 'services/package_payment_service.dart';

class DemoSubscriptionPaymentArgs {
  final String selectedPlanId;
  final String selectedPlanName;
  final double amount;
  final String duration;

  const DemoSubscriptionPaymentArgs({
    required this.selectedPlanId,
    required this.selectedPlanName,
    required this.amount,
    required this.duration,
  });
}

class SubscriptionSuccessArgs {
  final String planName;
  final double amount;
  final String transactionId;

  const SubscriptionSuccessArgs({
    required this.planName,
    required this.amount,
    required this.transactionId,
  });
}

class DemoSubscriptionPaymentScreen extends StatefulWidget {
  const DemoSubscriptionPaymentScreen({super.key});

  @override
  State<DemoSubscriptionPaymentScreen> createState() =>
      _DemoSubscriptionPaymentScreenState();
}

class _DemoSubscriptionPaymentScreenState
    extends State<DemoSubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardholder = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _paymentService = PackagePaymentService();
  final _profileService = UserProfileService();
  bool _loading = false;

  @override
  void dispose() {
    _cardholder.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  DemoSubscriptionPaymentArgs? _args(BuildContext context) =>
      ModalRoute.of(context)?.settings.arguments
          as DemoSubscriptionPaymentArgs?;

  Future<void> _confirm(DemoSubscriptionPaymentArgs args) async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final ok = await AppErrorHandler.guard<Map<String, dynamic>>(
      context,
      () async {
        final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
        final result = await _paymentService
            .completeDemoOnlineSubscriptionPayment(
              planId: args.selectedPlanId,
              amount: args.amount,
              cardLast4: digits.substring(digits.length - 4),
            );
        await _profileService.getProfile();
        return result;
      },
      fallbackMessage: 'Demo online payment could not be completed.',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok == null) return;
    final transactionId =
        (ok['transactionId'] ?? ok['subscription']?['transactionId'] ?? '')
            .toString();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription activated successfully.'),
        backgroundColor: AC.success,
      ),
    );
    Navigator.pushReplacementNamed(
      context,
      R.subscriptionSuccess,
      arguments: SubscriptionSuccessArgs(
        planName: args.selectedPlanName,
        amount: args.amount,
        transactionId: transactionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args(context);
    if (args == null) {
      return const Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(title: 'Demo Payment'),
        body: Center(
          child: EmptyState(
            icon: '?',
            title: 'No Plan Selected',
            sub: 'Please choose a subscription plan first.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const SAppBar(title: 'Online Card Payment'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ACard(
                glow: true,
                glowColor: AC.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GoldBadge('Online Card Demo'),
                    const SizedBox(height: 14),
                    Text(
                      args.selectedPlanName,
                      style: const TextStyle(
                        color: AC.t1,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      args.duration,
                      style: const TextStyle(color: AC.t3, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      label: 'Amount',
                      value: 'EGP ${args.amount.toStringAsFixed(2)}',
                      bold: true,
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AC.success.withValues(alpha: 0.10),
                        borderRadius: Rd.mdA,
                        border: Border.all(
                          color: AC.success.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'Demo online card payment only. No real money will be charged.',
                        style: TextStyle(
                          color: AC.success,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 20),
              _Field(
                controller: _cardholder,
                label: 'Cardholder Name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: validateCardholderName,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _cardNumber,
                label: 'Card Number',
                icon: Icons.credit_card_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: const [CardNumberInputFormatter()],
                textInputAction: TextInputAction.next,
                validator: validateCardNumber,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _expiry,
                      label: 'Expiry Date MM/YY',
                      icon: Icons.calendar_month_rounded,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [ExpiryDateInputFormatter()],
                      textInputAction: TextInputAction.next,
                      validator: validateExpiryDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      controller: _cvv,
                      label: 'CVV',
                      icon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      textInputAction: TextInputAction.done,
                      validator: validateCvv,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              AppBtn(
                label: 'Confirm Online Payment',
                gold: true,
                loading: _loading,
                onTap: () => _confirm(args),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final List<TextInputFormatter> inputFormatters;
  final TextInputAction? textInputAction;
  final String? Function(String value) validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.inputFormatters = const [],
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    inputFormatters: inputFormatters,
    textInputAction: textInputAction,
    style: const TextStyle(color: AC.t1, fontWeight: FontWeight.w700),
    validator: (value) => validator(value ?? ''),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AC.t3),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _loading = false;
  late String _selectedPaymentId;
  final _formKey = GlobalKey<FormState>();
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPaymentId = AppData.i.bookingCheckout.selectedPaymentOptionId;
  }

  @override
  void dispose() {
    _cardNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  bool get _needsCardDetails => _selectedPaymentId == 'card';

  @override
  Widget build(BuildContext context) {
    final checkout = AppData.i.bookingCheckout;

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Booking Checkout', showBack: true),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AC.red.withOpacity(0.16),
                    AC.s2,
                    AC.s1,
                  ],
                ),
                borderRadius: Rd.lgA,
                border: Border.all(color: AC.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review your booking details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AC.t3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    checkout.serviceName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${checkout.workshopName} • ${checkout.durationMins} min',
                    style: const TextStyle(fontSize: 13, color: AC.t3),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 18),
            ACard(
              child: Column(
                children: [
                  InfoRow(label: 'Service', value: checkout.serviceName),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Workshop', value: checkout.workshopName),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Date & Time',
                    value: '${checkout.date} • ${checkout.time}',
                  ),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Vehicle', value: checkout.vehicleLabel),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Duration',
                    value: '${checkout.durationMins} min',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 80.ms),
            const SizedBox(height: 24),
            const SecHeader(title: 'Payment Method'),
            const SizedBox(height: 12),
            ...checkout.paymentOptions.asMap().entries.map(
              (entry) {
                final option = entry.value;
                final selected = option.id == _selectedPaymentId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPaymentId = option.id),
                    child: AnimatedContainer(
                      duration: 250.ms,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [
                                  AC.red.withOpacity(0.14),
                                  AC.red.withOpacity(0.04),
                                ],
                              )
                            : null,
                        color: selected ? null : AC.s2,
                        borderRadius: Rd.lgA,
                        border: Border.all(
                          color: selected ? AC.red : AC.border,
                          width: selected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(option.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              option.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selected ? AC.t1 : AC.t2,
                              ),
                            ),
                          ),
                          AnimatedContainer(
                            duration: 250.ms,
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? AC.red : Colors.transparent,
                              border: Border.all(
                                color: selected ? AC.red : AC.border2,
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (160 + entry.key * 80).ms),
                );
              },
            ),
            if (_needsCardDetails) ...[
              const SizedBox(height: 12),
              ACard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Card Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AC.t1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PaymentField(
                      controller: _cardNameCtrl,
                      label: 'Cardholder Name',
                      hint: 'Name on card',
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter the cardholder name';
                        if (text.length < 3) return 'Name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _PaymentField(
                      controller: _cardNumberCtrl,
                      label: 'Card Number',
                      hint: '1234 5678 9012 3456',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final digits =
                            (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.isEmpty) return 'Enter card number';
                        if (digits.length < 16) return 'Card number is invalid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentField(
                            controller: _expiryCtrl,
                            label: 'Expiry',
                            hint: 'MM/YY',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.isEmpty) return 'Required';
                              if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$')
                                  .hasMatch(text)) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentField(
                            controller: _cvvCtrl,
                            label: 'CVV',
                            hint: '123',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final digits =
                                  (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.isEmpty) return 'Required';
                              if (digits.length < 3 || digits.length > 4) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 220.ms),
            ],
            const SizedBox(height: 14),
            ACard(
              glow: true,
              glowColor: AC.gold,
              child: Column(
                children: [
                  InfoRow(
                    label: 'Subtotal',
                    value: '\$${checkout.subtotal.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    label: 'Service Fee',
                    value: '\$${checkout.serviceFee.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 10),
                  InfoRow(
                    label: 'Discount',
                    value: '-\$${checkout.discount.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  const Div(),
                  const SizedBox(height: 12),
                  InfoRow(
                    label: 'Total',
                    value: '\$${checkout.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 220.ms),
            const SizedBox(height: 24),
            AppBtn(
              label: _needsCardDetails ? 'Pay Now' : 'Confirm Booking',
              loading: _loading,
              onTap: () async {
                if (_needsCardDetails &&
                    !(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                setState(() => _loading = true);
                final ok = await AppErrorHandler.guard<bool>(
                  context,
                  () async {
                    await MockData.saveBookingPaymentMethod(_selectedPaymentId);
                    await Future.delayed(900.ms);
                    return true;
                  },
                  fallbackMessage:
                      'Could not complete the booking payment. Please try again.',
                );
                if (!mounted) return;
                setState(() => _loading = false);
                if (ok == true) {
                  Navigator.pushReplacementNamed(context, R.bookingTrack);
                }
              },
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 280.ms),
          ],
          ),
        ),
      ),
    );
  }
}

class _PaymentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PaymentField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AC.t2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: AC.t1, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AC.t4, fontSize: 13),
            filled: true,
            fillColor: AC.s1,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.red, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: Rd.mdA,
              borderSide: const BorderSide(color: AC.error, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

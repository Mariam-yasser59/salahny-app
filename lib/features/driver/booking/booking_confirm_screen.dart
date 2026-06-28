import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../bookings/services/booking_service.dart';
import '../../workshops/services/workshop_service.dart';
import '../../../shared/services/app_cache.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/utils/payment_input_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

class BookingConfirmScreen extends StatefulWidget {
  const BookingConfirmScreen({super.key});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _bookingService = BookingService();
  final _workshopService = WorkshopService();
  bool _loading = false;
  late String _selectedPaymentId;
  final _formKey = GlobalKey<FormState>();
  final _cardNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _locationService = const LocationService();
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _addressSearching = false;

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
    _addressCtrl.dispose();
    super.dispose();
  }

  bool get _needsCardDetails => _selectedPaymentId == 'card';

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final result = await _locationService.currentPosition(withAddress: true);
    if (!mounted) return;
    setState(() => _locating = false);
    if (!result.hasLocation) {
      AppErrorHandler.showMessage(
        context,
        result.message ?? 'Could not detect your location.',
      );
      if (result.permanentlyDenied) {
        await _locationService.openAppSettings();
      }
      return;
    }
    final position = result.position!;
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _addressCtrl.text =
          result.address ??
          '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _searchAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      AppErrorHandler.showMessage(context, 'Type the pickup address first.');
      return;
    }
    setState(() => _addressSearching = true);
    final point = await _locationService.geocodeAddress(address);
    if (!mounted) return;
    setState(() => _addressSearching = false);
    if (point == null) {
      AppErrorHandler.showMessage(
        context,
        'Could not find that address. Try adding city/country.',
      );
      return;
    }
    setState(() {
      _latitude = point.latitude;
      _longitude = point.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkout = AppData.i.bookingCheckout;

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const SAppBar(title: 'Booking Checkout', showBack: true),
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
                    colors: [AC.red.withValues(alpha: 0.16), AC.s2, AC.s1],
                  ),
                  borderRadius: Rd.lgA,
                  border: Border.all(color: AC.red.withValues(alpha: 0.3)),
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
              const SizedBox(height: 18),
              ACard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup / Service Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AC.t1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Use your current location or type the address where the workshop should expect you.',
                      style: TextStyle(fontSize: 12, color: AC.t3),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressCtrl,
                      style: const TextStyle(color: AC.t1, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Street, district, landmark',
                        hintStyle: const TextStyle(color: AC.t4),
                        prefixIcon: const Icon(
                          Icons.place_rounded,
                          color: AC.red,
                        ),
                        filled: true,
                        fillColor: AC.s1,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: Rd.mdA,
                          borderSide: const BorderSide(color: AC.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: Rd.mdA,
                          borderSide: const BorderSide(color: AC.red),
                        ),
                      ),
                      onSubmitted: (_) => _searchAddress(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: AppBtn(
                            label: _locating ? 'Detecting...' : 'Use Current',
                            outline: true,
                            loading: _locating,
                            onTap: _locating ? null : _useCurrentLocation,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppBtn(
                            label: _addressSearching
                                ? 'Searching...'
                                : 'Find Address',
                            loading: _addressSearching,
                            onTap: _addressSearching ? null : _searchAddress,
                          ),
                        ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Saved GPS: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                        style: const TextStyle(color: AC.t3, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 120.ms),
              const SizedBox(height: 24),
              const SecHeader(title: 'Payment Method'),
              const SizedBox(height: 12),
              ...checkout.paymentOptions.asMap().entries.map((entry) {
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
                                  AC.red.withValues(alpha: 0.14),
                                  AC.red.withValues(alpha: 0.04),
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
                          Text(
                            option.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
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
              }),
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
                          return validateCardholderName(value ?? '');
                        },
                      ),
                      const SizedBox(height: 12),
                      _PaymentField(
                        controller: _cardNumberCtrl,
                        label: 'Card Number',
                        hint: '1234 5678 9012 3456',
                        keyboardType: TextInputType.number,
                        inputFormatters: const [CardNumberInputFormatter()],
                        validator: (value) {
                          return validateCardNumber(value ?? '');
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
                              inputFormatters: const [
                                ExpiryDateInputFormatter(),
                              ],
                              validator: (value) {
                                return validateExpiryDate(value ?? '');
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
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                return validateCvv(value ?? '');
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
                      value: 'EGP ${checkout.subtotal.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Salahny service fee (10%)',
                      value: 'EGP ${checkout.serviceFee.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      label: 'Discount',
                      value: '-EGP ${checkout.discount.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 12),
                    const Div(),
                    const SizedBox(height: 12),
                    InfoRow(
                      label: 'Total',
                      value: 'EGP ${checkout.total.toStringAsFixed(2)}',
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
                  if (_addressCtrl.text.trim().isEmpty) {
                    AppErrorHandler.showMessage(
                      context,
                      'Enter the pickup or service address.',
                    );
                    return;
                  }
                  if (_latitude == null || _longitude == null) {
                    final point = await _locationService.geocodeAddress(
                      _addressCtrl.text.trim(),
                    );
                    if (!context.mounted) return;
                    if (point == null) {
                      AppErrorHandler.showMessage(
                        context,
                        'Could not find that address. Add city and country, then try again.',
                      );
                      return;
                    }
                    _latitude = point.latitude;
                    _longitude = point.longitude;
                  }
                  setState(() => _loading = true);
                  final bookingId = await AppErrorHandler.guard<String>(
                    context,
                    () async {
                      await AppCache.saveBookingPaymentMethod(
                        _selectedPaymentId,
                      );
                      final selectedPayment = checkout.paymentOptions
                          .firstWhere(
                            (item) => item.id == _selectedPaymentId,
                            orElse: () => checkout.paymentOptions.first,
                          );
                      final booking = await _bookingService.createBooking({
                        'workshop': checkout.workshopId,
                        'service': checkout.serviceName,
                        'serviceId': checkout.serviceId,
                        'paymentMethod': selectedPayment.label,
                        'subtotal': checkout.subtotal,
                        'appServiceFee': checkout.serviceFee,
                        'total': checkout.total,
                        'vehicleLabel': checkout.vehicleLabel,
                        'vehicleId': checkout.vehicleId,
                        'address': _addressCtrl.text.trim(),
                        'latitude': _latitude,
                        'longitude': _longitude,
                        'date': checkout.slotIso.isNotEmpty
                            ? checkout.slotIso
                            : _resolveBookingDateTime(
                                checkout.date,
                                checkout.time,
                              ).toIso8601String(),
                      });
                      await Future.wait([
                        _bookingService.getBookings(),
                        _workshopService.getWorkshops(),
                      ]);
                      return booking.id;
                    },
                    fallbackMessage:
                        'Could not complete the booking payment. Please try again.',
                  );
                  if (!context.mounted) return;
                  setState(() => _loading = false);
                  if (bookingId == null) return;
                  Navigator.pushReplacementNamed(
                    context,
                    R.bookingTrack,
                    arguments: bookingId,
                  );
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

  DateTime _resolveBookingDateTime(String label, String time) {
    final now = DateTime.now();
    DateTime baseDate;
    if (label == 'Today') {
      baseDate = now;
    } else if (label == 'Tomorrow') {
      baseDate = now.add(const Duration(days: 1));
    } else {
      final parts = label.split(' ');
      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final month = months[parts.first] ?? now.month;
      final day = int.tryParse(parts.last) ?? now.day;
      baseDate = DateTime(now.year, month, day);
    }

    final segments = time.split(' ');
    final clock = segments.first.split(':');
    var hour = int.tryParse(clock.first) ?? 9;
    final minute = int.tryParse(clock.last) ?? 0;
    final suffix = segments.length > 1 ? segments.last : 'AM';

    if (suffix == 'PM' && hour < 12) {
      hour += 12;
    } else if (suffix == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
  }
}

class _PaymentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final String? Function(String?)? validator;

  const _PaymentField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.inputFormatters = const [],
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
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: AC.t1, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AC.t4, fontSize: 13),
            filled: true,
            fillColor: AC.s1,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
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

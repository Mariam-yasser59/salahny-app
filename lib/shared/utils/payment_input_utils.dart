import 'package:flutter/services.dart';

class CardNumberInputFormatter extends TextInputFormatter {
  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 19 ? digits.substring(0, 19) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  const ExpiryDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = limited.length <= 2
        ? limited
        : '${limited.substring(0, 2)}/${limited.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String? validateCardholderName(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'Cardholder name is required';
  if (text.length < 3) return 'Cardholder name is too short';
  return null;
}

String? validateCardNumber(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'Card number is required';
  if (digits.length < 13 || digits.length > 19) {
    return 'Card number must be 13 to 19 digits';
  }
  return null;
}

String? validateExpiryDate(String value) {
  final text = value.trim();
  final match = RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').firstMatch(text);
  if (match == null) return 'Use valid MM/YY';

  final month = int.parse(match.group(1)!);
  final year = 2000 + int.parse(match.group(2)!);
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  final expiryMonth = DateTime(year, month);
  final maxMonth = DateTime(now.year + 10, now.month);

  if (expiryMonth.isBefore(currentMonth)) return 'Card is expired';
  if (expiryMonth.isAfter(maxMonth)) return 'Expiry is too far in future';
  return null;
}

String? validateCvv(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 'CVV is required';
  if (digits.length < 3 || digits.length > 4) {
    return 'CVV must be 3 or 4 digits';
  }
  return null;
}

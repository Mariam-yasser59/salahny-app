import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import '../network/api_client.dart';

class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class AppErrorHandler {
  AppErrorHandler._();

  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void report(Object error, [StackTrace? stackTrace]) {
    developer.log(
      error.toString(),
      name: 'Salahny',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String messageFor(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is AppException) return error.message;
    if (error is ApiException) return error.message;
    return fallback;
  }

  static void showMessage(
    BuildContext? context,
    String message, {
    bool isError = true,
  }) {
    final messenger =
        context != null ? ScaffoldMessenger.maybeOf(context) : messengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB3261E) : const Color(0xFF1F7A1F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<T?> guard<T>(
    BuildContext context,
    Future<T> Function() action, {
    String fallbackMessage = 'Something went wrong. Please try again.',
    String? successMessage,
  }) async {
    try {
      final result = await action();
      if (successMessage != null && context.mounted) {
        showMessage(context, successMessage, isError: false);
      }
      return result;
    } catch (error, stackTrace) {
      report(error, stackTrace);
      if (context.mounted) {
        showMessage(
          context,
          messageFor(error, fallback: fallbackMessage),
        );
      } else {
        showMessage(null, messageFor(error, fallback: fallbackMessage));
      }
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_widgets.dart';
import 'services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _sent = false;
  bool _loading = false;
  bool _reset = false;

  @override
  void initState() {
    super.initState();
    final token = Uri.base.queryParameters['token'];
    if (token != null && token.trim().isNotEmpty) {
      _token.text = token.trim();
      _sent = true;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_email.text.trim().isEmpty) {
      AppErrorHandler.showMessage(context, 'Enter your email address.');
      return;
    }
    setState(() => _loading = true);
    final response = await AppErrorHandler.guard<Map<String, dynamic>>(
      context,
      () => _auth.requestPasswordReset(email: _email.text.trim()),
      fallbackMessage: 'Could not request a password reset.',
    );
    if (!mounted) return;
    final data = response?['data'] as Map<String, dynamic>?;
    if (data?['resetToken'] != null) {
      _token.text = data!['resetToken'].toString();
    }
    setState(() {
      _loading = false;
      _sent = response != null;
    });
    if (response != null) {
      AppErrorHandler.showMessage(
        context,
        'Password reset instructions have been sent to your email.',
      );
    }
  }

  Future<void> _resetPassword() async {
    if (_email.text.trim().isEmpty ||
        _token.text.trim().isEmpty ||
        _password.text.length < 8) {
      AppErrorHandler.showMessage(
        context,
        'Enter your email, reset token, and a password with at least 8 characters.',
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await AppErrorHandler.guard<bool>(context, () async {
      await _auth.resetPassword(
        email: _email.text.trim(),
        token: _token.text.trim(),
        password: _password.text,
      );
      return true;
    }, fallbackMessage: 'Could not reset the password.');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _reset = ok == true;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AC.s2,
                    borderRadius: Rd.mdA,
                    border: Border.all(color: AC.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AC.t1,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
            if (!_sent) ...[
              _hero(
                icon: Icons.lock_reset_rounded,
                color: AC.red,
                gradient: AC.redGrad,
              ),
              const SizedBox(height: 28),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we will send a reset token to your inbox.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AC.t3, height: 1.6),
              ),
              const SizedBox(height: 40),
              AppField(
                label: 'Email Address',
                hint: 'you@example.com',
                ctrl: _email,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 28),
              AppBtn(
                label: 'Send Reset Link',
                loading: _loading,
                onTap: _requestReset,
              ),
            ] else if (!_reset) ...[
              _hero(icon: Icons.mark_email_read_outlined, color: AC.success),
              const SizedBox(height: 28),
              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use the reset token from your email to choose a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AC.t3, height: 1.6),
              ),
              const SizedBox(height: 28),
              AppField(label: 'Reset Token', hint: 'Paste token', ctrl: _token),
              const SizedBox(height: 16),
              AppField(
                label: 'New Password',
                hint: 'At least 8 characters',
                ctrl: _password,
                obscure: true,
              ),
              const SizedBox(height: 28),
              AppBtn(
                label: 'Reset Password',
                loading: _loading,
                onTap: _resetPassword,
              ),
            ] else ...[
              _hero(icon: Icons.lock_open_rounded, color: AC.success),
              const SizedBox(height: 28),
              const Text(
                'Password Updated',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can now sign in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AC.t3, height: 1.6),
              ),
              const SizedBox(height: 40),
              AppBtn(
                label: 'Back to Login',
                onTap: () => Navigator.pushReplacementNamed(context, R.login),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _hero({
    required IconData icon,
    required Color color,
    Gradient? gradient,
  }) =>
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? color.withOpacity(0.12) : null,
          shape: BoxShape.circle,
          border: gradient == null
              ? Border.all(color: color.withOpacity(0.4))
              : null,
        ),
        child: Icon(
          icon,
          color: gradient == null ? color : Colors.white,
          size: 36,
        ),
      ).animate().scale(
        begin: const Offset(0, 0),
        duration: 600.ms,
        curve: Curves.elasticOut,
      );
}

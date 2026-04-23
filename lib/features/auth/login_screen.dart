import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/mock_data.dart';
import '../../shared/widgets/app_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _fk = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _showPass = false;

  Future<void> _login() async {
    if (!_fk.currentState!.validate()) return;

    setState(() => _loading = true);
    final role = await AppErrorHandler.guard<String?>(
      context,
      () async {
        await Future.delayed(1400.ms);
        final nextRole = await MockData.getRole();
        await MockData.loadCurrentUser();
        await MockData.saveToken(
          'mock_token_${DateTime.now().millisecondsSinceEpoch}',
        );
        return nextRole;
      },
      fallbackMessage: 'Could not sign you in right now.',
    );

    if (!mounted) return;

    setState(() => _loading = false);
    if (role == null) return;
    Navigator.pushReplacementNamed(
      context,
      role == 'workshop' ? R.wsDashboard : R.home,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AC.red.withOpacity(0.22),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _fk,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    GestureDetector(
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
                    const SizedBox(height: 36),
                    const Text(
                      'Welcome back 👋',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AC.t1,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(
                      begin: 0.3,
                      end: 0,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: AC.t3,
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 40),
                    AppField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      ctrl: _email,
                      keyboard: TextInputType.emailAddress,
                      prefix: const Icon(
                        Icons.email_outlined,
                        size: 18,
                        color: AC.t3,
                      ),
                      validator: (v) =>
                      v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())
                          ? 'Enter a valid email'
                          : null,
                    ).animate().fadeIn(delay: 200.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      label: 'Password',
                      hint: '••••••••',
                      ctrl: _pass,
                      obscure: !_showPass,
                      prefix: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AC.t3,
                      ),
                      suffix: GestureDetector(
                        onTap: () => setState(() => _showPass = !_showPass),
                        child: Icon(
                          _showPass
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AC.t3,
                        ),
                      ),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.length < 8) return 'Use at least 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add one uppercase letter';
                        if (!RegExp(r'\d').hasMatch(value)) return 'Add one number';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, R.forgotPassword),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AC.red,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 32),
                    AppBtn(
                      label: 'Sign In',
                      loading: _loading,
                      onTap: _login,
                    ).animate().fadeIn(delay: 400.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(
                          child: Divider(color: AC.border),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: AC.t3,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AC.border),
                        ),
                      ],
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 20),
                    AppBtn(
                      label: 'Continue with Google',
                      outline: true,
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AC.red,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () {},
                    ).animate().fadeIn(delay: 500.ms),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 13,
                            color: AC.t3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, R.register),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AC.red,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 550.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

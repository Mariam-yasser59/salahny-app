import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ring1, _ring2, _ring3;
  late final AnimationController _logo, _text, _progress;
  late final Animation<double> _logoScale, _logoOpacity, _logoRotate;
  late final Animation<double> _textOpacity, _textY, _progressVal;
  late final Animation<double> _ring1S, _ring1O, _ring2S, _ring2O;

  @override
  void initState() {
    super.initState();
    _ring1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _ring2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ring3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _logo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _text = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _ring1S = Tween(begin: 0.9, end: 2.2).animate(
      CurvedAnimation(parent: _ring1, curve: Curves.easeOut),
    );
    _ring1O = Tween(begin: 0.5, end: 0.0).animate(_ring1);
    _ring2S = Tween(begin: 0.9, end: 2.5).animate(
      CurvedAnimation(parent: _ring2, curve: Curves.easeOut),
    );
    _ring2O = Tween(begin: 0.3, end: 0.0).animate(_ring2);

    _logoScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logo, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logo, curve: const Interval(0, 0.4)),
    );
    _logoRotate = Tween(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _logo, curve: Curves.elasticOut),
    );
    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _text, curve: Curves.easeOut),
    );
    _textY = Tween(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(parent: _text, curve: Curves.easeOutCubic),
    );
    _progressVal = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progress, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _logo.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _text.forward();
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _progress.forward();
    });

    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(milliseconds: 3200));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_done') ?? false;

    // ✅ مهم:
    // مهما كان فيه token أو لا، متروحيش على home مباشرة من splash.
    // لازم بعد الـ splash يروح يا onboarding يا roleSelect.
    if (seen) {
      Navigator.pushReplacementNamed(context, R.roleSelect);
    } else {
      Navigator.pushReplacementNamed(context, R.onboarding);
    }
  }

  @override
  void dispose() {
    _ring1.dispose();
    _ring2.dispose();
    _ring3.dispose();
    _logo.dispose();
    _text.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _GridPainter()),
        Positioned(
          bottom: -100,
          left: 0,
          right: 0,
          child: Container(
            height: 350,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 1.0,
                colors: [AC.red.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _ring2,
                      builder: (_, __) => Transform.scale(
                        scale: _ring2S.value,
                        child: Opacity(
                          opacity: _ring2O.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AC.red.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _ring1,
                      builder: (_, __) => Transform.scale(
                        scale: _ring1S.value,
                        child: Opacity(
                          opacity: _ring1O.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AC.red.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _logo,
                      builder: (_, __) => Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotate.value,
                            child: Container(
                              width: 106,
                              height: 106,
                              decoration: BoxDecoration(
                                gradient: AC.redGrad,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AC.red.withOpacity(0.65),
                                    blurRadius: 44,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.car_repair_rounded,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _text,
                builder: (_, __) => Opacity(
                  opacity: _textOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _textY.value),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => LinearGradient(
                            colors: [AC.redLight, AC.red, AC.gold],
                          ).createShader(b),
                          child: const Text(
                            'SALAHNY',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Your Smart Auto Partner',
                          style: TextStyle(
                            fontSize: 13,
                            color: AC.t3,
                            fontFamily: 'Poppins',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              AnimatedBuilder(
                animation: _progress,
                builder: (_, __) {
                  final opacity = _progressVal.value < 0.15
                      ? _progressVal.value / 0.15
                      : 1.0;

                  return Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 130,
                          child: ClipRRect(
                            borderRadius: Rd.fullA,
                            child: LinearProgressIndicator(
                              value: _progressVal.value,
                              minHeight: 2,
                              backgroundColor: AC.border2,
                              valueColor:
                              const AlwaysStoppedAnimation(AC.red),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(_progressVal.value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AC.t3,
                            fontFamily: 'Poppins',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

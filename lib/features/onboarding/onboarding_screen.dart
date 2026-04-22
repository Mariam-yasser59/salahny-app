import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _ctrl = PageController();
  int _page = 0;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  static const _pages = [
    _Page(emoji:'🔧', title:'Smart Maintenance\nBooking', sub:'Book services from top-rated workshops near you with one tap — oil changes, brakes, tires and more.',  tag:'#1 in your city'),
    _Page(emoji:'🤖', title:'AI-Powered\nDiagnostics', sub:'Our OBD-II system detects issues before they become serious, with instant AI recommendations.', tag:'Powered by AI'),
    _Page(emoji:'🛡️', title:'24/7 Emergency\nProtection', sub:'Professional emergency response and smart subscription plans to keep you safe anywhere, anytime.', tag:'Always available'),
  ];

  @override void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
  }
  @override void dispose() { _fadeCtrl.dispose(); _ctrl.dispose(); super.dispose(); }

  void _next() async {
    if (_page < _pages.length - 1) {
      _fadeCtrl.reset(); _fadeCtrl.forward();
      _ctrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) Navigator.pushReplacementNamed(context, R.roleSelect);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: Stack(children: [
      Positioned(top: -80, right: -80, child: Container(width: 260, height: 260,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AC.red.withOpacity(0.1), Colors.transparent])))),
      Positioned(bottom: -60, left: -40, child: Container(width: 200, height: 200,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AC.gold.withOpacity(0.07), Colors.transparent])))),
      SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 6),
              width: i == _page ? 24 : 6, height: 6,
              decoration: BoxDecoration(
                color: i == _page ? AC.red : AC.border2, borderRadius: Rd.fullA)))),
            GestureDetector(onTap: _next, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AC.s2, borderRadius: Rd.fullA, border: Border.all(color: AC.border)),
              child: const Text('Skip', style: TextStyle(fontSize: 12, color: AC.t2, fontFamily: 'Poppins')))),
          ])),
        Expanded(child: PageView.builder(
          controller: _ctrl, itemCount: _pages.length,
          onPageChanged: (i) { setState(() => _page = i); _fadeCtrl.reset(); _fadeCtrl.forward(); },
          itemBuilder: (_, i) => FadeTransition(opacity: _fade, child: _PageView(page: _pages[i])),
        )),
        Padding(padding: const EdgeInsets.fromLTRB(24, 0, 24, 44), child: Column(children: [
          AppBtn(label: _page < _pages.length - 1 ? 'Continue' : 'Get Started',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            onTap: _next),
          if (_page < _pages.length - 1) ...[
            const SizedBox(height: 14),
            GestureDetector(onTap: _next, child: const Text('Skip all',
              style: TextStyle(fontSize: 12, color: AC.t3, fontFamily: 'Poppins'))),
          ],
        ])),
      ])),
    ]),
  );
}

class _PageView extends StatelessWidget {
  final _Page page;
  const _PageView({super.key, required this.page});
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 150, height: 150,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [AC.red.withOpacity(0.18), Colors.transparent])),
        child: Center(child: Text(page.emoji, style: const TextStyle(fontSize: 76)))),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(gradient: AC.goldGrad, borderRadius: Rd.fullA,
          boxShadow: [BoxShadow(color: AC.gold.withOpacity(0.4), blurRadius: 12)]),
        child: Text(page.tag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: AC.bg, fontFamily: 'Poppins'))),
      const SizedBox(height: 24),
      Text(page.title, textAlign: TextAlign.center, style: const TextStyle(
        fontSize: 32, fontWeight: FontWeight.w800, color: AC.t1, fontFamily: 'Poppins', height: 1.2)),
      const SizedBox(height: 18),
      Text(page.sub, textAlign: TextAlign.center, style: const TextStyle(
        fontSize: 15, color: AC.t3, fontFamily: 'Poppins', height: 1.7)),
    ]),
  );
}

class _Page {
  final String emoji, title, sub, tag;
  const _Page({required this.emoji, required this.title, required this.sub, required this.tag});
}

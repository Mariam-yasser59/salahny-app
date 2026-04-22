import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// APP COLORS
// ═══════════════════════════════════════════════════════════════
class AC {
  AC._();
  static const Color bg       = Color(0xFF080808);
  static const Color s1       = Color(0xFF111111);
  static const Color s2       = Color(0xFF181818);
  static const Color s3       = Color(0xFF202020);
  static const Color border   = Color(0xFF2A2A2A);
  static const Color border2  = Color(0xFF363636);
  static const Color red      = Color(0xFFBF1F2E);
  static const Color redDark  = Color(0xFF8B0F1A);
  static const Color redLight = Color(0xFFD93344);
  static const Color gold     = Color(0xFFD4A843);
  static const Color goldDark = Color(0xFF9E7A1E);
  static const Color goldLight= Color(0xFFE8C06A);
  static const Color purple   = Color(0xFF7C3AED);
  static const Color t1 = Color(0xFFF5F5F5);
  static const Color t2 = Color(0xFFAAAAAA);
  static const Color t3 = Color(0xFF666666);
  static const Color t4 = Color(0xFF3A3A3A);
  static const Color success  = Color(0xFF22C55E);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFEF4444);
  static const Color info     = Color(0xFF3B82F6);

  static Color get redGlow   => red.withOpacity(0.30);
  static Color get redGlow2  => red.withOpacity(0.10);
  static Color get goldGlow  => gold.withOpacity(0.25);

  static const LinearGradient redGrad = LinearGradient(
    colors: [redDark, red, redLight],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient goldGrad = LinearGradient(
    colors: [goldDark, gold, goldLight],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const LinearGradient cardGrad = LinearGradient(
    colors: [Color(0xFF1C1C1C), Color(0xFF141414)],
    begin: Alignment.topLeft, end: Alignment.bottomRight);
}

// ═══════════════════════════════════════════════════════════════
// SPACING & RADIUS
// ═══════════════════════════════════════════════════════════════
class Sp {
  Sp._();
  static const double x4  = 4;  static const double x8  = 8;
  static const double x12 = 12; static const double x16 = 16;
  static const double x20 = 20; static const double x24 = 24;
  static const double x32 = 32; static const double x40 = 40;
  static const double x48 = 48; static const double x64 = 64;
}

class Rd {
  Rd._();
  static const double xs=6; static const double sm=10;
  static const double md=14; static const double lg=20;
  static const double xl=28; static const double full=999;
  static BorderRadius get xsA   => BorderRadius.circular(xs);
  static BorderRadius get smA   => BorderRadius.circular(sm);
  static BorderRadius get mdA   => BorderRadius.circular(md);
  static BorderRadius get lgA   => BorderRadius.circular(lg);
  static BorderRadius get xlA   => BorderRadius.circular(xl);
  static BorderRadius get fullA => BorderRadius.circular(full);
}

// ═══════════════════════════════════════════════════════════════
// SHADOWS
// ═══════════════════════════════════════════════════════════════
class AS {
  AS._();
  static List<BoxShadow> get redGlow => [
    BoxShadow(color: AC.red.withOpacity(0.45), blurRadius: 24, spreadRadius: -4),
    BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
  ];
  static List<BoxShadow> get goldGlow => [
    BoxShadow(color: AC.gold.withOpacity(0.40), blurRadius: 24, spreadRadius: -4),
  ];
  static List<BoxShadow> get card => [
    BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
  ];
}

// ═══════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AC.bg,
    fontFamily: 'Poppins',
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AC.red, onPrimary: Colors.white,
      secondary: AC.gold, onSecondary: AC.bg,
      surface: AC.s1, onSurface: AC.t1,
      error: AC.error, outline: AC.border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent, elevation: 0,
      scrolledUnderElevation: 0, centerTitle: true,
      iconTheme: IconThemeData(color: AC.t1, size: 22),
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: AC.t1),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: AC.s2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: Rd.mdA, borderSide: const BorderSide(color: AC.border)),
      enabledBorder: OutlineInputBorder(borderRadius: Rd.mdA, borderSide: const BorderSide(color: AC.border)),
      focusedBorder: OutlineInputBorder(borderRadius: Rd.mdA, borderSide: const BorderSide(color: AC.red, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: Rd.mdA, borderSide: const BorderSide(color: AC.error)),
      hintStyle: const TextStyle(color: AC.t4, fontFamily: 'Poppins', fontSize: 14),
      labelStyle: const TextStyle(color: AC.t3, fontFamily: 'Poppins', fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: AC.s2, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: Rd.lgA, side: const BorderSide(color: AC.border, width: 0.5)),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AC.border, thickness: 0.5, space: 0),
    iconTheme: const IconThemeData(color: AC.t2, size: 22),
    splashColor: Colors.transparent, highlightColor: Colors.transparent,
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AC.t1, height: 1.1),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AC.t1),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AC.t1),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AC.t1),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AC.t1),
      bodyLarge: TextStyle(fontSize: 15, color: AC.t1, height: 1.6),
      bodyMedium: TextStyle(fontSize: 14, color: AC.t2, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, color: AC.t3),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AC.t1),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AC.t2),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AC.t3, letterSpacing: 0.8),
    ),
  );
}

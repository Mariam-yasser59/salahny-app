import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/navigation/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AC.s1,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const SalahnyApp());
}

class SalahnyApp extends StatelessWidget {
  const SalahnyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    initialRoute: R.splash,
    onGenerateRoute: onGenerateRoute,
  );
}

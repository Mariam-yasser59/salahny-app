import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/errors/app_error_handler.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/navigation/router.dart';
import 'shared/services/mock_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppErrorHandler.report(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppErrorHandler.report(error, stackTrace);
    return true;
  };

  await runZonedGuarded(() async {
    await MockData.loadCurrentUser();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AC.s1,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    runApp(const SalahnyApp());
  }, AppErrorHandler.report);
}

class SalahnyApp extends StatelessWidget {
  const SalahnyApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: AppErrorHandler.messengerKey,
    theme: AppTheme.dark,
    initialRoute: R.splash,
    onGenerateRoute: onGenerateRoute,
  );
}

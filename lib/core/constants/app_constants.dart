// ═══════════════════════════════════════════════════════════════
// APP CONSTANTS
// ═══════════════════════════════════════════════════════════════
class AppConstants {
  AppConstants._();

  static const String appName = 'Salahny';
  static const String appTagline = 'Your Smart Auto Partner';
  static const String version = '1.0.0';

  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animMed = Duration(milliseconds: 380);
  static const Duration animSlow = Duration(milliseconds: 550);
  static const Duration animPage = Duration(milliseconds: 320);
}

// ═══════════════════════════════════════════════════════════════
// NAMED ROUTES
// ═══════════════════════════════════════════════════════════════
class R {
  R._();

  // Core
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelect = '/role-select';

  // Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';

  // Driver App
  static const String home = '/home';
  static const String services = '/services';
  static const String serviceDetail = '/service-detail';
  static const String bookService = '/book-service';
  static const String bookingConfirm = '/booking-confirm';
  static const String bookingTrack = '/booking-track';
  static const String workshops = '/workshops';
  static const String workshopDetail = '/workshop-detail';
  static const String diagnostics = '/diagnostics';
  static const String diagResult = '/diag-result';
  static const String diagHistory = '/diag-history';
  static const String packages = '/packages';
  static const String checkout = '/checkout';
  static const String paySuccess = '/pay-success';
  static const String aiChat = '/ai-chat';
  static const String mechanicChat = '/mechanic-chat';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';
  static const String vehicles = '/vehicles';
  static const String addVehicle = '/add-vehicle';
  static const String emergency = '/emergency';
  static const String history = '/history';
  static const String reviews = '/reviews';
  static const String privacy = '/privacy';
  static const String about = '/about';

  // Workshop App
  static const String wsDashboard = '/ws/dashboard';
  static const String wsRequests = '/ws/requests';
  static const String wsReqDetail = '/ws/req-detail';
  static const String wsActiveJobs = '/ws/active-jobs';
  static const String wsServices = '/ws/services';
  static const String wsEarnings = '/ws/earnings';
  static const String wsProfile = '/ws/profile';
  static const String wsSchedule = '/ws/schedule';
  static const String wsDiagnostics = '/ws/diagnostics';
  static const String wsAiReport = '/ws/ai-report';
  static const String wsChat = '/ws/chat';
}
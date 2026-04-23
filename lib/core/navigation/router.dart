import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

// Core
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';

// Auth
import '../../features/auth/role_selection_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/forgot_password_screen.dart';

// Driver
import '../../features/driver/home/home_screen.dart';
import '../../features/driver/services/services_screen.dart';
import '../../features/driver/booking/book_service_screen.dart';
import '../../features/driver/booking/booking_confirm_screen.dart';
import '../../features/driver/workshops/workshops_screen.dart';
import '../../features/driver/workshops/workshop_detail_screen.dart';
import '../../features/driver/diagnostics/diagnostics_screen.dart';
import '../../features/driver/diagnostics/diag_result_screen.dart';
import '../../features/driver/diagnostics/diag_history_screen.dart';
import '../../features/driver/packages/packages_screen.dart';
import '../../features/driver/packages/checkout_screen.dart';
import '../../features/driver/packages/pay_success_screen.dart';
import '../../features/driver/chat/ai_chat_screen.dart';
import '../../features/driver/chat/mechanic_chat_screen.dart';
import '../../features/driver/notifications/notifications_screen.dart';
import '../../features/driver/profile/profile_screen.dart';
import '../../features/driver/profile/edit_profile_screen.dart';
import '../../features/driver/profile/settings_screen.dart';
import '../../features/driver/profile/privacy_screen.dart';
import '../../features/driver/profile/about_screen.dart';
import '../../features/driver/vehicles/vehicles_screen.dart';
import '../../features/driver/vehicles/add_vehicle_screen.dart';
import '../../features/driver/emergency/emergency_screen.dart';

// Shared models
import '../../shared/models/models.dart';
import '../../shared/services/mock_data.dart';

// Workshop
import '../../features/workshop/ws_dashboard_screen.dart';
import '../../features/workshop/ws_requests_screen.dart';
import '../../features/workshop/ws_req_detail_screen.dart';
import '../../features/workshop/ws_active_jobs_screen.dart';
import '../../features/workshop/ws_services_screen.dart';
import '../../features/workshop/ws_earnings_screen.dart';
import '../../features/workshop/ws_profile_screen.dart';
import '../../features/workshop/ws_diagnostics_screen.dart';
import '../../features/workshop/ws_ai_report_screen.dart';
import '../../features/workshop/ws_chat_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings s) {
  Widget page;

  switch (s.name) {
  // ─── Core ────────────────────────────────────────────────────
    case R.splash:
      page = const SplashScreen();
      break;
    case R.onboarding:
      page = const OnboardingScreen();
      break;
    case R.roleSelect:
      page = const RoleSelectionScreen();
      break;

  // ─── Auth ────────────────────────────────────────────────────
    case R.login:
      page = const LoginScreen();
      break;
    case R.register:
      page = const RegisterScreen();
      break;
    case R.otp:
      page = const OtpScreen();
      break;
    case R.forgotPassword:
      page = const ForgotPasswordScreen();
      break;

  // ─── Driver App ──────────────────────────────────────────────
    case R.home:
      page = const HomeScreen();
      break;
    case R.services:
      page = const ServicesScreen();
      break;
    case R.bookService:
      page = const BookServiceScreen();
      break;
    case R.bookingConfirm:
      page = const BookingConfirmScreen();
      break;
    case R.bookingTrack:
      page = const _TrackingRouteScreen();
      break;
    case R.workshops:
      page = const WorkshopsScreen();
      break;
    case R.workshopDetail:
      page = const WorkshopDetailScreen();
      break;
    case R.diagnostics:
      page = const DiagnosticsScreen();
      break;
    case R.diagResult:
      page = const DiagResultScreen();
      break;
    case R.diagHistory:
      page = const DiagHistoryScreen();
      break;
    case R.packages:
      page = const PackagesScreen();
      break;
    case R.checkout:
      page = const CheckoutScreen();
      break;
    case R.paySuccess:
      page = const PaySuccessScreen();
      break;
    case R.aiChat:
      page = const AiChatScreen();
      break;
    case R.mechanicChat:
      page = const MechanicChatScreen();
      break;
    case R.notifications:
      page = const NotificationsScreen();
      break;
    case R.profile:
      page = const ProfileScreen();
      break;
    case R.editProfile:
      page = const EditProfileScreen();
      break;
    case R.settings:
      page = const SettingsScreen();
      break;
    case R.privacy:
      page = const PrivacyScreen();
      break;
    case R.about:
      page = const AboutScreen();
      break;
    case R.vehicles:
      page = const VehiclesScreen();
      break;
    case R.addVehicle:
      page = const AddVehicleScreen();
      break;
    case R.emergency:
      page = const EmergencyScreen();
      break;

  // ─── Workshop App ────────────────────────────────────────────
    case R.wsDashboard:
      page = const WsDashboardScreen();
      break;
    case R.wsRequests:
      page = const WsRequestsScreen();
      break;
    case R.wsActiveJobs:
      page = const WsActiveJobsScreen();
      break;
    case R.wsServices:
      page = const WsServicesScreen();
      break;
    case R.wsEarnings:
      page = const WsEarningsScreen();
      break;
    case R.wsProfile:
      page = const WsProfileScreen();
      break;
    case R.wsDiagnostics:
      page = const WsDiagnosticsScreen();
      break;

    case R.wsReqDetail:
      final booking = s.arguments as WsBookingData;
      page = WsReqDetailScreen(booking: booking);
      break;

    case R.wsAiReport:
      final rid = s.arguments as String?;
      page = WsAiReportScreen(linkedRequestId: rid);
      break;

    case R.wsChat:
      final args = s.arguments as Map<String, String>? ?? {};
      page = WsChatScreen(
        bookingId: args['bookingId'] ?? '',
        customerName: args['customerName'] ?? 'Customer',
      );
      break;

    default:
      page = const SplashScreen();
  }

  return PageRouteBuilder(
    settings: s,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a1, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: a1, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: a1, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    transitionDuration: const Duration(milliseconds: 280),
  );
}

class _TrackingRouteScreen extends StatelessWidget {
  const _TrackingRouteScreen();

  @override
  Widget build(BuildContext context) {
    final booking = AppData.i.bookings.first;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        foregroundColor: Colors.white,
        title: const Text('Track Booking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.serviceName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${booking.workshopName} • ${booking.date} ${booking.time}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              'Status: ${booking.status}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Total: \$${booking.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

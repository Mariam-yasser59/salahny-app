import 'dart:async';

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
import '../../features/admin/admin_login_screen.dart';
import '../../features/admin/admin_workshop_chat_screen.dart';
import '../../features/admin/admin_documents_screen.dart';
import '../../features/admin/admin_driver_chat_screen.dart';
import '../../features/admin/emergency_management_screen.dart';
import '../../features/admin/diagnostics_management_screen.dart';

// Driver
import '../../features/driver/home/home_screen.dart';
import '../../features/driver/services/services_screen.dart';
import '../../features/driver/booking/book_service_screen.dart';
import '../../features/driver/booking/booking_confirm_screen.dart';
import '../../features/driver/booking/booking_success_tracking_screen.dart';
import '../../features/driver/booking/services/tracking_service.dart';
import '../network/realtime_service.dart';
import '../../features/driver/workshops/workshops_screen.dart';
import '../../features/driver/workshops/workshop_detail_screen.dart';
import '../../features/driver/diagnostics/diagnostics_screen.dart';
import '../../features/driver/diagnostics/diag_result_screen.dart';
import '../../features/driver/diagnostics/diag_history_screen.dart';
import '../../features/driver/packages/packages_screen.dart';
import '../../features/driver/packages/checkout_screen.dart';
import '../../features/driver/packages/demo_subscription_payment_screen.dart';
import '../../features/driver/packages/pay_success_screen.dart';
import '../../features/driver/packages/subscription_success_screen.dart';
import '../../features/driver/chat/ai_chat_screen.dart';
import '../../features/driver/chat/mechanic_chat_screen.dart';
import '../../features/driver/chat/admin_chat_screen.dart';
import '../../features/driver/notifications/notifications_screen.dart';
import '../../features/driver/profile/profile_screen.dart';
import '../../features/driver/profile/edit_profile_screen.dart';
import '../../features/driver/profile/settings_screen.dart';
import '../../features/driver/profile/privacy_screen.dart';
import '../../features/driver/profile/about_screen.dart';
import '../../features/driver/vehicles/vehicles_screen.dart';
import '../../features/driver/vehicles/add_vehicle_screen.dart';
import '../../features/driver/emergency/emergency_screen.dart';
import '../../features/documents/documents_screen.dart';

// Shared models
import '../../shared/models/models.dart';
import '../../shared/services/app_cache.dart';

// Workshop
import '../../features/workshop/ws_dashboard_screen.dart';
import '../../features/workshop/ws_requests_screen.dart';
import '../../features/workshop/ws_req_detail_screen.dart';
import '../../features/workshop/ws_active_jobs_screen.dart';
import '../../features/workshop/ws_services_screen.dart';
import '../../features/workshop/ws_schedule_screen.dart';
import '../../features/workshop/ws_earnings_screen.dart';
import '../../features/workshop/ws_profile_screen.dart';
import '../../features/workshop/ws_diagnostics_screen.dart';
import '../../features/workshop/ws_ai_report_screen.dart';
import '../../features/workshop/ws_chat_screen.dart';
import '../../features/admin/pending_approvals_screen.dart';
import '../../features/admin/drivers_management_screen.dart';
import '../../features/admin/workshops_management_screen.dart';
import '../../features/admin/bookings_management_screen.dart';
import '../../features/admin/services_management_screen.dart';
import '../../features/admin/packages_management_screen.dart';
import '../../features/admin/activity_logs_screen.dart';
import '../../features/admin/admin_settings_screen.dart';
import '../../features/admin/super_admin_shell.dart';

Route<dynamic> onGenerateRoute(RouteSettings s) {
  Widget page;
  if (AppCache.isGuest && _guestRestrictedRoutes.contains(s.name)) {
    page = const _GuestRestrictedScreen();
    return _buildRoute(s, page);
  }

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
    case R.adminLogin:
      page = const AdminLoginScreen();
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
      page = const BookingSuccessTrackingScreen();
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
    case R.demoSubscriptionPayment:
      page = const DemoSubscriptionPaymentScreen();
      break;
    case R.subscriptionSuccess:
      page = const SubscriptionSuccessScreen();
      break;
    case R.paySuccess:
      page = const PaySuccessScreen();
      break;
    case R.aiChat:
      page = const AiChatScreen();
      break;
    case R.mechanicChat:
      page = MechanicChatScreen(bookingId: s.arguments as String?);
      break;
    case R.adminChat:
      page = const AdminChatScreen();
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
    case R.documents:
      page = const DocumentsScreen();
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
    case R.wsSchedule:
      page = const WsScheduleScreen();
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
    case R.wsAdminChat:
      page = const AdminWorkshopChatScreen(workshopMode: true);
      break;

    case R.saDashboard:
      page = const SuperAdminShell();
      break;
    case R.saApprovals:
      page = const PendingApprovalsScreen();
      break;
    case R.saDrivers:
      page = const DriversManagementScreen();
      break;
    case R.saWorkshops:
      page = const WorkshopsManagementScreen();
      break;
    case R.saBookings:
      page = const BookingsManagementScreen();
      break;
    case R.saServices:
      page = const ServicesManagementScreen();
      break;
    case R.saPackages:
      page = const PackagesManagementScreen();
      break;
    case R.saLogs:
      page = const ActivityLogsScreen();
      break;
    case R.saSettings:
      page = const AdminSettingsScreen();
      break;
    case R.saDocuments:
      page = const AdminDocumentsScreen();
      break;
    case R.saDriverChat:
      final args = s.arguments as Map<String, String>? ?? {};
      page = AdminDriverChatScreen(
        driverId: args['driverId'] ?? '',
        driverName: args['driverName'] ?? 'Driver',
      );
      break;
    case R.saEmergency:
      page = const EmergencyManagementScreen();
      break;
    case R.saDiagnostics:
      page = const DiagnosticsManagementScreen();
      break;
    case R.saWorkshopChat:
      final args = s.arguments as Map<String, String>? ?? {};
      page = AdminWorkshopChatScreen(
        workshopId: args['workshopId'],
        workshopName: args['workshopName'] ?? 'Workshop',
      );
      break;

    default:
      page = const SplashScreen();
  }

  return _buildRoute(s, page);
}

const _guestRestrictedRoutes = {
  R.bookService,
  R.bookingConfirm,
  R.bookingTrack,
  R.diagnostics,
  R.diagResult,
  R.diagHistory,
  R.checkout,
  R.demoSubscriptionPayment,
  R.subscriptionSuccess,
  R.paySuccess,
  R.aiChat,
  R.mechanicChat,
  R.adminChat,
  R.notifications,
  R.profile,
  R.editProfile,
  R.settings,
  R.documents,
  R.vehicles,
  R.addVehicle,
  R.emergency,
};

PageRouteBuilder<dynamic> _buildRoute(RouteSettings s, Widget page) =>
    PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a1, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a1, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a1, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 280),
    );

class _GuestRestrictedScreen extends StatelessWidget {
  const _GuestRestrictedScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0B0B0B),
    appBar: AppBar(backgroundColor: const Color(0xFF0B0B0B)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 46,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please log in or create an account to use this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, R.login),
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, R.register),
                    child: const Text('Register'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TrackingRouteScreen extends StatefulWidget {
  const _TrackingRouteScreen();

  @override
  State<_TrackingRouteScreen> createState() => _TrackingRouteScreenState();
}

class _TrackingRouteScreenState extends State<_TrackingRouteScreen> {
  final _tracking = TrackingService();
  List<TrackingPoint> _points = const [];
  StreamSubscription<RealtimeEvent>? _subscription;

  Future<void> _load(String bookingId) async {
    if (bookingId.isEmpty) return;
    await RealtimeService.instance.joinBooking(bookingId);
    _subscription ??= RealtimeService.instance.events.listen((event) {
      if (event.type != 'tracking_update') return;
      final point = _tracking.mapPoint(event.data);
      if (mounted) setState(() => _points = [point, ..._points]);
    });
    final points = await _tracking
        .getUpdates(bookingId)
        .catchError((_) => const <TrackingPoint>[]);
    if (mounted) setState(() => _points = points);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = ModalRoute.of(context)?.settings.arguments as String?;
    final bookings = AppData.i.bookings;
    if (bookings.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
          title: const Text('Track Booking'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No bookings available to track yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }
    final booking = bookings.firstWhere(
      (item) => item.id == bookingId,
      orElse: () => bookings.first,
    );
    if (_points.isEmpty) {
      _load(booking.id);
    }
    final latest = _points.isEmpty ? null : _points.first;

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
              'Total: EGP ${booking.price.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              latest == null
                  ? 'Live location: waiting for workshop update'
                  : 'Live location: ${latest.latitude.toStringAsFixed(5)}, ${latest.longitude.toStringAsFixed(5)}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              latest == null
                  ? 'ETA: unavailable'
                  : 'ETA: ${latest.etaMinutes} min',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

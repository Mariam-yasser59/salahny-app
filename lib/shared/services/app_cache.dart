import 'package:shared_preferences/shared_preferences.dart';

import '../models/admin_models.dart';
import '../models/models.dart';

class WorkshopProfileData {
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final double rating;
  final bool isOpen;
  final bool isVerified;
  final String accountStatus;
  final String address;
  final double? latitude;
  final double? longitude;
  final double monthlyRevenue;
  final String revenuePeriod;
  final String payoutMethod;
  final int completedServices;
  final int reviewCount;

  const WorkshopProfileData({
    required this.id,
    required this.name,
    required this.initials,
    required this.specialty,
    required this.rating,
    required this.isOpen,
    required this.isVerified,
    required this.accountStatus,
    this.address = '',
    this.latitude,
    this.longitude,
    required this.monthlyRevenue,
    required this.revenuePeriod,
    required this.payoutMethod,
    this.completedServices = 0,
    this.reviewCount = 0,
  });
}

abstract class AppDataSource {
  UserModel get currentUser;
  List<VehicleModel> get vehicles;
  List<ServiceModel> get services;
  List<WorkshopModel> get workshops;
  List<BookingModel> get bookings;
  BookingCheckoutData get bookingCheckout;
  List<PackageModel> get packages;
  List<NotificationModel> get notifications;
  DiagnosticReport get latestDiagnosticReport;
  List<DiagnosticReport> get diagnosticHistory;
  DiagnosticModel get diagnosticSummary;
  List<WsBookingData> get workshopBookings;
  List<WsServiceItem> get workshopServices;
  List<WsPayoutData> get workshopPayouts;
  WorkshopProfileData get workshopProfile;
}

class CachedAppDataSource implements AppDataSource {
  const CachedAppDataSource();

  @override
  UserModel get currentUser => AppCache.currentUser;

  @override
  List<VehicleModel> get vehicles => AppCache.vehicles;

  @override
  List<ServiceModel> get services => AppCache.services;

  @override
  List<WorkshopModel> get workshops => AppCache.workshops;

  @override
  List<BookingModel> get bookings => AppCache.bookings;

  @override
  BookingCheckoutData get bookingCheckout => AppCache.bookingCheckout;

  @override
  List<PackageModel> get packages => AppCache.packages;

  @override
  List<NotificationModel> get notifications => AppCache.notifications;

  @override
  DiagnosticReport get latestDiagnosticReport =>
      AppCache.latestDiagnosticReport;

  @override
  List<DiagnosticReport> get diagnosticHistory => AppCache.diagnosticHistory;

  @override
  DiagnosticModel get diagnosticSummary => AppCache.diagnosticSummary;

  @override
  List<WsBookingData> get workshopBookings => AppCache.workshopBookings;

  @override
  List<WsServiceItem> get workshopServices => AppCache.workshopServices;

  @override
  List<WsPayoutData> get workshopPayouts => AppCache.workshopPayouts;

  @override
  WorkshopProfileData get workshopProfile => AppCache.workshopProfile;
}

class AppData {
  AppData._();

  static AppDataSource _source = const CachedAppDataSource();

  static AppDataSource get i => _source;

  static void useSource(AppDataSource source) {
    _source = source;
  }
}

class AppCache {
  AppCache._();

  static const AdminUser superAdmin = AdminUser(
    id: 'admin_1',
    name: 'Salahny Super Admin',
    email: 'admin@salahny.com',
    password: 'admin123',
  );
  static String _adminPassword = superAdmin.password;

  static const List<PaymentOptionData> _paymentOptions = [
    PaymentOptionData(id: 'card', icon: '💳', label: 'Credit / Debit Card'),
    PaymentOptionData(id: 'wallet', icon: '📱', label: 'Apple Pay'),
    PaymentOptionData(id: 'cash', icon: '💵', label: 'Cash on Service'),
  ];

  static UserModel _currentUser = const UserModel(
    id: '',
    name: '',
    phone: '',
    email: '',
  );
  static bool _isGuest = false;
  static List<VehicleModel> _vehicles = [];
  static String? _preferredVehicleId;
  static BookingCheckoutData? _bookingCheckout;
  static List<WorkshopModel>? _remoteWorkshops;
  static List<BookingModel>? _remoteBookings;
  static List<ServiceModel>? _remoteServices;
  static List<PackageModel>? _remotePackages;
  static List<DriverUser>? _remoteDrivers;
  static List<WorkshopUser>? _remoteAdminWorkshops;
  static List<AdminBooking>? _remoteAdminBookings;
  static List<ManagedService>? _remoteManagedServices;
  static List<ManagedPackage>? _remoteManagedPackages;
  static List<ActivityLogEntry>? _remoteActivityLogs;
  static List<NotificationModel>? _remoteNotifications;
  static AdminSettingsData? _remoteAdminSettings;
  static AdminAnalyticsData? _remoteAdminAnalytics;
  static DiagnosticReport? _remoteLatestDiagnosticReport;
  static List<DiagnosticReport>? _remoteDiagnosticHistory;
  static List<WsBookingData>? _remoteWorkshopBookings;
  static List<WsServiceItem>? _remoteWorkshopServices;
  static WorkshopProfileData? _remoteWorkshopProfile;

  static List<DriverUser> _drivers = [];
  static List<WorkshopUser> _adminWorkshops = [];
  static List<ManagedService> _managedServices = [];
  static List<ManagedPackage> _managedPackages = [];
  static List<AdminBooking> _adminBookings = [];
  static List<ActivityLogEntry> _activityLogs = [];

  static AdminSettingsData _adminSettings = const AdminSettingsData(
    privacyPolicy: '',
    aboutContent: '',
    announcementTitle: '',
    announcementBody: '',
    notificationsEnabled: false,
  );

  static UserModel get currentUser => _currentUser;
  static bool get isGuest => _isGuest;
  static List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  static String? get preferredVehicleId => _preferredVehicleId;
  static BookingCheckoutData get bookingCheckout =>
      _bookingCheckout ?? _buildDefaultBookingCheckout();

  static List<DriverUser> get drivers =>
      List.unmodifiable(_remoteDrivers ?? _drivers);
  static List<DriverUser> get pendingDrivers => List.unmodifiable(
    drivers.where((d) => d.status == AdminAccountStatus.pending).toList(),
  );

  static List<WorkshopUser> get adminWorkshops =>
      List.unmodifiable(_remoteAdminWorkshops ?? _adminWorkshops);
  static List<WorkshopUser> get pendingWorkshops => List.unmodifiable(
    adminWorkshops
        .where((w) => w.status == AdminAccountStatus.pending)
        .toList(),
  );

  static List<ManagedService> get managedServices =>
      List.unmodifiable(_remoteManagedServices ?? _managedServices);
  static List<ManagedPackage> get managedPackages =>
      List.unmodifiable(_remoteManagedPackages ?? _managedPackages);
  static List<AdminBooking> get adminBookings =>
      List.unmodifiable(_remoteAdminBookings ?? _adminBookings);
  static List<ActivityLogEntry> get activityLogs =>
      List.unmodifiable(_remoteActivityLogs ?? _activityLogs);
  static AdminSettingsData get adminSettings =>
      _remoteAdminSettings ?? _adminSettings;
  static AdminAnalyticsData get adminAnalytics =>
      _remoteAdminAnalytics ?? AdminAnalyticsData.empty;

  static List<ServiceModel> get services {
    if (_remoteServices != null) {
      return List.unmodifiable(_remoteServices!);
    }
    return _managedServices
        .where((service) => service.isEnabled)
        .map((service) => service.toServiceModel())
        .toList(growable: false);
  }

  static List<PackageModel> get packages {
    if (_remotePackages != null) {
      return List.unmodifiable(_remotePackages!);
    }
    return _managedPackages
        .where((pkg) => pkg.isEnabled)
        .map((pkg) => pkg.toPackageModel())
        .toList(growable: false);
  }

  static List<WorkshopModel> get workshops {
    if (_remoteWorkshops != null) {
      return List.unmodifiable(_remoteWorkshops!);
    }
    final active = adminWorkshops
        .where(
          (workshop) =>
              workshop.status == AdminAccountStatus.active ||
              workshop.status == AdminAccountStatus.suspended,
        )
        .toList();
    return List<WorkshopModel>.generate(
      active.length,
      (index) => active[index].toWorkshopModel(distance: 0.8 + index * 1.3),
      growable: false,
    );
  }

  static List<BookingModel> get bookings {
    if (_remoteBookings != null) {
      return List.unmodifiable(_remoteBookings!);
    }
    return adminBookings
        .map((booking) => booking.toBookingModel())
        .toList(growable: false);
  }

  static WorkshopProfileData get workshopProfile {
    if (_remoteWorkshopProfile != null) {
      return _remoteWorkshopProfile!;
    }
    final workshop = adminWorkshops.firstWhere(
      (item) => item.status == AdminAccountStatus.active,
      orElse: () =>
          adminWorkshops.firstOrNull ??
          WorkshopUser(
            id: '',
            name: 'Workshop',
            email: '',
            phone: '',
            address: '',
            specialty: '',
            rating: 0,
            totalJobs: 0,
            revenue: 0,
            isVerified: false,
            status: AdminAccountStatus.pending,
            joinedAt: DateTime.now(),
          ),
    );
    final initials = workshop.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return WorkshopProfileData(
      id: workshop.id,
      name: workshop.name,
      initials: initials.isEmpty ? 'SA' : initials,
      specialty: workshop.specialty,
      rating: workshop.rating,
      isOpen: workshop.status == AdminAccountStatus.active,
      isVerified: workshop.isVerified,
      accountStatus: workshop.status.label.toLowerCase(),
      address: workshop.address,
      monthlyRevenue: workshop.revenue,
      revenuePeriod: _currentMonthLabel(),
      payoutMethod: 'Bank Transfer',
    );
  }

  static List<WsBookingData> get workshopBookings =>
      List.unmodifiable(_remoteWorkshopBookings ?? const []);

  static List<WsServiceItem> get workshopServices {
    if (_remoteWorkshopServices != null) {
      return List.unmodifiable(_remoteWorkshopServices!);
    }
    if (_remoteServices != null) {
      return _remoteServices!
          .map(
            (service) => WsServiceItem(
              emoji: service.emoji,
              name: service.name,
              durationMins: service.durationMins,
              price: service.price,
            ),
          )
          .toList(growable: false);
    }
    return const [];
  }

  static List<WsPayoutData> get workshopPayouts {
    final bookings = workshopBookings
        .where((item) => item.status != RequestStatus.cancelled)
        .toList();
    if (bookings.isEmpty) {
      return const [];
    }
    final total = bookings.fold<double>(0, (sum, item) => sum + item.price);
    return [
      WsPayoutData(period: 'Current Period', amount: total),
      WsPayoutData(period: 'Previous Period', amount: total * 0.82),
      WsPayoutData(period: 'Two Periods Ago', amount: total * 0.74),
    ];
  }

  static DiagnosticReport get latestDiagnosticReport =>
      _remoteLatestDiagnosticReport ??
      (_remoteDiagnosticHistory?.isNotEmpty == true
          ? _remoteDiagnosticHistory!.first
          : DiagnosticReport(
              id: '',
              vehicleId: vehicles.firstOrNull?.id ?? '',
              date: appShortDate(0),
              summary: 'No diagnostic report yet',
              riskLevel: RiskLevel.healthy,
              health: 0,
              faultCodes: const [],
              vitals: const [],
              recommendations: const [],
            ));

  static List<DiagnosticReport> get diagnosticHistory =>
      List.unmodifiable(_remoteDiagnosticHistory ?? const []);

  static DiagnosticModel get diagnosticSummary {
    final report = latestDiagnosticReport;
    return DiagnosticModel(
      id: report.id,
      vehicleId: report.vehicleId,
      date: report.date,
      summary: report.summary,
      health: report.health,
      codes: report.faultCodes
          .map((code) => '${code.code} - ${code.description}')
          .toList(growable: false),
      recommendations: List<String>.from(report.recommendations),
      vitals: {for (final vital in report.vitals) vital.key: vital.value},
    );
  }

  static int get totalRevenue =>
      adminBookings.fold<int>(0, (sum, booking) => sum + booking.total.toInt());

  static int get pendingApprovalsCount =>
      pendingDrivers.length + pendingWorkshops.length;

  static bool validateAdminCredentials(String email, String password) {
    return email.trim().toLowerCase() == superAdmin.email &&
        password == _adminPassword;
  }

  static BookingCheckoutData _buildDefaultBookingCheckout() {
    final service = services.firstOrNull;
    final workshop = workshops.firstOrNull;
    final vehicle = _vehicles.firstOrNull;
    final serviceFee = double.parse(
      ((service?.price ?? 0) * 0.10).toStringAsFixed(2),
    );
    const discount = 0.0;
    return BookingCheckoutData(
      serviceId: service?.id ?? '',
      serviceName: service?.name ?? '',
      workshopId: workshop?.id ?? '',
      workshopName: workshop?.name ?? '',
      vehicleId: vehicle?.id ?? '',
      vehicleLabel: vehicle?.fullName ?? '',
      date: '',
      time: '',
      slotIso: '',
      durationMins: service?.durationMins ?? 0,
      subtotal: service?.price ?? 0,
      serviceFee: serviceFee,
      discount: discount,
      total: service == null ? 0 : service.price + serviceFee - discount,
      paymentOptions: _paymentOptions,
      selectedPaymentOptionId: _paymentOptions.first.id,
    );
  }

  static Future<void> loadCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    _adminPassword =
        p.getString('admin_password_override') ?? superAdmin.password;
    _currentUser = UserModel(
      id: p.getString('user_id') ?? '',
      name: p.getString('user_name') ?? '',
      phone: p.getString('user_phone') ?? '',
      email: p.getString('user_email') ?? '',
      role: p.getString('user_role') ?? 'driver',
      walletBalance: p.getDouble('user_wallet') ?? 0,
      rating: p.getDouble('user_rating') ?? 0,
      totalBookings: p.getInt('user_bookings') ?? 0,
      vehicleCount: p.getInt('user_vehicle_count') ?? 0,
    );
    _isGuest = p.getBool('guest_mode') ?? false;
    final savedVehicle = p.getStringList('user_vehicle');
    if (savedVehicle != null && savedVehicle.length >= 4) {
      _vehicles = [
        VehicleModel(
          id: 'v_user',
          make: savedVehicle[0],
          model: savedVehicle[1],
          year: savedVehicle[2],
          plate: savedVehicle[3],
          color: savedVehicle.length > 4 ? savedVehicle[4] : 'Custom',
          mileage: savedVehicle.length > 5
              ? int.tryParse(savedVehicle[5]) ?? 0
              : 0,
          health: savedVehicle.length > 6
              ? double.tryParse(savedVehicle[6]) ?? 85
              : 85,
        ),
      ];
    }
    _preferredVehicleId = p.getString('preferred_vehicle_id');
    final savedCheckout = p.getStringList('booking_checkout');
    if (savedCheckout != null && savedCheckout.length >= 14) {
      final hasSlotIso = savedCheckout.length >= 15;
      _bookingCheckout = BookingCheckoutData(
        serviceId: savedCheckout[0],
        serviceName: savedCheckout[1],
        workshopId: savedCheckout[2],
        workshopName: savedCheckout[3],
        vehicleId: savedCheckout[4],
        vehicleLabel: savedCheckout[5],
        date: savedCheckout[6],
        time: savedCheckout[7],
        slotIso: hasSlotIso ? savedCheckout[8] : '',
        durationMins: int.tryParse(savedCheckout[hasSlotIso ? 9 : 8]) ?? 0,
        subtotal: double.tryParse(savedCheckout[hasSlotIso ? 10 : 9]) ?? 0,
        serviceFee: double.tryParse(savedCheckout[hasSlotIso ? 11 : 10]) ?? 0,
        discount: double.tryParse(savedCheckout[hasSlotIso ? 12 : 11]) ?? 0,
        total: double.tryParse(savedCheckout[hasSlotIso ? 13 : 12]) ?? 0,
        paymentOptions: _paymentOptions,
        selectedPaymentOptionId: savedCheckout[hasSlotIso ? 14 : 13],
      );
    }
  }

  static Future<void> saveCurrentUser({
    required String name,
    required String phone,
    required String email,
    String? role,
    String? userId,
  }) async {
    final p = await SharedPreferences.getInstance();
    final nextRole = role ?? p.getString('user_role') ?? _currentUser.role;
    final nextId =
        userId ??
        p.getString('user_id') ??
        'u_${DateTime.now().millisecondsSinceEpoch}';
    _currentUser = UserModel(
      id: nextId,
      name: name,
      phone: phone,
      email: email,
      role: nextRole,
      walletBalance: _currentUser.walletBalance,
      rating: _currentUser.rating,
      totalBookings: _currentUser.totalBookings,
      vehicleCount: _vehicles.length,
    );
    _isGuest = false;
    await p.setString('user_id', _currentUser.id);
    await p.setString('user_name', _currentUser.name);
    await p.setString('user_phone', _currentUser.phone);
    await p.setString('user_email', _currentUser.email);
    await p.setString('user_role', _currentUser.role);
    await p.setDouble('user_wallet', _currentUser.walletBalance);
    await p.setDouble('user_rating', _currentUser.rating);
    await p.setInt('user_bookings', _currentUser.totalBookings);
    await p.setInt('user_vehicle_count', _currentUser.vehicleCount);
    await p.setBool('guest_mode', false);

    final index = _drivers.indexWhere(
      (driver) => driver.email.toLowerCase() == email.toLowerCase(),
    );
    if (index >= 0) {
      _drivers[index] = _drivers[index].copyWith(
        name: name,
        phone: phone,
        email: email,
      );
    }
  }

  static void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  static Future<void> continueAsGuest() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('auth_token');
    await p.remove('refresh_token');
    await p.setString('user_role', 'guest');
    await p.setBool('guest_mode', true);
    _isGuest = true;
    _currentUser = const UserModel(
      id: '',
      name: 'Guest',
      phone: '',
      email: '',
      role: 'guest',
    );
  }

  static void setRemoteWorkshops(List<WorkshopModel> workshops) {
    _remoteWorkshops = List<WorkshopModel>.from(workshops);
  }

  static void setRemoteBookings(List<BookingModel> bookings) {
    _remoteBookings = List<BookingModel>.from(bookings);
  }

  static void setRemoteVehicles(List<VehicleModel> vehicles) {
    _vehicles = List<VehicleModel>.from(vehicles);
    _currentUser = UserModel(
      id: _currentUser.id,
      name: _currentUser.name,
      phone: _currentUser.phone,
      email: _currentUser.email,
      role: _currentUser.role,
      walletBalance: _currentUser.walletBalance,
      rating: _currentUser.rating,
      totalBookings: _currentUser.totalBookings,
      vehicleCount: _vehicles.length,
      activeSubscription: _currentUser.activeSubscription,
    );
    if (_vehicles.isEmpty) {
      _preferredVehicleId = null;
    } else if (!_vehicles.any((vehicle) => vehicle.id == _preferredVehicleId)) {
      _preferredVehicleId = _vehicles.first.id;
    }
  }

  static Future<void> savePreferredVehicleId(String vehicleId) async {
    _preferredVehicleId = vehicleId;
    final p = await SharedPreferences.getInstance();
    await p.setString('preferred_vehicle_id', vehicleId);
  }

  static void setRemoteServices(List<ServiceModel> services) {
    _remoteServices = List<ServiceModel>.from(services);
  }

  static void setRemotePackages(List<PackageModel> packages) {
    _remotePackages = List<PackageModel>.from(packages);
  }

  static void setRemoteAdminDrivers(List<DriverUser> drivers) {
    _remoteDrivers = List<DriverUser>.from(drivers);
  }

  static void setRemoteAdminWorkshops(List<WorkshopUser> workshops) {
    _remoteAdminWorkshops = List<WorkshopUser>.from(workshops);
  }

  static void setRemoteAdminBookings(List<AdminBooking> bookings) {
    _remoteAdminBookings = List<AdminBooking>.from(bookings);
  }

  static void setRemoteManagedServices(List<ManagedService> services) {
    _remoteManagedServices = List<ManagedService>.from(services);
  }

  static void setRemoteManagedPackages(List<ManagedPackage> packages) {
    _remoteManagedPackages = List<ManagedPackage>.from(packages);
  }

  static void setRemoteActivityLogs(List<ActivityLogEntry> logs) {
    _remoteActivityLogs = List<ActivityLogEntry>.from(logs);
  }

  static void setRemoteNotifications(List<NotificationModel> items) {
    _remoteNotifications = List<NotificationModel>.from(items);
  }

  static void setRemoteAdminSettings(AdminSettingsData settings) {
    _remoteAdminSettings = settings;
  }

  static void setRemoteAdminAnalytics(AdminAnalyticsData analytics) {
    _remoteAdminAnalytics = analytics;
  }

  static void setRemoteDiagnostics(List<DiagnosticReport> reports) {
    _remoteDiagnosticHistory = List<DiagnosticReport>.from(reports);
    if (reports.isNotEmpty) {
      _remoteLatestDiagnosticReport = reports.first;
    }
  }

  static void setLatestDiagnosticReport(DiagnosticReport report) {
    _remoteLatestDiagnosticReport = report;
    final next = [...?_remoteDiagnosticHistory];
    next.removeWhere((item) => item.id == report.id);
    _remoteDiagnosticHistory = [report, ...next];
  }

  static void setRemoteWorkshopPortal({
    required WorkshopProfileData profile,
    required List<WsBookingData> bookings,
    List<WsServiceItem>? services,
  }) {
    _remoteWorkshopProfile = profile;
    _remoteWorkshopBookings = List<WsBookingData>.from(bookings);
    if (services != null) {
      _remoteWorkshopServices = List<WsServiceItem>.from(services);
    }
  }

  static void setRemoteWorkshopServices(List<WsServiceItem> services) {
    _remoteWorkshopServices = List<WsServiceItem>.from(services);
  }

  static Future<void> saveVehicle({
    required String make,
    required String model,
    required String year,
    required String plate,
  }) async {
    final p = await SharedPreferences.getInstance();
    final vehicle = VehicleModel(
      id: 'v_user',
      make: make,
      model: model,
      year: year,
      plate: plate,
      color: 'Custom',
      health: 100,
      mileage: 0,
    );
    _vehicles = [vehicle, ..._vehicles.where((v) => v.id != vehicle.id)];
    await p.setStringList('user_vehicle', [
      vehicle.make,
      vehicle.model,
      vehicle.year,
      vehicle.plate,
      vehicle.color,
      '${vehicle.mileage}',
      '${vehicle.health}',
    ]);
  }

  static Future<void> saveBookingCheckout(BookingCheckoutData data) async {
    _bookingCheckout = data;
    final p = await SharedPreferences.getInstance();
    await p.setStringList('booking_checkout', [
      data.serviceId,
      data.serviceName,
      data.workshopId,
      data.workshopName,
      data.vehicleId,
      data.vehicleLabel,
      data.date,
      data.time,
      data.slotIso,
      '${data.durationMins}',
      '${data.subtotal}',
      '${data.serviceFee}',
      '${data.discount}',
      '${data.total}',
      data.selectedPaymentOptionId,
    ]);
  }

  static Future<void> saveBookingPaymentMethod(String paymentOptionId) async {
    final next = bookingCheckout.copyWith(
      selectedPaymentOptionId: paymentOptionId,
    );
    await saveBookingCheckout(next);
  }

  static Future<void> saveRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_role', role);
  }

  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_role');
  }

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  static Future<void> setOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
  }

  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('onboarding_done') ?? false;
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('auth_token');
    await p.remove('user_role');
    await p.remove('guest_mode');
    _isGuest = false;
    _remoteWorkshops = null;
    _remoteBookings = null;
    _remoteServices = null;
    _remotePackages = null;
    _remoteDrivers = null;
    _remoteAdminWorkshops = null;
    _remoteAdminBookings = null;
    _remoteManagedServices = null;
    _remoteManagedPackages = null;
    _remoteActivityLogs = null;
    _remoteNotifications = null;
    _remoteAdminSettings = null;
    _remoteAdminAnalytics = null;
    _remoteLatestDiagnosticReport = null;
    _remoteDiagnosticHistory = null;
    _remoteWorkshopBookings = null;
    _remoteWorkshopServices = null;
    _remoteWorkshopProfile = null;
  }

  static DriverUser? driverById(String id) {
    for (final driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  static WorkshopUser? workshopById(String id) {
    for (final workshop in adminWorkshops) {
      if (workshop.id == id) return workshop;
    }
    return null;
  }

  static AdminBooking? bookingById(String id) {
    for (final booking in adminBookings) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  static void _addLog({
    required String actor,
    required String action,
    required String target,
    required String details,
  }) {
    _activityLogs = [
      ActivityLogEntry(
        id: 'log_${DateTime.now().microsecondsSinceEpoch}',
        timestamp: DateTime.now(),
        actor: actor,
        action: action,
        target: target,
        details: details,
      ),
      ..._activityLogs,
    ];
  }

  static void approveDriver(String id) {
    _drivers = _drivers
        .map(
          (driver) => driver.id == id
              ? driver.copyWith(status: AdminAccountStatus.active)
              : driver,
        )
        .toList();
    final driver = driverById(id);
    if (driver != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Approved driver',
        target: driver.name,
        details: 'Driver registration approved.',
      );
    }
  }

  static void rejectDriver(String id) {
    _drivers = _drivers
        .map(
          (driver) => driver.id == id
              ? driver.copyWith(status: AdminAccountStatus.rejected)
              : driver,
        )
        .toList();
    final driver = driverById(id);
    if (driver != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Rejected driver',
        target: driver.name,
        details: 'Driver registration rejected.',
      );
    }
  }

  static void suspendDriver(String id) {
    _drivers = _drivers
        .map(
          (driver) => driver.id == id
              ? driver.copyWith(status: AdminAccountStatus.suspended)
              : driver,
        )
        .toList();
    final driver = driverById(id);
    if (driver != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Suspended driver',
        target: driver.name,
        details: 'Driver account suspended.',
      );
    }
  }

  static void activateDriver(String id) {
    _drivers = _drivers
        .map(
          (driver) => driver.id == id
              ? driver.copyWith(status: AdminAccountStatus.active)
              : driver,
        )
        .toList();
    final driver = driverById(id);
    if (driver != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Activated driver',
        target: driver.name,
        details: 'Driver account reactivated.',
      );
    }
  }

  static void deleteDriver(String id) {
    final driver = driverById(id);
    _drivers = _drivers.where((item) => item.id != id).toList();
    if (driver != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Deleted driver',
        target: driver.name,
        details: 'Driver account removed from admin records.',
      );
    }
  }

  static void approveWorkshop(String id) {
    _adminWorkshops = _adminWorkshops
        .map(
          (workshop) => workshop.id == id
              ? workshop.copyWith(status: AdminAccountStatus.active)
              : workshop,
        )
        .toList();
    final workshop = workshopById(id);
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Approved workshop',
        target: workshop.name,
        details: 'Workshop registration approved.',
      );
    }
  }

  static void rejectWorkshop(String id) {
    _adminWorkshops = _adminWorkshops
        .map(
          (workshop) => workshop.id == id
              ? workshop.copyWith(status: AdminAccountStatus.rejected)
              : workshop,
        )
        .toList();
    final workshop = workshopById(id);
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Rejected workshop',
        target: workshop.name,
        details: 'Workshop registration rejected.',
      );
    }
  }

  static void suspendWorkshop(String id) {
    _adminWorkshops = _adminWorkshops
        .map(
          (workshop) => workshop.id == id
              ? workshop.copyWith(status: AdminAccountStatus.suspended)
              : workshop,
        )
        .toList();
    final workshop = workshopById(id);
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Suspended workshop',
        target: workshop.name,
        details: 'Workshop account suspended.',
      );
    }
  }

  static void activateWorkshop(String id) {
    _adminWorkshops = _adminWorkshops
        .map(
          (workshop) => workshop.id == id
              ? workshop.copyWith(status: AdminAccountStatus.active)
              : workshop,
        )
        .toList();
    final workshop = workshopById(id);
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Activated workshop',
        target: workshop.name,
        details: 'Workshop account activated.',
      );
    }
  }

  static void verifyWorkshop(String id) {
    _adminWorkshops = _adminWorkshops
        .map(
          (workshop) => workshop.id == id
              ? workshop.copyWith(isVerified: true)
              : workshop,
        )
        .toList();
    final workshop = workshopById(id);
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Verified workshop',
        target: workshop.name,
        details: 'Workshop marked as verified.',
      );
    }
  }

  static void deleteWorkshop(String id) {
    final workshop = workshopById(id);
    _adminWorkshops = _adminWorkshops.where((item) => item.id != id).toList();
    if (workshop != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Deleted workshop',
        target: workshop.name,
        details: 'Workshop account removed from admin records.',
      );
    }
  }

  static void updateBookingStatus(String id, AdminBookingStatus status) {
    _adminBookings = _adminBookings
        .map(
          (booking) =>
              booking.id == id ? booking.copyWith(status: status) : booking,
        )
        .toList();
    final booking = bookingById(id);
    if (booking != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Booking updated',
        target: booking.id,
        details: 'Booking status changed to ${status.label}.',
      );
    }
  }

  static void addService(ManagedService service) {
    _managedServices = [..._managedServices, service];
    _addLog(
      actor: 'Super Admin',
      action: 'Service added',
      target: service.name,
      details: 'New service added at EGP ${service.price.toStringAsFixed(0)}.',
    );
  }

  static void updateService(ManagedService service) {
    _managedServices = _managedServices
        .map((item) => item.id == service.id ? service : item)
        .toList();
    _addLog(
      actor: 'Super Admin',
      action: 'Service updated',
      target: service.name,
      details: 'Service configuration updated.',
    );
  }

  static void toggleService(String id) {
    ManagedService? updated;
    _managedServices = _managedServices.map((item) {
      if (item.id != id) return item;
      updated = item.copyWith(isEnabled: !item.isEnabled);
      return updated!;
    }).toList();
    if (updated != null) {
      _addLog(
        actor: 'Super Admin',
        action: updated!.isEnabled ? 'Service enabled' : 'Service disabled',
        target: updated!.name,
        details: 'Visibility updated for the service catalog.',
      );
    }
  }

  static void deleteService(String id) {
    final service = _managedServices.where((item) => item.id == id).firstOrNull;
    _managedServices = _managedServices.where((item) => item.id != id).toList();
    if (service != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Service deleted',
        target: service.name,
        details: 'Service removed from the catalog.',
      );
    }
  }

  static void addPackage(ManagedPackage pkg) {
    _managedPackages = [..._managedPackages, pkg];
    _addLog(
      actor: 'Super Admin',
      action: 'Package added',
      target: pkg.name,
      details: 'Subscription package created.',
    );
  }

  static void updatePackage(ManagedPackage pkg) {
    _managedPackages = _managedPackages
        .map((item) => item.id == pkg.id ? pkg : item)
        .toList();
    _addLog(
      actor: 'Super Admin',
      action: 'Package updated',
      target: pkg.name,
      details: 'Package details updated.',
    );
  }

  static void togglePackage(String id) {
    ManagedPackage? updated;
    _managedPackages = _managedPackages.map((item) {
      if (item.id != id) return item;
      updated = item.copyWith(isEnabled: !item.isEnabled);
      return updated!;
    }).toList();
    if (updated != null) {
      _addLog(
        actor: 'Super Admin',
        action: updated!.isEnabled ? 'Package enabled' : 'Package disabled',
        target: updated!.name,
        details: 'Subscription visibility updated.',
      );
    }
  }

  static void deletePackage(String id) {
    final pkg = _managedPackages.where((item) => item.id == id).firstOrNull;
    _managedPackages = _managedPackages.where((item) => item.id != id).toList();
    if (pkg != null) {
      _addLog(
        actor: 'Super Admin',
        action: 'Package deleted',
        target: pkg.name,
        details: 'Subscription package removed.',
      );
    }
  }

  static void updateAdminSettings(AdminSettingsData data) {
    _adminSettings = data;
    _addLog(
      actor: 'Super Admin',
      action: 'Settings updated',
      target: 'Platform settings',
      details: 'Admin settings and announcements were updated.',
    );
  }

  static String _currentMonthLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  static Future<void> changeAdminPassword(String password) async {
    final p = await SharedPreferences.getInstance();
    _adminPassword = password;
    await p.setString('admin_password_override', password);
    _addLog(
      actor: 'Super Admin',
      action: 'Admin password changed',
      target: 'Super Admin',
      details: 'Private admin credentials were updated locally.',
    );
  }

  static List<NotificationModel> get notifications {
    if (_remoteNotifications != null) {
      return List.unmodifiable(_remoteNotifications!);
    }
    return const [];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

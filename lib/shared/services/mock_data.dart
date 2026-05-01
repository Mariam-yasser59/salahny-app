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
  final double monthlyRevenue;
  final String revenuePeriod;
  final String payoutMethod;

  const WorkshopProfileData({
    required this.id,
    required this.name,
    required this.initials,
    required this.specialty,
    required this.rating,
    required this.isOpen,
    required this.isVerified,
    required this.monthlyRevenue,
    required this.revenuePeriod,
    required this.payoutMethod,
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

class MockAppDataSource implements AppDataSource {
  const MockAppDataSource();

  @override
  UserModel get currentUser => MockData.currentUser;

  @override
  List<VehicleModel> get vehicles => MockData.vehicles;

  @override
  List<ServiceModel> get services => MockData.services;

  @override
  List<WorkshopModel> get workshops => MockData.workshops;

  @override
  List<BookingModel> get bookings => MockData.bookings;

  @override
  BookingCheckoutData get bookingCheckout => MockData.bookingCheckout;

  @override
  List<PackageModel> get packages => MockData.packages;

  @override
  List<NotificationModel> get notifications => MockData.notifications;

  @override
  DiagnosticReport get latestDiagnosticReport => MockData.latestDiagnosticReport;

  @override
  List<DiagnosticReport> get diagnosticHistory => MockData.diagnosticHistory;

  @override
  DiagnosticModel get diagnosticSummary => MockData.diagnosticSummary;

  @override
  List<WsBookingData> get workshopBookings => MockData.workshopBookings;

  @override
  List<WsServiceItem> get workshopServices => MockData.workshopServices;

  @override
  List<WsPayoutData> get workshopPayouts => MockData.workshopPayouts;

  @override
  WorkshopProfileData get workshopProfile => MockData.workshopProfile;
}

class AppData {
  AppData._();

  static AppDataSource _source = const MockAppDataSource();

  static AppDataSource get i => _source;

  static void useSource(AppDataSource source) {
    _source = source;
  }
}

class MockData {
  MockData._();

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

  static UserModel _currentUser = UserModel.mock;
  static List<VehicleModel> _vehicles = List.of(VehicleModel.mockList);
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
  static DiagnosticReport? _remoteLatestDiagnosticReport;
  static List<DiagnosticReport>? _remoteDiagnosticHistory;
  static List<WsBookingData>? _remoteWorkshopBookings;
  static List<WsServiceItem>? _remoteWorkshopServices;
  static WorkshopProfileData? _remoteWorkshopProfile;

  static List<DriverUser> _drivers = [
    DriverUser(
      id: 'd1',
      name: 'James Carter',
      email: 'james@example.com',
      phone: '01011112222',
      status: AdminAccountStatus.active,
      totalBookings: 14,
      walletBalance: 245,
      joinedAt: DateTime.now().subtract(const Duration(days: 82)),
    ),
    DriverUser(
      id: 'd2',
      name: 'Sara Ahmed',
      email: 'sara.ahmed@example.com',
      phone: '01022223333',
      status: AdminAccountStatus.pending,
      totalBookings: 0,
      walletBalance: 0,
      joinedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DriverUser(
      id: 'd3',
      name: 'Omar Khalil',
      email: 'omar.k@example.com',
      phone: '01033334444',
      status: AdminAccountStatus.suspended,
      totalBookings: 6,
      walletBalance: 85,
      joinedAt: DateTime.now().subtract(const Duration(days: 44)),
    ),
    DriverUser(
      id: 'd4',
      name: 'Lena Hoffman',
      email: 'lena.h@example.com',
      phone: '01044445555',
      status: AdminAccountStatus.active,
      totalBookings: 9,
      walletBalance: 122,
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];

  static List<WorkshopUser> _adminWorkshops = [
    WorkshopUser(
      id: 'w1',
      name: 'ProTech Auto Center',
      email: 'owner@protech.com',
      phone: '01050001111',
      address: '142 Maple Ave, Downtown',
      specialty: 'Full Service',
      rating: 4.9,
      totalJobs: 1820,
      revenue: 8450,
      isVerified: true,
      status: AdminAccountStatus.active,
      joinedAt: DateTime.now().subtract(const Duration(days: 130)),
    ),
    WorkshopUser(
      id: 'w2',
      name: 'Speed Kings Garage',
      email: 'hello@speedkings.com',
      phone: '01050002222',
      address: '78 Oak Street, Midtown',
      specialty: 'Performance & Tuning',
      rating: 4.7,
      totalJobs: 940,
      revenue: 6320,
      isVerified: true,
      status: AdminAccountStatus.active,
      joinedAt: DateTime.now().subtract(const Duration(days: 98)),
    ),
    WorkshopUser(
      id: 'w3',
      name: 'QuickFix Motors',
      email: 'admin@quickfix.com',
      phone: '01050003333',
      address: '33 Pine Rd, West District',
      specialty: 'Diagnostics & Electrical',
      rating: 4.6,
      totalJobs: 650,
      revenue: 4180,
      isVerified: false,
      status: AdminAccountStatus.pending,
      joinedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static List<ManagedService> _managedServices = ServiceModel.mockList
      .map(
        (s) => ManagedService(
          id: s.id,
          name: s.name,
          category: s.category,
          description: s.description,
          emoji: s.emoji,
          price: s.price,
          durationMins: s.durationMins,
          isPopular: s.isPopular,
          isEnabled: true,
        ),
      )
      .toList();

  static List<ManagedPackage> _managedPackages = PackageModel.mockList
      .map(
        (p) => ManagedPackage(
          id: p.id,
          name: p.name,
          tagline: p.tagline,
          duration: p.duration,
          price: p.price,
          originalPrice: p.originalPrice,
          features: List<String>.from(p.features),
          isPopular: p.isPopular,
          isEnabled: true,
        ),
      )
      .toList();

  static List<AdminBooking> _adminBookings = [
    AdminBooking(
      id: 'bk1',
      driverId: 'd1',
      driverName: 'James Carter',
      workshopId: 'w1',
      workshopName: 'ProTech Auto Center',
      serviceId: 's1',
      serviceName: 'Oil Change',
      status: AdminBookingStatus.active,
      date: appShortDate(1),
      time: '10:00 AM',
      total: 89,
      paymentMethod: 'Credit / Debit Card',
    ),
    AdminBooking(
      id: 'bk2',
      driverId: 'd4',
      driverName: 'Lena Hoffman',
      workshopId: 'w2',
      workshopName: 'Speed Kings Garage',
      serviceId: 's6',
      serviceName: 'Brake Service',
      status: AdminBookingStatus.pending,
      date: appShortDate(2),
      time: '01:30 PM',
      total: 199,
      paymentMethod: 'Cash on Service',
    ),
    AdminBooking(
      id: 'bk3',
      driverId: 'd1',
      driverName: 'James Carter',
      workshopId: 'w2',
      workshopName: 'Speed Kings Garage',
      serviceId: 's8',
      serviceName: 'Battery Check',
      status: AdminBookingStatus.completed,
      date: appShortDate(-4),
      time: '09:00 AM',
      total: 39,
      paymentMethod: 'Apple Pay',
    ),
  ];

  static List<ActivityLogEntry> _activityLogs = [
    ActivityLogEntry(
      id: 'l1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      actor: 'Super Admin',
      action: 'Approved workshop',
      target: 'QuickFix Motors',
      details: 'Workshop application moved from pending to active review.',
    ),
    ActivityLogEntry(
      id: 'l2',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      actor: 'System',
      action: 'Booking created',
      target: 'bk1',
      details: 'James Carter created a new Oil Change booking.',
    ),
    ActivityLogEntry(
      id: 'l3',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      actor: 'Super Admin',
      action: 'Service price changed',
      target: 'Brake Service',
      details: 'Price updated from \$189 to \$199.',
    ),
    ActivityLogEntry(
      id: 'l4',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      actor: 'Super Admin',
      action: 'Driver suspended',
      target: 'Omar Khalil',
      details: 'Driver account suspended pending support review.',
    ),
  ];

  static AdminSettingsData _adminSettings = const AdminSettingsData(
    privacyPolicy: 'Salahny keeps booking, workshop, and payment metadata secure and visible only to authorized roles.',
    aboutContent: 'Salahny connects drivers with trusted workshops and supervises the whole service flow as a managed platform.',
    announcementTitle: 'Weekend maintenance push',
    announcementBody: 'Promote AC and brake services across all active workshops.',
    notificationsEnabled: true,
  );

  static UserModel get currentUser => _currentUser;
  static List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
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
  static AdminSettingsData get adminSettings => _adminSettings;

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
    final active = _adminWorkshops
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
    return _adminBookings.map((booking) => booking.toBookingModel()).toList(
          growable: false,
        );
  }

  static WorkshopProfileData get workshopProfile {
    if (_remoteWorkshopProfile != null) {
      return _remoteWorkshopProfile!;
    }
    final workshop = _adminWorkshops.firstWhere(
      (item) => item.status == AdminAccountStatus.active,
      orElse: () => _adminWorkshops.first,
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
      monthlyRevenue: workshop.revenue,
      revenuePeriod: 'April 2026',
      payoutMethod: 'Bank Transfer',
    );
  }

  static List<WsBookingData> get workshopBookings =>
      List.unmodifiable(_remoteWorkshopBookings ?? WsMock.bookings);

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
    return WsMock.services;
  }

  static List<WsPayoutData> get workshopPayouts {
    final bookings = workshopBookings
        .where((item) => item.status != RequestStatus.cancelled)
        .toList();
    if (bookings.isEmpty) {
      return WsMock.payouts;
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
          : DiagnosticReport.mock);

  static List<DiagnosticReport> get diagnosticHistory =>
      List.unmodifiable(_remoteDiagnosticHistory ?? DiagnosticReport.mockHistory);

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
      vitals: {
        for (final vital in report.vitals) vital.key: vital.value,
      },
    );
  }

  static int get totalRevenue => adminBookings.fold<int>(
        0,
        (sum, booking) => sum + booking.total.toInt(),
      );

  static int get pendingApprovalsCount =>
      pendingDrivers.length + pendingWorkshops.length;

  static bool validateAdminCredentials(String email, String password) {
    return email.trim().toLowerCase() == superAdmin.email &&
        password == _adminPassword;
  }

  static BookingCheckoutData _buildDefaultBookingCheckout() {
    final service = services.isEmpty ? ServiceModel.mockList.first : services.first;
    final workshop = workshops.isEmpty ? WorkshopModel.mockList.first : workshops.first;
    final vehicle = _vehicles.isEmpty ? VehicleModel.mockList.first : _vehicles.first;
    const serviceFee = 5.0;
    const discount = 0.0;
    return BookingCheckoutData(
      serviceId: service.id,
      serviceName: service.name,
      workshopId: workshop.id,
      workshopName: workshop.name,
      vehicleId: vehicle.id,
      vehicleLabel: vehicle.fullName,
      date: appShortDate(1),
      time: '10:00 AM',
      durationMins: service.durationMins,
      subtotal: service.price,
      serviceFee: serviceFee,
      discount: discount,
      total: service.price + serviceFee - discount,
      paymentOptions: _paymentOptions,
      selectedPaymentOptionId: _paymentOptions.first.id,
    );
  }

  static Future<void> loadCurrentUser() async {
    final p = await SharedPreferences.getInstance();
    _adminPassword =
        p.getString('admin_password_override') ?? superAdmin.password;
    _currentUser = UserModel(
      id: p.getString('user_id') ?? UserModel.mock.id,
      name: p.getString('user_name') ?? UserModel.mock.name,
      phone: p.getString('user_phone') ?? UserModel.mock.phone,
      email: p.getString('user_email') ?? UserModel.mock.email,
      role: p.getString('user_role') ?? UserModel.mock.role,
      walletBalance: p.getDouble('user_wallet') ?? UserModel.mock.walletBalance,
      rating: p.getDouble('user_rating') ?? UserModel.mock.rating,
      totalBookings: p.getInt('user_bookings') ?? UserModel.mock.totalBookings,
    );
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
          mileage: savedVehicle.length > 5 ? int.tryParse(savedVehicle[5]) ?? 0 : 0,
          health: savedVehicle.length > 6 ? double.tryParse(savedVehicle[6]) ?? 85 : 85,
        ),
        ...VehicleModel.mockList.where((v) => v.id != 'v_user'),
      ];
    }
    final savedCheckout = p.getStringList('booking_checkout');
    if (savedCheckout != null && savedCheckout.length >= 14) {
      _bookingCheckout = BookingCheckoutData(
        serviceId: savedCheckout[0],
        serviceName: savedCheckout[1],
        workshopId: savedCheckout[2],
        workshopName: savedCheckout[3],
        vehicleId: savedCheckout[4],
        vehicleLabel: savedCheckout[5],
        date: savedCheckout[6],
        time: savedCheckout[7],
        durationMins: int.tryParse(savedCheckout[8]) ?? 0,
        subtotal: double.tryParse(savedCheckout[9]) ?? 0,
        serviceFee: double.tryParse(savedCheckout[10]) ?? 0,
        discount: double.tryParse(savedCheckout[11]) ?? 0,
        total: double.tryParse(savedCheckout[12]) ?? 0,
        paymentOptions: _paymentOptions,
        selectedPaymentOptionId: savedCheckout[13],
      );
    }
  }

  static Future<void> saveCurrentUser({
    required String name,
    required String phone,
    required String email,
    String? role,
  }) async {
    final p = await SharedPreferences.getInstance();
    final nextRole = role ?? p.getString('user_role') ?? _currentUser.role;
    _currentUser = UserModel(
      id: p.getString('user_id') ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      email: email,
      role: nextRole,
      walletBalance: _currentUser.walletBalance,
      rating: _currentUser.rating,
      totalBookings: _currentUser.totalBookings,
    );
    await p.setString('user_id', _currentUser.id);
    await p.setString('user_name', _currentUser.name);
    await p.setString('user_phone', _currentUser.phone);
    await p.setString('user_email', _currentUser.email);
    await p.setString('user_role', _currentUser.role);
    await p.setDouble('user_wallet', _currentUser.walletBalance);
    await p.setDouble('user_rating', _currentUser.rating);
    await p.setInt('user_bookings', _currentUser.totalBookings);

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

  static void setRemoteWorkshops(List<WorkshopModel> workshops) {
    _remoteWorkshops = List<WorkshopModel>.from(workshops);
  }

  static void setRemoteBookings(List<BookingModel> bookings) {
    _remoteBookings = List<BookingModel>.from(bookings);
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
    _vehicles = [
      vehicle,
      ..._vehicles.where((v) => v.id != vehicle.id),
    ];
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
          (booking) => booking.id == id
              ? booking.copyWith(status: status)
              : booking,
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
      details: 'New service added at \$${service.price.toStringAsFixed(0)}.',
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
    final booking = bookings.isEmpty ? BookingModel.mockList.first : bookings.first;
    final vehicle = _vehicles.isEmpty ? null : _vehicles.first;
    return [
      NotificationModel(
        id: 'n1',
        title: 'Booking Confirmed',
        body:
            '${booking.workshopName} confirmed your ${booking.serviceName} for ${booking.date}',
        type: 'booking',
        time: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      NotificationModel(
        id: 'n2',
        title: 'Service Reminder',
        body:
            '${vehicle?.fullName ?? 'Your vehicle'} is due for its next inspection soon',
        type: 'reminder',
        time: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      NotificationModel(
        id: 'n3',
        title: _adminSettings.announcementTitle,
        body: _adminSettings.announcementBody,
        type: 'promo',
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationModel(
        id: 'n4',
        title: 'Job Completed',
        body:
            '${vehicle?.fullName ?? 'Your vehicle'} is ready for pickup at ${booking.workshopName}',
        type: 'booking',
        time: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

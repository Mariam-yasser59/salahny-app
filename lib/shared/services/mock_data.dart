import 'package:shared_preferences/shared_preferences.dart';
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
  List<ServiceModel> get services => ServiceModel.mockList;

  @override
  List<WorkshopModel> get workshops => WorkshopModel.mockList;

  @override
  List<BookingModel> get bookings => BookingModel.mockList;

  @override
  BookingCheckoutData get bookingCheckout => MockData.bookingCheckout;

  @override
  List<PackageModel> get packages => PackageModel.mockList;

  @override
  List<NotificationModel> get notifications => MockData.notifications;

  @override
  DiagnosticReport get latestDiagnosticReport => DiagnosticReport.mock;

  @override
  List<DiagnosticReport> get diagnosticHistory => DiagnosticReport.mockHistory;

  @override
  DiagnosticModel get diagnosticSummary => DiagnosticModel.mock;

  @override
  List<WsBookingData> get workshopBookings => WsMock.bookings;

  @override
  List<WsServiceItem> get workshopServices => WsMock.services;

  @override
  List<WsPayoutData> get workshopPayouts => WsMock.payouts;

  @override
  WorkshopProfileData get workshopProfile => const WorkshopProfileData(
    id: 'w1',
    name: 'ProTech Auto Center',
    initials: 'PA',
    specialty: 'Multi-Service Workshop',
    rating: 4.9,
    isOpen: true,
    isVerified: true,
    monthlyRevenue: 8450,
    revenuePeriod: 'December 2024',
    payoutMethod: 'Bank Transfer',
  );
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

  static UserModel _currentUser = UserModel.mock;
  static List<VehicleModel> _vehicles = List.of(VehicleModel.mockList);
  static BookingCheckoutData? _bookingCheckout;
  static const List<PaymentOptionData> _paymentOptions = [
    PaymentOptionData(id: 'card', icon: '💳', label: 'Credit / Debit Card'),
    PaymentOptionData(id: 'wallet', icon: '📱', label: 'Apple Pay'),
    PaymentOptionData(id: 'cash', icon: '💵', label: 'Cash on Service'),
  ];

  static UserModel get currentUser => _currentUser;
  static List<VehicleModel> get vehicles => List.unmodifiable(_vehicles);
  static BookingCheckoutData get bookingCheckout =>
      _bookingCheckout ?? _buildDefaultBookingCheckout();

  static BookingCheckoutData _buildDefaultBookingCheckout() {
    final service = ServiceModel.mockList.first;
    final workshop = WorkshopModel.mockList.first;
    final vehicle = _vehicles.isEmpty ? VehicleModel.mockList.first : _vehicles.first;
    final subtotal = service.price;
    final serviceFee = 5.0;
    final discount = 0.0;
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
      subtotal: subtotal,
      serviceFee: serviceFee,
      discount: discount,
      total: subtotal + serviceFee - discount,
      paymentOptions: _paymentOptions,
      selectedPaymentOptionId: _paymentOptions.first.id,
    );
  }

  static Future<void> loadCurrentUser() async {
    final p = await SharedPreferences.getInstance();
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
  }

  static List<NotificationModel> get notifications {
    final booking = BookingModel.mockList.first;
    final vehicle = _vehicles.isEmpty ? null : _vehicles.first;
    return [
      NotificationModel(id:'n1', title:'Booking Confirmed', body:'${booking.workshopName} confirmed your ${booking.serviceName} for ${booking.date}', type:'booking', time: DateTime.now().subtract(const Duration(hours: 1))),
      NotificationModel(id:'n2', title:'Service Reminder', body:'${vehicle?.fullName ?? 'Your vehicle'} is due for its next inspection soon', type:'reminder', time: DateTime.now().subtract(const Duration(hours: 4))),
      NotificationModel(id:'n3', title:'Special Offer', body:'Get 30% off all AC services this week!', type:'promo', time: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
      NotificationModel(id:'n4', title:'Job Completed', body:'${vehicle?.fullName ?? 'Your vehicle'} is ready for pickup at ${booking.workshopName}', type:'booking', time: DateTime.now().subtract(const Duration(days: 2)), isRead: true),
    ];
  }
}

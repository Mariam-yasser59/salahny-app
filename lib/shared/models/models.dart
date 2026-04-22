// lib/shared/models/models.dart

enum RiskLevel { healthy, warning, critical }

extension RiskLevelX on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.healthy:
        return 'Healthy';
      case RiskLevel.warning:
        return 'Warning';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  String toUpperCase() => label.toUpperCase();
}

enum RequestStatus {
  pending,
  accepted,
  inProgress,
  diagnosticsReady,
  repairInProgress,
  completed,
  cancelled;

  static String label(RequestStatus s) {
    switch (s) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.diagnosticsReady:
        return 'Diagnostics Ready';
      case RequestStatus.repairInProgress:
        return 'Repair In Progress';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final double walletBalance;
  final double rating;
  final int totalBookings;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.role = 'driver',
    this.walletBalance = 0,
    this.rating = 0,
    this.totalBookings = 0,
  });

  static const mock = UserModel(
    id: 'u1',
    name: 'James Carter',
    phone: '+1 (555) 234-5678',
    email: 'james@example.com',
    walletBalance: 245,
    rating: 4.8,
    totalBookings: 14,
  );
}

class VehicleModel {
  final String id;
  final String make;
  final String model;
  final String year;
  final String plate;
  final String color;
  final String fuel;
  final double health;
  final int mileage;

  const VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    this.fuel = 'Gasoline',
    this.health = 85,
    this.mileage = 0,
  });

  String get fullName => '$make $model $year';

  static const List<VehicleModel> mockList = [
    VehicleModel(
      id: 'v1',
      make: 'Toyota',
      model: 'Camry',
      year: '2022',
      plate: '7XYZ 421',
      color: 'Pearl White',
      health: 83,
      mileage: 42000,
    ),
    VehicleModel(
      id: 'v2',
      make: 'Ford',
      model: 'F-150',
      year: '2020',
      plate: '9ABC 832',
      color: 'Midnight Black',
      health: 65,
      mileage: 78000,
    ),
  ];
}

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String emoji;
  final double price;
  final int durationMins;
  final bool isPopular;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.emoji,
    required this.price,
    this.durationMins = 60,
    this.isPopular = false,
  });

  static const List<ServiceModel> mockList = [
    ServiceModel(
      id: 's1',
      name: 'Oil Change',
      category: 'Maintenance',
      description: 'Full synthetic oil change with filter replacement',
      emoji: '🔧',
      price: 89,
      durationMins: 45,
      isPopular: true,
    ),
    ServiceModel(
      id: 's2',
      name: 'Tire Rotation',
      category: 'Tires',
      description: 'Rotate and balance all four tires',
      emoji: '🔄',
      price: 59,
      durationMins: 60,
    ),
    ServiceModel(
      id: 's3',
      name: 'Air Filter',
      category: 'Maintenance',
      description: 'Engine air filter replacement',
      emoji: '💨',
      price: 45,
      durationMins: 30,
      isPopular: true,
    ),
    ServiceModel(
      id: 's4',
      name: 'Full Inspection',
      category: 'Inspection',
      description: 'Comprehensive 150-point vehicle inspection',
      emoji: '🔍',
      price: 149,
      durationMins: 90,
    ),
    ServiceModel(
      id: 's5',
      name: 'Car Wash & Detail',
      category: 'Cleaning',
      description: 'Premium exterior & interior detailing',
      emoji: '✨',
      price: 99,
      durationMins: 120,
    ),
    ServiceModel(
      id: 's6',
      name: 'Brake Service',
      category: 'Brakes',
      description: 'Brake pad inspection and replacement',
      emoji: '🛑',
      price: 199,
      durationMins: 90,
      isPopular: true,
    ),
    ServiceModel(
      id: 's7',
      name: 'AC Service',
      category: 'HVAC',
      description: 'AC system check, recharge, and repair',
      emoji: '❄️',
      price: 129,
      durationMins: 75,
    ),
    ServiceModel(
      id: 's8',
      name: 'Battery Check',
      category: 'Electrical',
      description: 'Battery test and terminal cleaning',
      emoji: '🔋',
      price: 39,
      durationMins: 30,
    ),
  ];
}

class WorkshopModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String specialty;
  final double rating;
  final double distance;
  final int reviews;
  final int jobsDone;
  final bool isOpen;
  final bool isVerified;

  const WorkshopModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.specialty,
    required this.rating,
    required this.distance,
    this.reviews = 0,
    this.jobsDone = 0,
    this.isOpen = true,
    this.isVerified = false,
  });

  static const List<WorkshopModel> mockList = [
    WorkshopModel(
      id: 'w1',
      name: 'ProTech Auto Center',
      address: '142 Maple Ave, Downtown',
      phone: '+1 555 010 1234',
      specialty: 'Full Service',
      rating: 4.9,
      distance: 0.8,
      reviews: 312,
      jobsDone: 1820,
      isOpen: true,
      isVerified: true,
    ),
    WorkshopModel(
      id: 'w2',
      name: 'Speed Kings Garage',
      address: '78 Oak Street, Midtown',
      phone: '+1 555 020 5678',
      specialty: 'Performance & Tuning',
      rating: 4.7,
      distance: 2.1,
      reviews: 198,
      jobsDone: 940,
      isOpen: true,
      isVerified: true,
    ),
    WorkshopModel(
      id: 'w3',
      name: 'QuickFix Motors',
      address: '33 Pine Rd, West District',
      phone: '+1 555 030 9991',
      specialty: 'Diagnostics & Electrical',
      rating: 4.6,
      distance: 3.4,
      reviews: 144,
      jobsDone: 650,
      isOpen: false,
      isVerified: false,
    ),
  ];
}

class OBDVital {
  final String key;
  final double value;
  final String unit;

  const OBDVital({
    required this.key,
    required this.value,
    required this.unit,
  });
}

class OBDFaultCode {
  final String code;
  final String description;
  final RiskLevel level;

  const OBDFaultCode({
    required this.code,
    required this.description,
    required this.level,
  });

  RiskLevel get severity => level;
}

class AIPrediction {
  final String issue;
  final double confidence;
  final RiskLevel urgency;
  final String recommendation;
  final String technicalNote;
  final String estimatedRepair;

  const AIPrediction({
    required this.issue,
    required this.confidence,
    required this.urgency,
    required this.recommendation,
    required this.technicalNote,
    required this.estimatedRepair,
  });

  String get repairCategory => estimatedRepair;
  String get recommendedFix => recommendation;
}

class DiagnosticReport {
  final String id;
  final String vehicleId;
  final String date;
  final String summary;
  final RiskLevel riskLevel;
  final double health;
  final List<OBDFaultCode> faultCodes;
  final List<OBDVital> vitals;
  final List<String> recommendations;
  final AIPrediction? aiPrediction;

  const DiagnosticReport({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.summary,
    required this.riskLevel,
    required this.health,
    required this.faultCodes,
    required this.vitals,
    required this.recommendations,
    this.aiPrediction,
  });

  static const DiagnosticReport mock = DiagnosticReport(
    id: 'd1',
    vehicleId: 'v1',
    date: 'Apr 22, 2026',
    summary: 'Cooling system and fuel mixture anomaly detected',
    riskLevel: RiskLevel.critical,
    health: 61,
    faultCodes: [
      OBDFaultCode(
        code: 'P0420',
        description: 'Catalyst system efficiency below threshold',
        level: RiskLevel.warning,
      ),
      OBDFaultCode(
        code: 'P0171',
        description: 'System too lean (Bank 1)',
        level: RiskLevel.critical,
      ),
    ],
    vitals: [
      OBDVital(key: 'RPM', value: 3200, unit: 'rpm'),
      OBDVital(key: 'Coolant Temp', value: 110, unit: '°C'),
      OBDVital(key: 'MAP', value: 75, unit: 'kPa'),
      OBDVital(key: 'MAF', value: 14.2, unit: 'g/s'),
      OBDVital(key: 'Battery', value: 12.4, unit: 'V'),
    ],
    recommendations: [
      'Inspect radiator, coolant level, and thermostat.',
      'Check fuel delivery and vacuum leaks.',
      'Avoid long-distance driving until repair is completed.',
    ],
    aiPrediction: AIPrediction(
      issue: 'Cooling System / Fuel Mixture Anomaly',
      confidence: 0.94,
      urgency: RiskLevel.critical,
      recommendation:
      'Inspect radiator flow, coolant level, and intake/fuel mixture immediately.',
      technicalNote:
      'High coolant temperature with elevated RPM and lean fuel code pattern indicate possible cooling restriction and air-fuel imbalance.',
      estimatedRepair: 'Cooling inspection + fuel system diagnosis',
    ),
  );

  static const List<DiagnosticReport> mockHistory = [
    mock,
    DiagnosticReport(
      id: 'd2',
      vehicleId: 'v1',
      date: 'Apr 18, 2026',
      summary: 'Vehicle operating normally',
      riskLevel: RiskLevel.healthy,
      health: 96,
      faultCodes: [],
      vitals: [
        OBDVital(key: 'RPM', value: 1800, unit: 'rpm'),
        OBDVital(key: 'Coolant Temp', value: 91, unit: '°C'),
      ],
      recommendations: [
        'Continue routine maintenance schedule.',
        'Repeat OBD scan in 2 weeks.',
      ],
      aiPrediction: AIPrediction(
        issue: 'Normal Operating State',
        confidence: 0.88,
        urgency: RiskLevel.healthy,
        recommendation: 'No urgent action needed. Continue routine maintenance.',
        technicalNote:
        'All key OBD values are within acceptable operating range.',
        estimatedRepair: 'No repair required',
      ),
    ),
    DiagnosticReport(
      id: 'd3',
      vehicleId: 'v2',
      date: 'Apr 12, 2026',
      summary: 'Battery and charging weakness detected',
      riskLevel: RiskLevel.warning,
      health: 74,
      faultCodes: [
        OBDFaultCode(
          code: 'P0562',
          description: 'System voltage low',
          level: RiskLevel.warning,
        ),
      ],
      vitals: [
        OBDVital(key: 'Battery', value: 11.8, unit: 'V'),
        OBDVital(key: 'RPM', value: 2500, unit: 'rpm'),
      ],
      recommendations: [
        'Test battery and alternator.',
        'Inspect battery terminals for corrosion.',
      ],
      aiPrediction: AIPrediction(
        issue: 'Battery / Charging Weakness',
        confidence: 0.79,
        urgency: RiskLevel.warning,
        recommendation: 'Inspect battery charge state and alternator output.',
        technicalNote:
        'Voltage trend suggests weak charging performance under moderate engine load.',
        estimatedRepair: 'Battery & alternator test',
      ),
    ),
  ];
}

class DiagnosticModel {
  final String id;
  final String vehicleId;
  final String date;
  final String summary;
  final double health;
  final List<String> codes;
  final List<String> recommendations;
  final Map<String, double> vitals;

  const DiagnosticModel({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.summary,
    required this.health,
    required this.codes,
    required this.recommendations,
    required this.vitals,
  });

  static const DiagnosticModel mock = DiagnosticModel(
    id: 'd1',
    vehicleId: 'v1',
    date: 'Apr 22, 2026',
    summary: 'Good overall condition with minor issues',
    health: 83,
    codes: [
      'P0420 — Catalyst Efficiency Below Threshold',
      'P0171 — System Too Lean (Bank 1)',
    ],
    recommendations: [
      'Schedule exhaust inspection',
      'Replace air filter within 1,000 miles',
      'Check O2 sensors',
    ],
    vitals: {
      'Engine Temp': 87,
      'Oil Pressure': 78,
      'Battery': 92,
      'Tire Pressure': 68,
    },
  );
}

class BookingModel {
  final String id;
  final String serviceName;
  final String workshopName;
  final String status;
  final String date;
  final String time;
  final double price;

  const BookingModel({
    required this.id,
    required this.serviceName,
    required this.workshopName,
    required this.status,
    required this.date,
    required this.time,
    required this.price,
  });

  static const List<BookingModel> mockList = [
    BookingModel(
      id: 'bk1',
      serviceName: 'Oil Change',
      workshopName: 'ProTech Auto Center',
      status: 'In Progress',
      date: 'Apr 24',
      time: '10:00 AM',
      price: 89,
    ),
    BookingModel(
      id: 'bk2',
      serviceName: 'Brake Service',
      workshopName: 'QuickFix Motors',
      status: 'Pending',
      date: 'Apr 25',
      time: '01:30 PM',
      price: 199,
    ),
    BookingModel(
      id: 'bk3',
      serviceName: 'Battery Check',
      workshopName: 'Speed Kings Garage',
      status: 'Completed',
      date: 'Apr 19',
      time: '09:00 AM',
      price: 39,
    ),
  ];
}

class PackageModel {
  final String id;
  final String name;
  final String tagline;
  final String duration;
  final double price;
  final double originalPrice;
  final List<String> features;
  final bool isPopular;

  const PackageModel({
    required this.id,
    required this.name,
    required this.tagline,
    required this.duration,
    required this.price,
    required this.originalPrice,
    required this.features,
    this.isPopular = false,
  });

  static const List<PackageModel> mockList = [
    PackageModel(
      id: 'p1',
      name: 'Basic',
      tagline: 'Perfect for 1 vehicle',
      duration: 'month',
      price: 29,
      originalPrice: 49,
      features: [
        'Monthly checkup',
        '10% service discount',
        'WhatsApp support',
        '2 emergency calls',
      ],
    ),
    PackageModel(
      id: 'p2',
      name: 'Premium',
      tagline: 'Best for families',
      duration: '3 months',
      price: 79,
      originalPrice: 129,
      features: [
        'Weekly checkup',
        '25% discount',
        '24/7 priority support',
        '5 emergency calls',
        'Free monthly wash',
        'Full diagnostic report',
      ],
      isPopular: true,
    ),
    PackageModel(
      id: 'p3',
      name: 'Fleet',
      tagline: 'For businesses & fleets',
      duration: 'year',
      price: 599,
      originalPrice: 899,
      features: [
        'Daily monitoring',
        '40% discount',
        'Dedicated manager',
        'Unlimited emergency',
        'Self-service bay',
        'Custom reports',
        'API integration',
      ],
    ),
  ];
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime time;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final String senderId;
  final DateTime time;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.time,
    this.isMe = false,
  });
}

class WsBookingData {
  final String id;
  final String serviceName;
  final String customerName;
  final String customerPhone;
  final String vehicleInfo;
  final String date;
  final String time;
  final RequestStatus status;
  final double price;
  final double progress;
  final String? attachedDiagnosticId;

  const WsBookingData({
    required this.id,
    required this.serviceName,
    required this.customerName,
    required this.customerPhone,
    required this.vehicleInfo,
    required this.date,
    required this.time,
    required this.status,
    required this.price,
    this.progress = 0.0,
    this.attachedDiagnosticId,
  });
}

class WsServiceItem {
  final String emoji;
  final String name;
  final int durationMins;
  final double price;

  const WsServiceItem({
    required this.emoji,
    required this.name,
    required this.durationMins,
    required this.price,
  });
}

class WsPayoutData {
  final String period;
  final double amount;

  const WsPayoutData({
    required this.period,
    required this.amount,
  });
}

class WsMock {
  WsMock._();

  static const List<WsBookingData> bookings = [
    WsBookingData(
      id: 'b001',
      serviceName: 'Oil Change',
      customerName: 'James Carter',
      customerPhone: '+1 (555) 234-5678',
      vehicleInfo: 'Toyota Camry 2022',
      date: 'Dec 22',
      time: '10:00 AM',
      price: 85,
      status: RequestStatus.pending,
    ),
    WsBookingData(
      id: 'b002',
      serviceName: 'Brake Check',
      customerName: 'Sara Ahmed',
      customerPhone: '+20 101 987 6543',
      vehicleInfo: 'Hyundai Elantra 2021',
      date: 'Dec 22',
      time: '12:30 PM',
      price: 120,
      status: RequestStatus.accepted,
      progress: 0.15,
    ),
    WsBookingData(
      id: 'b003',
      serviceName: 'Engine Diagnostics',
      customerName: 'Michael Torres',
      customerPhone: '+1 (555) 876-5432',
      vehicleInfo: 'BMW X3 2020',
      date: 'Dec 22',
      time: '09:00 AM',
      price: 200,
      status: RequestStatus.inProgress,
      progress: 0.60,
    ),
    WsBookingData(
      id: 'b004',
      serviceName: 'Tire Rotation',
      customerName: 'Lena Hoffman',
      customerPhone: '+49 170 123 4567',
      vehicleInfo: 'Nissan Sunny 2023',
      date: 'Dec 22',
      time: '11:00 AM',
      price: 65,
      status: RequestStatus.repairInProgress,
      progress: 0.35,
    ),
    WsBookingData(
      id: 'b005',
      serviceName: 'Battery Service',
      customerName: 'Omar Khalil',
      customerPhone: '+20 100 555 4321',
      vehicleInfo: 'Kia Sportage 2022',
      date: 'Dec 21',
      time: '02:15 PM',
      price: 95,
      status: RequestStatus.completed,
      progress: 1.0,
    ),
  ];

  static const List<WsServiceItem> services = [
    WsServiceItem(emoji: '🛢️', name: 'Oil Change', durationMins: 30, price: 85),
    WsServiceItem(emoji: '🔧', name: 'Engine Diagnostics', durationMins: 60, price: 200),
    WsServiceItem(emoji: '🛞', name: 'Tire Rotation', durationMins: 45, price: 65),
    WsServiceItem(emoji: '🔋', name: 'Battery Service', durationMins: 20, price: 95),
    WsServiceItem(emoji: '🚿', name: 'Full Wash & Detail', durationMins: 90, price: 150),
    WsServiceItem(emoji: '❄️', name: 'AC Service', durationMins: 60, price: 180),
  ];

  static const List<WsPayoutData> payouts = [
    WsPayoutData(period: 'Dec 15 – Dec 21', amount: 2450),
    WsPayoutData(period: 'Dec 08 – Dec 14', amount: 1980),
    WsPayoutData(period: 'Dec 01 – Dec 07', amount: 2150),
  ];
}
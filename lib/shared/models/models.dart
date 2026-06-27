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

String appShortDate([int daysFromToday = 0]) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final date = DateTime.now().add(Duration(days: daysFromToday));
  return '${months[date.month - 1]} ${date.day}';
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
  final int vehicleCount;
  final ActiveSubscription? activeSubscription;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.role = 'driver',
    this.walletBalance = 0,
    this.rating = 0,
    this.totalBookings = 0,
    this.vehicleCount = 0,
    this.activeSubscription,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    double? walletBalance,
    double? rating,
    int? totalBookings,
    int? vehicleCount,
    ActiveSubscription? activeSubscription,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    role: role ?? this.role,
    walletBalance: walletBalance ?? this.walletBalance,
    rating: rating ?? this.rating,
    totalBookings: totalBookings ?? this.totalBookings,
    vehicleCount: vehicleCount ?? this.vehicleCount,
    activeSubscription: activeSubscription ?? this.activeSubscription,
  );

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

class ActiveSubscription {
  final String packageName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int remainingDays;

  const ActiveSubscription({
    required this.packageName,
    required this.startsAt,
    required this.endsAt,
    required this.remainingDays,
  });
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
  final List<DateTime> availableSlots;
  final double? latitude;
  final double? longitude;
  final List<String> serviceNames;

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
    this.availableSlots = const [],
    this.latitude,
    this.longitude,
    this.serviceNames = const [],
  });
}

class OBDVital {
  final String key;
  final double value;
  final String unit;

  const OBDVital({required this.key, required this.value, required this.unit});
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
  final bool hasFault;
  final String issue;
  final String detectedIssue;
  final String predictedIssue;
  final String predictionHorizon;
  final String predictionReason;
  final double confidence;
  final RiskLevel urgency;
  final String explanation;
  final String recommendation;
  final String technicalNote;
  final String estimatedRepair;
  final String modelSource;

  const AIPrediction({
    required this.hasFault,
    required this.issue,
    this.detectedIssue = '',
    this.predictedIssue = '',
    this.predictionHorizon = '',
    this.predictionReason = '',
    required this.confidence,
    required this.urgency,
    required this.explanation,
    required this.recommendation,
    required this.technicalNote,
    required this.estimatedRepair,
    required this.modelSource,
  });

  String get repairCategory => estimatedRepair;
  String get recommendedFix => recommendation;
  String get detectionLabel => detectedIssue.isNotEmpty ? detectedIssue : issue;
  String get predictionLabel =>
      predictedIssue.isNotEmpty ? predictedIssue : issue;
}

class DiagnosticReport {
  final String id;
  final String vehicleId;
  final String? workshopId;
  final String? bookingId;
  final String date;
  final String summary;
  final RiskLevel riskLevel;
  final double health;
  final List<OBDFaultCode> faultCodes;
  final List<OBDVital> vitals;
  final List<String> recommendations;
  final AIPrediction? aiPrediction;
  final DateTime? sentToDriverAt;
  final DateTime? repairTaskCreatedAt;

  const DiagnosticReport({
    required this.id,
    required this.vehicleId,
    this.workshopId,
    this.bookingId,
    required this.date,
    required this.summary,
    required this.riskLevel,
    required this.health,
    required this.faultCodes,
    required this.vitals,
    required this.recommendations,
    this.aiPrediction,
    this.sentToDriverAt,
    this.repairTaskCreatedAt,
  });
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
}

class BookingModel {
  final String id;
  final String serviceName;
  final String workshopName;
  final String status;
  final String date;
  final String time;
  final String slotIso;
  final double price;
  final bool driverReviewed;
  final bool workshopReviewed;
  final double? driverRating;
  final double? workshopRating;

  const BookingModel({
    required this.id,
    required this.serviceName,
    required this.workshopName,
    required this.status,
    required this.date,
    required this.time,
    required this.slotIso,
    required this.price,
    this.driverReviewed = false,
    this.workshopReviewed = false,
    this.driverRating,
    this.workshopRating,
  });

  static const placeholder = BookingModel(
    id: '',
    serviceName: 'No booking',
    workshopName: '',
    status: 'Pending',
    date: '',
    time: '',
    slotIso: '',
    price: 0,
    driverReviewed: false,
    workshopReviewed: false,
  );
}

class PaymentOptionData {
  final String id;
  final String icon;
  final String label;

  const PaymentOptionData({
    required this.id,
    required this.icon,
    required this.label,
  });
}

class BookingCheckoutData {
  final String serviceId;
  final String serviceName;
  final String workshopId;
  final String workshopName;
  final String vehicleId;
  final String vehicleLabel;
  final String date;
  final String time;
  final String slotIso;
  final int durationMins;
  final double subtotal;
  final double serviceFee;
  final double discount;
  final double total;
  final List<PaymentOptionData> paymentOptions;
  final String selectedPaymentOptionId;

  const BookingCheckoutData({
    required this.serviceId,
    required this.serviceName,
    required this.workshopId,
    required this.workshopName,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.date,
    required this.time,
    required this.slotIso,
    required this.durationMins,
    required this.subtotal,
    required this.serviceFee,
    required this.discount,
    required this.total,
    required this.paymentOptions,
    required this.selectedPaymentOptionId,
  });

  BookingCheckoutData copyWith({
    String? serviceId,
    String? serviceName,
    String? workshopId,
    String? workshopName,
    String? vehicleId,
    String? vehicleLabel,
    String? date,
    String? time,
    String? slotIso,
    int? durationMins,
    double? subtotal,
    double? serviceFee,
    double? discount,
    double? total,
    List<PaymentOptionData>? paymentOptions,
    String? selectedPaymentOptionId,
  }) {
    return BookingCheckoutData(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      date: date ?? this.date,
      time: time ?? this.time,
      slotIso: slotIso ?? this.slotIso,
      durationMins: durationMins ?? this.durationMins,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paymentOptions: paymentOptions ?? this.paymentOptions,
      selectedPaymentOptionId:
          selectedPaymentOptionId ?? this.selectedPaymentOptionId,
    );
  }
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
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime time;
  final bool isRead;
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
    this.data = const {},
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
  final bool driverReviewed;
  final bool workshopReviewed;
  final double? driverRating;
  final double? workshopRating;

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
    this.driverReviewed = false,
    this.workshopReviewed = false,
    this.driverRating,
    this.workshopRating,
  });
}

class WsServiceItem {
  final String id;
  final String emoji;
  final String name;
  final int durationMins;
  final double price;

  const WsServiceItem({
    this.id = '',
    required this.emoji,
    required this.name,
    required this.durationMins,
    required this.price,
  });
}

class WsPayoutData {
  final String period;
  final double amount;

  const WsPayoutData({required this.period, required this.amount});
}

class EmergencyRequestModel {
  final String id;
  final String emergencyType;
  final String issueDescription;
  final String address;
  final double? latitude;
  final double? longitude;
  final String locationNotes;
  final String status;
  final String? assignedWorkshopName;
  final String? assignedWorkshopPhone;
  final double? distanceKm;
  final DateTime createdAt;

  const EmergencyRequestModel({
    required this.id,
    required this.emergencyType,
    required this.issueDescription,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.locationNotes,
    required this.status,
    required this.assignedWorkshopName,
    required this.assignedWorkshopPhone,
    required this.distanceKm,
    required this.createdAt,
  });
}

class WorkshopEarningItem {
  final String id;
  final String bookingId;
  final String driverName;
  final String serviceName;
  final double amount;
  final String status;
  final DateTime createdAt;

  const WorkshopEarningItem({
    required this.id,
    required this.bookingId,
    required this.driverName,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}

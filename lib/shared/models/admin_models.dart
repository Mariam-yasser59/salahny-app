import 'models.dart';

enum AdminAccountStatus { pending, active, suspended, rejected, deleted }

extension AdminAccountStatusX on AdminAccountStatus {
  String get label {
    switch (this) {
      case AdminAccountStatus.pending:
        return 'Pending';
      case AdminAccountStatus.active:
        return 'Active';
      case AdminAccountStatus.suspended:
        return 'Suspended';
      case AdminAccountStatus.rejected:
        return 'Rejected';
      case AdminAccountStatus.deleted:
        return 'Deleted';
    }
  }
}

enum AdminBookingStatus { pending, active, completed, cancelled }

extension AdminBookingStatusX on AdminBookingStatus {
  String get label {
    switch (this) {
      case AdminBookingStatus.pending:
        return 'Pending';
      case AdminBookingStatus.active:
        return 'Active';
      case AdminBookingStatus.completed:
        return 'Completed';
      case AdminBookingStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String password;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
}

class DriverUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final AdminAccountStatus status;
  final int totalBookings;
  final double walletBalance;
  final DateTime joinedAt;

  const DriverUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.status,
    required this.totalBookings,
    required this.walletBalance,
    required this.joinedAt,
  });

  DriverUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    AdminAccountStatus? status,
    int? totalBookings,
    double? walletBalance,
    DateTime? joinedAt,
  }) {
    return DriverUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      totalBookings: totalBookings ?? this.totalBookings,
      walletBalance: walletBalance ?? this.walletBalance,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class WorkshopUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String specialty;
  final double rating;
  final int totalJobs;
  final double revenue;
  final bool isVerified;
  final AdminAccountStatus status;
  final DateTime joinedAt;
  final double? latitude;
  final double? longitude;

  const WorkshopUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.specialty,
    required this.rating,
    required this.totalJobs,
    required this.revenue,
    required this.isVerified,
    required this.status,
    required this.joinedAt,
    this.latitude,
    this.longitude,
  });

  bool get isApproved =>
      status == AdminAccountStatus.active ||
      status == AdminAccountStatus.suspended;

  WorkshopModel toWorkshopModel({double distance = 1.2}) {
    return WorkshopModel(
      id: id,
      name: name,
      address: address,
      phone: phone,
      specialty: specialty,
      rating: rating,
      distance: distance,
      reviews: totalJobs > 0 ? totalJobs ~/ 4 : 0,
      jobsDone: totalJobs,
      isOpen: status == AdminAccountStatus.active,
      isVerified: isVerified,
      latitude: latitude,
      longitude: longitude,
      serviceNames: specialty.trim().isEmpty ? const [] : [specialty],
    );
  }

  WorkshopUser copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? specialty,
    double? rating,
    int? totalJobs,
    double? revenue,
    bool? isVerified,
    AdminAccountStatus? status,
    DateTime? joinedAt,
    double? latitude,
    double? longitude,
  }) {
    return WorkshopUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      totalJobs: totalJobs ?? this.totalJobs,
      revenue: revenue ?? this.revenue,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class ManagedService {
  final String id;
  final String name;
  final String category;
  final String description;
  final String emoji;
  final double price;
  final int durationMins;
  final bool isPopular;
  final bool isEnabled;

  const ManagedService({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.emoji,
    required this.price,
    required this.durationMins,
    this.isPopular = false,
    this.isEnabled = true,
  });

  ServiceModel toServiceModel() {
    return ServiceModel(
      id: id,
      name: name,
      category: category,
      description: description,
      emoji: emoji,
      price: price,
      durationMins: durationMins,
      isPopular: isPopular,
    );
  }

  ManagedService copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? emoji,
    double? price,
    int? durationMins,
    bool? isPopular,
    bool? isEnabled,
  }) {
    return ManagedService(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      price: price ?? this.price,
      durationMins: durationMins ?? this.durationMins,
      isPopular: isPopular ?? this.isPopular,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class ManagedPackage {
  final String id;
  final String name;
  final String tagline;
  final String duration;
  final double price;
  final double originalPrice;
  final List<String> features;
  final bool isPopular;
  final bool isEnabled;

  const ManagedPackage({
    required this.id,
    required this.name,
    required this.tagline,
    required this.duration,
    required this.price,
    required this.originalPrice,
    required this.features,
    this.isPopular = false,
    this.isEnabled = true,
  });

  PackageModel toPackageModel() {
    return PackageModel(
      id: id,
      name: name,
      tagline: tagline,
      duration: duration,
      price: price,
      originalPrice: originalPrice,
      features: features,
      isPopular: isPopular,
    );
  }

  ManagedPackage copyWith({
    String? id,
    String? name,
    String? tagline,
    String? duration,
    double? price,
    double? originalPrice,
    List<String>? features,
    bool? isPopular,
    bool? isEnabled,
  }) {
    return ManagedPackage(
      id: id ?? this.id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      features: features ?? this.features,
      isPopular: isPopular ?? this.isPopular,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class AdminBooking {
  final String id;
  final String driverId;
  final String driverName;
  final String workshopId;
  final String workshopName;
  final String serviceId;
  final String serviceName;
  final AdminBookingStatus status;
  final String date;
  final String time;
  final double total;
  final String paymentMethod;

  const AdminBooking({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.workshopId,
    required this.workshopName,
    required this.serviceId,
    required this.serviceName,
    required this.status,
    required this.date,
    required this.time,
    required this.total,
    required this.paymentMethod,
  });

  BookingModel toBookingModel() {
    return BookingModel(
      id: id,
      serviceName: serviceName,
      workshopName: workshopName,
      status: status.label,
      date: date,
      time: time,
      slotIso: '',
      price: total,
    );
  }

  AdminBooking copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? workshopId,
    String? workshopName,
    String? serviceId,
    String? serviceName,
    AdminBookingStatus? status,
    String? date,
    String? time,
    double? total,
    String? paymentMethod,
  }) {
    return AdminBooking(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      workshopId: workshopId ?? this.workshopId,
      workshopName: workshopName ?? this.workshopName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      status: status ?? this.status,
      date: date ?? this.date,
      time: time ?? this.time,
      total: total ?? this.total,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class ActivityLogEntry {
  final String id;
  final DateTime timestamp;
  final String actor;
  final String action;
  final String target;
  final String details;

  const ActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.actor,
    required this.action,
    required this.target,
    required this.details,
  });
}

class AdminSettingsData {
  final String privacyPolicy;
  final String aboutContent;
  final String announcementTitle;
  final String announcementBody;
  final bool notificationsEnabled;

  const AdminSettingsData({
    required this.privacyPolicy,
    required this.aboutContent,
    required this.announcementTitle,
    required this.announcementBody,
    required this.notificationsEnabled,
  });

  AdminSettingsData copyWith({
    String? privacyPolicy,
    String? aboutContent,
    String? announcementTitle,
    String? announcementBody,
    bool? notificationsEnabled,
  }) {
    return AdminSettingsData(
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      aboutContent: aboutContent ?? this.aboutContent,
      announcementTitle: announcementTitle ?? this.announcementTitle,
      announcementBody: announcementBody ?? this.announcementBody,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class AdminAnalyticsData {
  final Map<String, int> bookingsByStatus;
  final int activeSubscribers;
  final int pendingDocuments;
  final List<MonthlyRevenuePoint> revenueByMonth;
  final List<TopWorkshopPoint> topWorkshops;

  const AdminAnalyticsData({
    required this.bookingsByStatus,
    required this.activeSubscribers,
    required this.pendingDocuments,
    required this.revenueByMonth,
    required this.topWorkshops,
  });

  static const empty = AdminAnalyticsData(
    bookingsByStatus: {},
    activeSubscribers: 0,
    pendingDocuments: 0,
    revenueByMonth: [],
    topWorkshops: [],
  );
}

class MonthlyRevenuePoint {
  final int year;
  final int month;
  final double total;

  const MonthlyRevenuePoint({
    required this.year,
    required this.month,
    required this.total,
  });
}

class TopWorkshopPoint {
  final String name;
  final int bookings;
  final double revenue;

  const TopWorkshopPoint({
    required this.name,
    required this.bookings,
    required this.revenue,
  });
}

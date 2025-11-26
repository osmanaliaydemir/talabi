class Courier {
  final int id;
  final String userId;
  final String name;
  final String? phoneNumber;
  final String? vehicleType;
  final bool isActive;
  final String status;
  final int maxActiveOrders;
  final int currentActiveOrders;
  final double? currentLatitude;
  final double? currentLongitude;
  final DateTime? lastLocationUpdate;
  final double totalEarnings;
  final double currentDayEarnings;
  final int totalDeliveries;
  final double averageRating;
  final String? workingHoursStart;
  final String? workingHoursEnd;
  final bool isWithinWorkingHours;

  Courier({
    required this.id,
    required this.userId,
    required this.name,
    this.phoneNumber,
    this.vehicleType,
    required this.isActive,
    required this.status,
    required this.maxActiveOrders,
    required this.currentActiveOrders,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdate,
    required this.totalEarnings,
    required this.currentDayEarnings,
    required this.totalDeliveries,
    required this.averageRating,
    this.workingHoursStart,
    this.workingHoursEnd,
    required this.isWithinWorkingHours,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    return Courier(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      vehicleType: json['vehicleType'],
      isActive: json['isActive'],
      status: json['status'],
      maxActiveOrders: json['maxActiveOrders'],
      currentActiveOrders: json['currentActiveOrders'],
      currentLatitude: json['currentLatitude']?.toDouble(),
      currentLongitude: json['currentLongitude']?.toDouble(),
      lastLocationUpdate: json['lastLocationUpdate'] != null
          ? DateTime.parse(json['lastLocationUpdate'])
          : null,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      currentDayEarnings: (json['currentDayEarnings'] ?? 0).toDouble(),
      totalDeliveries: json['totalDeliveries'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      workingHoursStart: json['workingHoursStart'],
      workingHoursEnd: json['workingHoursEnd'],
      isWithinWorkingHours: json['isWithinWorkingHours'] ?? true,
    );
  }
}

class CourierStatistics {
  final int totalDeliveries;
  final int todayDeliveries;
  final int weekDeliveries;
  final int monthDeliveries;
  final double totalEarnings;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final double averageRating;
  final int totalRatings;
  final int activeOrders;

  CourierStatistics({
    required this.totalDeliveries,
    required this.todayDeliveries,
    required this.weekDeliveries,
    required this.monthDeliveries,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.averageRating,
    required this.totalRatings,
    required this.activeOrders,
  });

  factory CourierStatistics.fromJson(Map<String, dynamic> json) {
    return CourierStatistics(
      totalDeliveries: json['totalDeliveries'],
      todayDeliveries: json['todayDeliveries'],
      weekDeliveries: json['weekDeliveries'],
      monthDeliveries: json['monthDeliveries'],
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      todayEarnings: (json['todayEarnings'] ?? 0).toDouble(),
      weekEarnings: (json['weekEarnings'] ?? 0).toDouble(),
      monthEarnings: (json['monthEarnings'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'],
      activeOrders: json['activeOrders'],
    );
  }
}

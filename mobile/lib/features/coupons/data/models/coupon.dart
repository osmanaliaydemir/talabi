import 'package:flutter/material.dart';

enum DiscountType { percentage, fixed }

class Coupon {
  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minCartAmount,
    required this.expirationDate,
    required this.description,
    this.title,
    this.vendorType,
    this.vendorId,
    this.startTime,
    this.endTime,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: DiscountType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            (json['discountType'] ?? json['type']),
        orElse: () => DiscountType.percentage,
      ),
      discountValue: (json['discountValue'] ?? json['value'] as num).toDouble(),
      minCartAmount: (json['minCartAmount'] ?? json['min_amount'] as num)
          .toDouble(),
      expirationDate: DateTime.parse(
        json['expirationDate'] ?? json['expiration_date'] as String,
      ),
      description: json['description'] as String,
      title: json['title'] as String?,
      vendorType: json['vendorType'] as int?,
      vendorId: json['vendorId'] as String?,
      startTime: _parseTime(json['startTime'] as String?),
      endTime: _parseTime(json['endTime'] as String?),
    );
  }
  final String id;
  final String code;
  final DiscountType discountType;
  final double discountValue;
  final double minCartAmount;
  final DateTime expirationDate;
  final String description;
  final String? title;
  final int? vendorType;
  final String? vendorId;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  bool get isValid {
    return DateTime.now().isBefore(expirationDate);
  }

  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }
}

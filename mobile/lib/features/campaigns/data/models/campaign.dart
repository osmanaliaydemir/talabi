import 'package:flutter/material.dart';
import 'package:mobile/features/coupons/data/models/coupon.dart';

class Campaign {
  Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    this.actionUrl,
    required this.priority,
    this.vendorType,
    this.minCartAmount,
    this.startTime,
    this.endTime,
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      actionUrl: json['actionUrl'] as String?,
      priority: json['priority'] as int? ?? 0,
      vendorType: json['vendorType'] as int?,
      minCartAmount: (json['minCartAmount'] as num?)?.toDouble(),
      startTime: _parseTime(json['startTime'] as String?),
      endTime: _parseTime(json['endTime'] as String?),
      discountType: json['discountType'] != null
          ? DiscountType.values.firstWhere(
              (e) => e.toString().split('.').last == json['discountType'],
              orElse: () => DiscountType.percentage,
            )
          : DiscountType.percentage,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final String? actionUrl;
  final int priority;
  final int? vendorType;
  final double? minCartAmount;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final DiscountType discountType;
  final double discountValue;

  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

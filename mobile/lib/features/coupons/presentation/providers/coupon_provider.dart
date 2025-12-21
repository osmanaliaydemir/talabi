import 'package:flutter/material.dart';
import 'package:mobile/features/coupons/data/models/coupon.dart';
import 'package:mobile/features/coupons/services/coupon_service.dart';

class CouponProvider with ChangeNotifier {
  final CouponService _couponService = CouponService();

  List<Coupon> _coupons = [];
  bool _isLoading = false;
  String? _error;

  List<Coupon> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _coupons = await _couponService.getAvailableCoupons();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Coupon?> validateCoupon(String code) async {
    // This is optional if we only want to validate through CartProvider,
    // but useful if we want to pre-validate in the list.
    return await _couponService.validateCoupon(code);
  }
}

import 'package:get_it/get_it.dart';
import 'package:mobile/features/coupons/data/models/coupon.dart';
import 'package:mobile/services/api_service.dart';

class CouponService {
  final ApiService _apiService = GetIt.instance<ApiService>();

  Future<Coupon?> validateCoupon(String code) async {
    try {
      // Get user's default address for validation context
      String? cityId;
      String? districtId;

      try {
        final addresses = await _apiService.getAddresses();
        if (addresses.isNotEmpty) {
          final defaultAddr =
              addresses.firstWhere(
                    (a) => a['isDefault'] == true,
                    orElse: () => addresses.first,
                  )
                  as Map<String, dynamic>;

          if (defaultAddr['cityId'] != null) {
            cityId = defaultAddr['cityId'].toString();
          }
          // Map 'districtId' if available.
          // Note: Backend expects Guids. Mobile usually stores Ids as string.
          // Check Address model or Map structure. assuming 'cityId' and 'districtId' keys.
          if (defaultAddr['districtId'] != null) {
            districtId = defaultAddr['districtId'].toString();
          }

          // Fallback: If map has 'city' name but not ID?
          // The API usually returns IDs.
        }
      } catch (e) {
        // Ignore address fetch error, proceed with null location (backend validates only if location rule exists)
      }

      return await _apiService.validateCoupon(
        code,
        cityId: cityId,
        districtId: districtId,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Coupon>> getAvailableCoupons() async {
    try {
      return await _apiService.getCoupons();
    } catch (e) {
      return [];
    }
  }
}

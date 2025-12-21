import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/features/profile/data/models/courier.dart';
import 'package:mobile/features/orders/data/models/courier_order.dart';
import 'package:mobile/features/wallet/data/models/courier_earning.dart';
import 'package:mobile/features/notifications/data/models/courier_notification.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/core/constants/api_constants.dart';

class CourierService {
  final Dio _dio = ApiService().dio;

  Future<Courier> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierProfile);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => Courier.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Kurye profili getirilemedi');
        }

        return apiResponse.data!;
      }
      return Courier.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching courier profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateStatus(String status) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.courierStatus,
        data: {'status': status},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Durum güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating status', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final response = await _dio.put(
        '/courier/location', // ApiEndpoints.courierLocation is /courier (Base), so we might want /courier/location specifically or just append.
        // Existing ApiEndpoints.courierLocation = '/courier'.
        // Let's use string concatenation or define a specific one if reused often.
        // Or better, add 'courierLocationUpdate' to constants.
        // For now I will leave it hardcoded or use '${ApiEndpoints.courierLocation}/location' if appropriate?
        // ApiEndpoints.courierLocation is base.
        // I will use string literal for now to match exactly unless I add it.
        // Wait, I added many courier endpoints. Did I add location? No.
        // I will use direct string to be safe or add it?
        // Let's stick to what I added. Check 'courierStatus', 'courierProfile'.
        // I'll leave '/courier/location' hardcoded or add it to ApiEndpoints locally?
        // I will just leave it hardcoded for this one or use '${ApiEndpoints.courierLocation}/location' if base is correct.
        // Base is '/courier'. So '/courier/location' is valid.
        // But cleaner to have constant.
        // I will use the string for now to avoid creating more work/potential breaking if base varies.
        // Actually, let's look at getProfile. '/courier/profile'. I defined ApiEndpoints.courierProfile.
        // I'll just keep '/courier/location' as string or add it.
        // Use string.
        data: {'latitude': latitude, 'longitude': longitude},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Konum güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating location', e, stackTrace);
      rethrow;
    }
  }

  Future<CourierStatistics> getStatistics() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierStatistics);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => CourierStatistics.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'İstatistikler getirilemedi');
        }

        return apiResponse.data!;
      }
      return CourierStatistics.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching statistics', e, stackTrace);
      rethrow;
    }
  }

  Future<List<CourierOrder>> getActiveOrders() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierActiveOrders);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Aktif siparişler getirilemedi',
          );
        }

        return apiResponse.data!
            .map((json) => CourierOrder.fromJson(json))
            .toList();
      }
      return (response.data as List)
          .map((json) => CourierOrder.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching active orders', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierOrders}/$orderId/accept',
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş kabul edilemedi');
        }
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService().error('Error accepting order', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierOrders}/$orderId/reject',
        data: {'reason': reason},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş reddedilemedi');
        }
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService().error('Error rejecting order', e, stackTrace);
      rethrow;
    }
  }

  Future<CourierOrder> getOrderDetail(String orderId) async {
    try {
      final response = await _dio.get('${ApiEndpoints.courierOrders}/$orderId');

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => CourierOrder.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Sipariş detayı getirilemedi');
        }

        return apiResponse.data!;
      }
      return CourierOrder.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching order detail', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> pickupOrder(String orderId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierOrders}/$orderId/pickup',
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş teslim alınamadı');
        }
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService().error('Error picking up order', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> deliverOrder(String orderId) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierOrders}/$orderId/deliver',
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş teslim edilemedi');
        }
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService().error('Error delivering order', e, stackTrace);
      rethrow;
    }
  }

  Future<CourierNotificationResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.courierNotifications,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => CourierNotificationResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Bildirimler getirilemedi');
        }

        return apiResponse.data!;
      }
      return CourierNotificationResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching notifications', e, stackTrace);
      rethrow;
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierNotifications}/$id/read',
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Bildirim okundu olarak işaretlenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error marking notification read', e, stackTrace);
      rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierNotifications}/read-all',
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ??
                'Tüm bildirimler okundu olarak işaretlenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error marking all notifications read',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<EarningsSummary> getTodayEarnings() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierEarningsToday);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Bugünkü kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return EarningsSummary.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching today earnings', e, stackTrace);
      rethrow;
    }
  }

  Future<EarningsSummary> getWeeklyEarnings() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierEarningsWeek);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Haftalık kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return EarningsSummary.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching weekly earnings', e, stackTrace);
      rethrow;
    }
  }

  Future<EarningsSummary> getMonthlyEarnings() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierEarningsMonth);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Aylık kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return EarningsSummary.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching monthly earnings', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEarningsHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.courierEarningsHistory,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Kazanç geçmişi getirilemedi');
        }

        return apiResponse.data!;
      }
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching earnings history', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierCheckAvailability);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Müsaitlik durumu kontrol edilemedi',
          );
        }

        return apiResponse.data!;
      }
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error checking availability', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.courierOrdersHistory,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Sipariş geçmişi getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching order history', e, stackTrace);
      rethrow;
    }
  }

  Future<void> submitProof(
    String orderId,
    String? photoUrl,
    String? signatureUrl,
    String? notes,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.courierOrders}/$orderId/proof',
        data: {
          'photoUrl': photoUrl,
          'signatureUrl': signatureUrl,
          'notes': notes,
        },
      );

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Teslimat kanıtı gönderilemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error submitting proof', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.courierProfile, data: data);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Profil güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating profile', e, stackTrace);
      rethrow;
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(ApiEndpoints.upload, data: formData);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('url')) {
        return response.data['url'];
      }

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );
        if (apiResponse.success &&
            apiResponse.data != null &&
            apiResponse.data!['url'] != null) {
          return apiResponse.data!['url'];
        }
      }

      throw Exception('Failed to upload image');
    } catch (e, stackTrace) {
      LoggerService().error('Error uploading image', e, stackTrace);
      rethrow;
    }
  }

  Future<List<VehicleTypeOption>> getVehicleTypes() async {
    try {
      final response = await _dio.get(ApiEndpoints.courierVehicleTypes);

      if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => (json as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Araç tipleri getirilemedi');
        }

        return apiResponse.data!
            .map((e) => VehicleTypeOption.fromJson(e))
            .toList();
      }

      final List<dynamic> data = response.data;
      return data
          .map((e) => VehicleTypeOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vehicle types', e, stackTrace);
      rethrow;
    }
  }
}

class VehicleTypeOption {
  VehicleTypeOption({required this.key, required this.name});

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) {
    return VehicleTypeOption(
      key: json['key'] as String,
      name: json['name'] as String,
    );
  }
  final String key;
  final String name;
}

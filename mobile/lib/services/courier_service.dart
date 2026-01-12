import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/features/profile/data/models/courier.dart';
import 'package:mobile/features/orders/data/models/courier_order.dart';
import 'package:mobile/features/wallet/data/models/courier_earning.dart';
import 'package:mobile/features/notifications/data/models/courier_notification.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/core/constants/courier_api_constants.dart';
import 'package:mobile/core/constants/api_constants.dart';

class CourierService {
  final Dio _dio = ApiService().dio;

  Future<Courier> getProfile() async {
    try {
      final response = await _dio.get(CourierApiEndpoints.profile);

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
        CourierApiEndpoints.status,
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
        CourierApiEndpoints.location,
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
      final response = await _dio.get(CourierApiEndpoints.statistics);

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
      final response = await _dio.get(CourierApiEndpoints.activeOrders);

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
        CourierApiEndpoints.orderAccept(orderId),
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
        CourierApiEndpoints.orderReject(orderId),
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
      final response = await _dio.get(CourierApiEndpoints.order(orderId));

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
        CourierApiEndpoints.orderPickup(orderId),
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
        CourierApiEndpoints.orderDeliver(orderId),
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
        CourierApiEndpoints.notifications,
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
        CourierApiEndpoints.notificationRead(id),
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
        CourierApiEndpoints.notificationsReadAll,
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
      final response = await _dio.get(CourierApiEndpoints.earningsToday);

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
      final response = await _dio.get(CourierApiEndpoints.earningsWeek);

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
      final response = await _dio.get(CourierApiEndpoints.earningsMonth);

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
        CourierApiEndpoints.earningsHistory,
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
      final response = await _dio.get(CourierApiEndpoints.checkAvailability);

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
        CourierApiEndpoints.ordersHistory,
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
        CourierApiEndpoints.orderProof(orderId),
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
      final response = await _dio.put(CourierApiEndpoints.profile, data: data);

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
      final response = await _dio.get(CourierApiEndpoints.vehicleTypes);

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

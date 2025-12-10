import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile/models/api_response.dart';
import 'package:mobile/models/courier.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/models/courier_earning.dart';
import 'package:mobile/models/courier_notification.dart';
import 'package:mobile/services/api_service.dart';

class CourierService {
  final Dio _dio = ApiService().dio;

  Future<Courier> getProfile() async {
    try {
      final response = await _dio.get('/courier/profile');

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
    } catch (e) {
      print('Error fetching courier profile: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String status) async {
    try {
      final response = await _dio.put(
        '/courier/status',
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
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      final response = await _dio.put(
        '/courier/location',
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
    } catch (e) {
      print('Error updating location: $e');
      rethrow;
    }
  }

  Future<CourierStatistics> getStatistics() async {
    try {
      final response = await _dio.get('/courier/statistics');

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
    } catch (e) {
      print('Error fetching statistics: $e');
      rethrow;
    }
  }

  Future<List<CourierOrder>> getActiveOrders() async {
    try {
      final response = await _dio.get('/courier/orders/active');

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
    } catch (e) {
      print('Error fetching active orders: $e');
      rethrow;
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _dio.post('/courier/orders/$orderId/accept');

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
    } catch (e) {
      print('Error accepting order: $e');
      rethrow;
    }
  }

  Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      final response = await _dio.post(
        '/courier/orders/$orderId/reject',
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
    } catch (e) {
      print('Error rejecting order: $e');
      rethrow;
    }
  }

  Future<CourierOrder> getOrderDetail(String orderId) async {
    try {
      final response = await _dio.get('/courier/orders/$orderId');

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
    } catch (e) {
      print('Error fetching order detail: $e');
      rethrow;
    }
  }

  Future<bool> pickupOrder(String orderId) async {
    try {
      final response = await _dio.post('/courier/orders/$orderId/pickup');

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
    } catch (e) {
      print('Error picking up order: $e');
      rethrow;
    }
  }

  Future<bool> deliverOrder(String orderId) async {
    try {
      final response = await _dio.post('/courier/orders/$orderId/deliver');

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
    } catch (e) {
      print('Error delivering order: $e');
      rethrow;
    }
  }

  Future<CourierNotificationResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/courier/notifications',
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
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      final response = await _dio.post('/courier/notifications/$id/read');

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
    } catch (e) {
      print('Error marking notification read: $e');
      rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final response = await _dio.post('/courier/notifications/read-all');

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
    } catch (e) {
      print('Error marking all notifications read: $e');
      rethrow;
    }
  }

  Future<EarningsSummary> getTodayEarnings() async {
    try {
      final response = await _dio.get('/courier/earnings/today');

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
    } catch (e) {
      print('Error fetching today earnings: $e');
      rethrow;
    }
  }

  Future<EarningsSummary> getWeeklyEarnings() async {
    try {
      final response = await _dio.get('/courier/earnings/week');

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
    } catch (e) {
      print('Error fetching weekly earnings: $e');
      rethrow;
    }
  }

  Future<EarningsSummary> getMonthlyEarnings() async {
    try {
      final response = await _dio.get('/courier/earnings/month');

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
    } catch (e) {
      print('Error fetching monthly earnings: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEarningsHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _dio.get(
        '/courier/earnings/history',
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
    } catch (e) {
      print('Error fetching earnings history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkAvailability() async {
    try {
      final response = await _dio.get('/courier/check-availability');

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
    } catch (e) {
      print('Error checking availability: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/courier/orders/history',
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
    } catch (e) {
      print('Error fetching order history: $e');
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
        '/courier/orders/$orderId/proof',
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
    } catch (e) {
      print('Error submitting proof: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/courier/profile', data: data);

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
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post('/upload', data: formData);

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
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<List<VehicleTypeOption>> getVehicleTypes() async {
    try {
      final response = await _dio.get('/courier/vehicle-types');

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
    } catch (e) {
      print('Error fetching vehicle types: $e');
      rethrow;
    }
  }
}

class VehicleTypeOption {
  final String key;
  final String name;

  VehicleTypeOption({required this.key, required this.name});

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) {
    return VehicleTypeOption(
      key: json['key'] as String,
      name: json['name'] as String,
    );
  }
}

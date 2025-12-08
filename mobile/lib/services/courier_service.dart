import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mobile/models/api_response.dart';
import 'package:mobile/models/courier.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/models/courier_earning.dart';
import 'package:mobile/models/courier_notification.dart';
import 'package:mobile/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourierService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Courier> getProfile() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => Courier.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Kurye profili getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt Courier)
      return Courier.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load courier profile',
      );
      throw Exception(error);
    }
  }

  Future<void> updateStatus(String status) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${Constants.apiBaseUrl}/courier/status'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Durum güncellenemedi');
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to update status',
      );
      throw Exception(error);
    }
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${Constants.apiBaseUrl}/courier/location'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'latitude': latitude, 'longitude': longitude}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Konum güncellenemedi');
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to update location',
      );
      throw Exception(error);
    }
  }

  Future<CourierStatistics> getStatistics() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/statistics'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => CourierStatistics.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'İstatistikler getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt CourierStatistics)
      return CourierStatistics.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load statistics',
      );
      throw Exception(error);
    }
  }

  Future<List<CourierOrder>> getActiveOrders() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/active'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
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
      // Eski format (direkt liste)
      final List<dynamic> data = responseData as List;
      return data.map((json) => CourierOrder.fromJson(json)).toList();
    }
    final errorMessage = _extractErrorMessage(
      response.body,
      'Failed to load active orders',
    );
    throw Exception(errorMessage);
  }

  Future<bool> acceptOrder(String orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş kabul edilemedi');
        }
      }
      return true;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to accept order',
      );
      throw Exception(error);
    }
  }

  Future<bool> rejectOrder(String orderId, String reason) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş reddedilemedi');
        }
      }
      return true;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to reject order',
      );
      throw Exception(error);
    }
  }

  Future<CourierOrder> getOrderDetail(String orderId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => CourierOrder.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Sipariş detayı getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt CourierOrder)
      return CourierOrder.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load order detail',
      );
      throw Exception(error);
    }
  }

  Future<bool> pickupOrder(String orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/pickup'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş teslim alınamadı');
        }
      }
      return true;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to pickup order',
      );
      throw Exception(error);
    }
  }

  Future<bool> deliverOrder(String orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/deliver'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş teslim edilemedi');
        }
      }
      return true;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to deliver order',
      );
      throw Exception(error);
    }
  }

  Future<CourierNotificationResponse> getNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '${Constants.apiBaseUrl}/courier/notifications?page=$page&pageSize=$pageSize',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => CourierNotificationResponse.fromJson(
            json as Map<String, dynamic>,
          ),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Bildirimler getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt CourierNotificationResponse)
      return CourierNotificationResponse.fromJson(responseData);
    }

    final error = _extractErrorMessage(
      response.body,
      'Failed to load notifications',
    );
    throw Exception(error);
  }

  Future<void> markNotificationRead(String id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/notifications/$id/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Bildirim okundu olarak işaretlenemedi',
          );
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to mark notification as read',
      );
      throw Exception(error);
    }
  }

  Future<void> markAllNotificationsRead() async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/notifications/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ??
                'Tüm bildirimler okundu olarak işaretlenemedi',
          );
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to mark all notifications as read',
      );
      throw Exception(error);
    }
  }

  Future<EarningsSummary> getTodayEarnings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/earnings/today'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Bugünkü kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt EarningsSummary)
      return EarningsSummary.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load today earnings',
      );
      throw Exception(error);
    }
  }

  Future<EarningsSummary> getWeeklyEarnings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/earnings/week'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Haftalık kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt EarningsSummary)
      return EarningsSummary.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load weekly earnings',
      );
      throw Exception(error);
    }
  }

  Future<EarningsSummary> getMonthlyEarnings() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/earnings/month'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => EarningsSummary.fromJson(json as Map<String, dynamic>),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Aylık kazançlar getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt EarningsSummary)
      return EarningsSummary.fromJson(responseData);
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load monthly earnings',
      );
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> getEarningsHistory({
    int page = 1,
    int pageSize = 50,
  }) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(
        '${Constants.apiBaseUrl}/courier/earnings/history?page=$page&pageSize=$pageSize',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Kazanç geçmişi getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt Map)
      return responseData;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load earnings history',
      );
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> checkAvailability() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/check-availability'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Müsaitlik durumu kontrol edilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt Map)
      return responseData;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to check availability',
      );
      throw Exception(error);
    }
  }

  Future<Map<String, dynamic>> getOrderHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(
        '${Constants.apiBaseUrl}/courier/orders/history?page=$page&pageSize=$pageSize',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Sipariş geçmişi getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt Map)
      return responseData;
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load order history',
      );
      throw Exception(error);
    }
  }

  String _extractErrorMessage(String body, String fallback) {
    if (body.isEmpty) return fallback;
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      // Ignore parse errors and use fallback
    }
    return fallback;
  }

  Future<void> submitProof(
    String orderId,
    String? photoUrl,
    String? signatureUrl,
    String? notes,
  ) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/proof'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'photoUrl': photoUrl,
        'signatureUrl': signatureUrl,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Teslimat kanıtı gönderilemedi',
          );
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to submit proof',
      );
      throw Exception(error);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${Constants.apiBaseUrl}/courier/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Profil güncellenemedi');
        }
      }
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to update profile',
      );
      throw Exception(error);
    }
  }

  Future<String> uploadImage(File file) async {
    final token = await _getToken();
    final uri = Uri.parse('${Constants.apiBaseUrl}/upload');

    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }

  Future<List<VehicleTypeOption>> getVehicleTypes() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${Constants.apiBaseUrl}/courier/vehicle-types'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
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
      // Eski format (direkt liste)
      final List<dynamic> data = responseData;
      return data
          .map((e) => VehicleTypeOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final error = _extractErrorMessage(
        response.body,
        'Failed to load vehicle types',
      );
      throw Exception(error);
    }
  }
}

class VehicleTypeOption {
  final String key; // "Motorcycle", "Car", "Bicycle"
  final String name; // "Motor", "Araba", "Bisiklet"

  VehicleTypeOption({required this.key, required this.name});

  factory VehicleTypeOption.fromJson(Map<String, dynamic> json) {
    return VehicleTypeOption(
      key: json['key'] as String,
      name: json['name'] as String,
    );
  }
}

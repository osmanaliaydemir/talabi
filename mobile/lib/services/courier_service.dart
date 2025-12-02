import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
      return Courier.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load courier profile');
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

    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['message'] ?? 'Failed to update status';
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

    if (response.statusCode != 200) {
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
      return CourierStatistics.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load statistics');
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
      final List<dynamic> data = json.decode(response.body);
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
    return response.statusCode == 200;
  }

  Future<bool> rejectOrder(String orderId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/orders/$orderId/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
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
      return CourierOrder.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load order detail');
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
    return response.statusCode == 200;
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
    return response.statusCode == 200;
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
      return CourierNotificationResponse.fromJson(json.decode(response.body));
    }

    final error = _extractErrorMessage(
      response.body,
      'Failed to load notifications',
    );
    throw Exception(error);
  }

  Future<void> markNotificationRead(int id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${Constants.apiBaseUrl}/courier/notifications/$id/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
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

    if (response.statusCode != 200) {
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
      return EarningsSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load today earnings');
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
      return EarningsSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load weekly earnings');
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
      return EarningsSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load monthly earnings');
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
      return json.decode(response.body);
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
      return json.decode(response.body);
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
      return json.decode(response.body);
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

    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['message'] ?? 'Failed to submit proof';
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

    if (response.statusCode != 200) {
      final error =
          json.decode(response.body)['message'] ?? 'Failed to update profile';
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
      final List<dynamic> data = json.decode(response.body);
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

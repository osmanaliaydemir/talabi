import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/notifications/data/models/customer_notification.dart';

@lazySingleton
class NotificationRemoteDataSource {

  NotificationRemoteDataSource(this._networkClient);
  final NetworkClient _networkClient;

  Future<List<CustomerNotification>> getCustomerNotifications() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.customerNotifications,
      );
      final responseData = response.data;

      // Backend artık ApiResponse<T> formatında döndürüyor
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          responseData,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Müşteri bildirimleri getirilemedi',
          );
        }

        // ApiResponse.data içinde CustomerNotificationResponseDto var
        final data = apiResponse.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items
            .map(
              (json) =>
                  CustomerNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      // Eski format (direkt CustomerNotificationResponseDto veya liste)
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('items')) {
        final items = responseData['items'] as List<dynamic>? ?? [];
        return items
            .map(
              (json) =>
                  CustomerNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (responseData is List) {
        return responseData
            .map(
              (json) =>
                  CustomerNotification.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching customer notifications',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.notificationSettings,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            json
                as Map<
                  String,
                  dynamic
                >, // NotificationSettingsDto direkt Map olarak döndürüyoruz
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(
          apiResponse.message ?? 'Bildirim ayarları getirilemedi',
        );
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching notification settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> data) async {
    try {
      final response = await _networkClient.dio.put(
        ApiEndpoints.notificationSettings,
        data: data,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success) {
        throw Exception(
          apiResponse.message ?? 'Bildirim ayarları güncellenemedi',
        );
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error updating notification settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

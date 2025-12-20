import 'package:injectable/injectable.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/vendors/data/models/delivery_zone_models.dart';
import 'package:mobile/core/models/location_item.dart';

@lazySingleton
class VendorRemoteDataSource {
  VendorRemoteDataSource(this._networkClient);

  final NetworkClient _networkClient;

  Future<List<Vendor>> getVendors({
    int? vendorType,
    int page = 1,
    int pageSize = 6,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (vendorType != null) {
      queryParams['vendorType'] = vendorType;
    }

    final response = await _networkClient.dio.get(
      '/vendors',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          if (json is Map<String, dynamic> && json.containsKey('items')) {
            return (json['items'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }
          if (json is List) {
            return (json).map((e) => e as Map<String, dynamic>).toList();
          }
          return [];
        },
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Satıcılar getirilemedi');
      }

      return apiResponse.data!.map((json) => Vendor.fromJson(json)).toList();
    } else {
      // Legacy format
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('items')) {
        final items = response.data['items'] as List;
        return items.map((json) => Vendor.fromJson(json)).toList();
      } else {
        final List<dynamic> data = response.data;
        return data.map((json) => Vendor.fromJson(json)).toList();
      }
    }
  }

  Future<Map<String, dynamic>> getVendorProfile() async {
    final response = await _networkClient.dio.get('/vendor/profile');

    // Ideally map to VendorProfileDto
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateVendorBusyStatus(bool isBusy) async {
    final response = await _networkClient.dio.put(
      '/vendor/profile/status',
      data: {'isBusy': isBusy},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Satıcı durumu güncellenemedi');
    }
  }

  Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    // Only send fields that are present in the map
    // The MultipartFile logic for images is typically handled by Dio if FormData is used
    // If ApiService used FormData, we need to check.
    // Assuming simple JSON update or Map for now as per ApiService signature.
    // If ApiService handled file upload, we might need to look closer.

    final response = await _networkClient.dio.put(
      '/vendor/profile',
      data: data,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Satıcı profili güncellenemedi');
    }
  }

  Future<void> updateVendorSettings(Map<String, dynamic> settings) async {
    final response = await _networkClient.dio.put(
      '/vendor/profile/settings',
      data: settings,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Satıcı ayarları güncellenemedi');
    }
  }

  Future<void> toggleVendorActive(bool isActive) async {
    final response = await _networkClient.dio.put(
      '/vendor/profile/settings/active',
      data: {'isActive': isActive},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Satıcı aktiflik durumu güncellenemedi',
      );
    }
  }

  Future<List<dynamic>> getVendorNotifications() async {
    final response = await _networkClient.dio.get('/vendor/notifications');

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      // Using raw access for now as per ApiService
      return response.data['data']['items'] ?? [];
    }
    return response.data['items'] ?? [];
  }

  Future<void> markNotificationAsRead(String type, String id) async {
    final endpoint = type == 'vendor'
        ? '/vendor/notifications/$id/read'
        : type == 'customer'
        ? '/customer/notifications/$id/read'
        : '/courier/notifications/$id/read';

    final response = await _networkClient.dio.post(endpoint);

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Bildirim okundu olarak işaretlenemedi',
      );
    }
  }

  Future<void> markAllNotificationsAsRead(String type) async {
    final endpoint = type == 'vendor'
        ? '/vendor/notifications/read-all'
        : type == 'customer'
        ? '/customer/notifications/read-all'
        : '/courier/notifications/read-all';

    final response = await _networkClient.dio.post(endpoint);

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Tüm bildirimler okundu olarak işaretlenemedi',
      );
    }
  }

  Future<dynamic> getDeliveryZones({String? cityId}) async {
    final queryParams = <String, dynamic>{};
    if (cityId != null) {
      queryParams['cityId'] = cityId;
    }

    final response = await _networkClient.dio.get(
      '/vendor/delivery-zones',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Failed to load zones');
    }

    if (cityId == null) {
      return (apiResponse.data as List)
          .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      return CityZoneDto.fromJson(apiResponse.data as Map<String, dynamic>);
    }
  }

  Future<void> syncDeliveryZones(DeliveryZoneSyncDto dto) async {
    final response = await _networkClient.dio.put(
      '/vendor/delivery-zones',
      data: dto.toJson(),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Failed to sync zones');
    }
  }
}

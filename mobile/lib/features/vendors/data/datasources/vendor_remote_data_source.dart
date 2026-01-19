import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/vendor_api_constants.dart';
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
    double? userLatitude,
    double? userLongitude,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (vendorType != null) {
      queryParams['vendorType'] = vendorType;
    }
    if (userLatitude != null && userLongitude != null) {
      queryParams['userLatitude'] = userLatitude;
      queryParams['userLongitude'] = userLongitude;
    }

    final response = await _networkClient.dio.get(
      ApiEndpoints.vendors,
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

  Future<List<dynamic>> getVendorOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String();
    }
    if (page != null) queryParams['page'] = page;
    if (pageSize != null) queryParams['pageSize'] = pageSize;

    final response = await _networkClient.dio.get(
      VendorApiEndpoints.orders,
      queryParameters: queryParams,
    );
    // Backend artık ApiResponse<PagedResultDto> formatında döndürüyor
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(
          apiResponse.message ?? 'Satıcı siparişleri getirilemedi',
        );
      }

      // PagedResultDto'dan items listesini çıkar
      final pagedResult = apiResponse.data!;
      final items = pagedResult['items'] as List<dynamic>?;
      return items ?? [];
    }
    // Eski format (direkt liste)
    return response.data;
  }

  Future<Map<String, dynamic>> getVendorProfile() async {
    final response = await _networkClient.dio.get(VendorApiEndpoints.profile);

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Satıcı profili getirilemedi');
      }

      return apiResponse.data!;
    }

    // Ideally map to VendorProfileDto
    return response.data as Map<String, dynamic>;
  }

  Future<void> updateVendorBusyStatus(bool isBusy) async {
    final response = await _networkClient.dio.put(
      VendorApiEndpoints.settingsStatus,
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

    final response = await _networkClient.dio.post(
      VendorApiEndpoints.profile,
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
      VendorApiEndpoints.settings,
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

  Future<Map<String, dynamic>> getVendorSettings() async {
    final response = await _networkClient.dio.get(VendorApiEndpoints.settings);

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Satıcı ayarları getirilemedi');
      }

      return apiResponse.data!;
    }
    // Legacy format
    return response.data as Map<String, dynamic>;
  }

  Future<void> toggleVendorActive(bool isActive) async {
    final response = await _networkClient.dio.put(
      VendorApiEndpoints.settingsActive,
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
    final response = await _networkClient.dio.get(
      VendorApiEndpoints.notifications,
    );

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      // Using raw access for now as per ApiService
      return response.data['data']['items'] ?? [];
    }
    return response.data['items'] ?? [];
  }

  Future<void> markNotificationAsRead(String type, String id) async {
    final endpoint = type == 'vendor'
        ? VendorApiEndpoints.notificationRead(id)
        : type == 'customer'
        ? '/customer/notifications/$id/read'
        : '/couriers/dashboard/notifications/$id/read';

    // Note: This dynamic endpoint building is fine, ApiEndpoints doesn't need to cover every dynamic permuration if logic is here.
    // Or we could have ApiEndpoints.markRead(type, id) method. Keeping existing logic.

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
        ? VendorApiEndpoints.notificationsReadAll
        : type == 'customer'
        ? '/customer/notifications/read-all'
        : '/couriers/dashboard/notifications/read-all';

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
      VendorApiEndpoints.deliveryZones,
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
      VendorApiEndpoints.deliveryZones,
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

  Future<List<String>> getVendorProductCategories() async {
    final response = await _networkClient.dio.get(
      VendorApiEndpoints.productCategories,
    );

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List).map((e) => e as String).toList(),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Kategoriler getirilemedi');
      }

      return apiResponse.data!;
    }
    // Legacy support
    return List<String>.from(response.data);
  }

  Future<void> updateVendorImage(String imageUrl) async {
    final response = await _networkClient.dio.put(
      VendorApiEndpoints.profileImage,
      data: {'imageUrl': imageUrl},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Satıcı profil resmi güncellenemedi',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getVendorsForMap({
    double? userLatitude,
    double? userLongitude,
  }) async {
    final queryParams = <String, dynamic>{};
    if (userLatitude != null) queryParams['userLatitude'] = userLatitude;
    if (userLongitude != null) queryParams['userLongitude'] = userLongitude;

    final response = await _networkClient.dio.get(
      ApiEndpoints.mapVendors,
      queryParameters: queryParams,
    );

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List).map((e) => e as Map<String, dynamic>).toList(),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(
          apiResponse.message ?? 'Satıcı harita bilgileri getirilemedi',
        );
      }

      return apiResponse.data!;
    }
    // Legacy support
    return List<Map<String, dynamic>>.from(response.data);
  }
}

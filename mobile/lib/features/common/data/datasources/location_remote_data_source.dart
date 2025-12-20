import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/services/logger_service.dart';

@lazySingleton
class LocationRemoteDataSource {
  LocationRemoteDataSource(this._networkClient);
  final NetworkClient _networkClient;

  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final response = await _networkClient.dio.get(ApiEndpoints.countries);
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching countries', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationCities(String countryId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.cities}/$countryId',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cities', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationDistricts(String cityId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.districts}/$cityId',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching districts', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationLocalities(
    String districtId,
  ) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.localities}/$districtId',
      );
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching localities', e, stackTrace);
      return [];
    }
  }

  Future<void> updateCourierLocation(
    String courierId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _networkClient.dio.put(
        '${ApiEndpoints.courierLocation}/$courierId/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error updating courier location', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourierLocation(String courierId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.courierLocation}/$courierId/location',
      );
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching courier location', e, stackTrace);
      rethrow;
    }
  }

  Future<String> getGoogleMapsApiKey() async {
    try {
      final response = await _networkClient.dio.get(ApiEndpoints.mapApiKey);

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Google Maps API anahtarı getirilemedi',
          );
        }

        return apiResponse.data!['apiKey'] as String;
      }
      return response.data['apiKey'] as String;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching Google Maps API key',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getLegalContent(
    String type,
    String langCode,
  ) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.legalContent}/$type',
        queryParameters: {'lang': langCode},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Yasal belge getirilemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching legal content', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> getCities({int page = 1, int pageSize = 6}) async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.vendorCities,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) {
            if (json is Map<String, dynamic> && json.containsKey('items')) {
              return (json['items'] as List).map((e) => e as String).toList();
            }
            if (json is List) {
              return (json).map((e) => e as String).toList();
            }
            return <String>[];
          },
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Şehirler getirilemedi');
        }

        return apiResponse.data!;
      }
      return List<String>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cities', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.apiAutocomplete,
        queryParameters: {'query': query},
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Otomatik tamamlama sonuçları getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error during autocomplete', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.deliveryTracking}/$orderId',
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Teslimat takip bilgileri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching delivery tracking', e, stackTrace);
      rethrow;
    }
  }
}

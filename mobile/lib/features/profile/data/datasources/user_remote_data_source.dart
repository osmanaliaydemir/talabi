import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/services/logger_service.dart';

@lazySingleton
class UserRemoteDataSource {
  UserRemoteDataSource(this._networkClient);
  final NetworkClient _networkClient;

  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.userPreferences,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              json
                  as Map<
                    String,
                    dynamic
                  >, // UserPreferencesDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Kullanıcı tercihleri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt UserPreferencesDto)
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching user preferences', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateUserPreferences({
    String? language,
    String? currency,
    String? timeZone,
    String? dateFormat,
    String? timeFormat,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (language != null) data['language'] = language;
      if (currency != null) data['currency'] = currency;
      if (timeZone != null) data['timeZone'] = timeZone;
      if (dateFormat != null) data['dateFormat'] = dateFormat;
      if (timeFormat != null) data['timeFormat'] = timeFormat;

      final response = await _networkClient.dio.post(
        ApiEndpoints.userPreferences,
        data: data,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Kullanıcı tercihleri güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating user preferences', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.userPreferencesSupportedCurrencies,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Desteklenen para birimleri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt liste)
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching supported currencies',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    try {
      final response = await _networkClient.dio.get(
        ApiEndpoints.userPreferencesSupportedLanguages,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Desteklenen diller getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt liste)
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching supported languages',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

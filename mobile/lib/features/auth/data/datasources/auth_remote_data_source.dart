import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/services/logger_service.dart';

@lazySingleton
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._networkClient);

  final NetworkClient _networkClient;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      return await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error logging in', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName, {
    String? language,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (language != null) 'language': language,
      };

      final response = await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e, stackTrace) {
      LoggerService().error('Error registering', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> vendorRegister({
    required String email,
    required String password,
    required String fullName,
    required String businessName,
    required String phone,
    String? address,
    String? city,
    String? description,
    String? language,
    int vendorType = 1,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'businessName': businessName,
        'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (description != null) 'description': description,
        if (language != null) 'language': language,
        'vendorType': vendorType,
      };

      return await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.vendorRegister,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error registering vendor', e, stackTrace);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email, {String? language}) async {
    try {
      final data = {'email': email};
      if (language != null) {
        data['language'] = language;
      }

      await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.forgotPassword,
        data: data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error sending forgot password', e, stackTrace);
      rethrow;
    }
  }

  Future<String> verifyResetCode(String email, String code) async {
    try {
      final result = await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyResetCode,
        data: {'email': email, 'code': code},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      return result['token'] as String;
    } catch (e, stackTrace) {
      LoggerService().error('Error verifying reset code', e, stackTrace);
      rethrow;
    }
  }

  Future<void> resetPassword(
    String email,
    String token,
    String newPassword,
  ) async {
    try {
      await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.resetPassword,
        data: {'email': email, 'token': token, 'newPassword': newPassword},
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error resetting password', e, stackTrace);
      rethrow;
    }
  }

  Future<void> confirmEmail(String token, String email) async {
    try {
      await _networkClient.get(
        ApiEndpoints.confirmEmail,
        queryParameters: {'token': token, 'email': email},
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error confirming email', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyEmailCode(
    String email,
    String code,
  ) async {
    try {
      final response = await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.verifyEmailCode,
        data: {'email': email, 'code': code},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e, stackTrace) {
      LoggerService().error('Error verifying email code', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendVerificationCode(
    String email, {
    String? language,
  }) async {
    try {
      final requestData = {
        'email': email,
        if (language != null) 'language': language,
      };

      final response = await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.resendVerificationCode,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return response;
    } catch (e, stackTrace) {
      LoggerService().error('Error resending verification code', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> courierRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required int vehicleType,
    String? language,
  }) async {
    try {
      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'vehicleType': vehicleType,
        if (language != null) 'language': language,
      };

      return await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.courierRegister,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error registering courier', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> externalLogin({
    required String provider,
    required String idToken,
    required String email,
    required String fullName,
    String? language,
  }) async {
    try {
      final requestData = {
        'provider': provider,
        'idToken': idToken,
        'email': email,
        'fullName': fullName,
        if (language != null) 'language': language,
      };

      return await _networkClient.post<Map<String, dynamic>>(
        ApiEndpoints.externalLogin,
        data: requestData,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error during external login with $provider',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> registerDeviceToken(String token, String deviceType) async {
    try {
      await _networkClient.post(
        ApiEndpoints.registerDeviceToken,
        data: {'token': token, 'deviceType': deviceType},

        fromJson: (json) =>
            json, // This will trigger ApiResponse check inside NetworkClient
      );
    } catch (e, stackTrace) {
      LoggerService().warning('Error registering device token', e, stackTrace);
      // Suppress error as per original requirement
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _networkClient.dio.post(
        ApiEndpoints.userProfile,
        data: data,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Profil güncellenemedi');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _networkClient.post<dynamic>(
        ApiEndpoints.deleteAccount,
        fromJson: (json) => json,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error deleting account', e, stackTrace);
      rethrow;
    }
  }
}

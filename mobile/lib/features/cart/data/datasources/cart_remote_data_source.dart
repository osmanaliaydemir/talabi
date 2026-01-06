import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/services/logger_service.dart';

@lazySingleton
class CartRemoteDataSource {
  CartRemoteDataSource(this._networkClient);
  final NetworkClient _networkClient;

  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _networkClient.dio.get(ApiEndpoints.cart);
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
                  >, // CartDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Sepet getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt CartDto)
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addToCart(
    String productId,
    int quantity, {
    List<Map<String, dynamic>>? selectedOptions,
  }) async {
    try {
      final data = {'productId': productId, 'quantity': quantity};
      if (selectedOptions != null) {
        data['selectedOptions'] = selectedOptions;
      }
      final response = await _networkClient.dio.post(
        ApiEndpoints.cartItems,
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
          throw Exception(apiResponse.message ?? 'Ürün sepete eklenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error adding to cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCartItem(String itemId, int quantity) async {
    try {
      final response = await _networkClient.dio.put(
        '${ApiEndpoints.cartItems}/$itemId',
        data: {'quantity': quantity},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sepet ürünü güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating cart item', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final response = await _networkClient.dio.delete(
        '${ApiEndpoints.cartItems}/$itemId',
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Ürün sepetten silinemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error removing from cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final response = await _networkClient.dio.delete(ApiEndpoints.cart);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sepet temizlenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCartPromotions({
    String? couponCode,
    String? campaignId,
  }) async {
    try {
      final response = await _networkClient.dio.put(
        '${ApiEndpoints.cart}/promotions',
        data: {'couponCode': couponCode, 'campaignId': campaignId},
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Sepet promosyonları güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating cart promotions', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCartPromotions() async {
    try {
      final response = await _networkClient.dio.delete(
        '${ApiEndpoints.cart}/promotions',
      );

      final apiResponse = ApiResponse<Map<String, dynamic>?>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Promosyonlar temizlenemedi');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart promotions', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations({
    int? type,
    double? lat,
    double? lon,
  }) async {
    try {
      final response = await _networkClient.dio.get(
        '${ApiEndpoints.cart}/recommendations',
        queryParameters: {
          if (type != null) 'type': type,
          if (lat != null) 'lat': lat,
          if (lon != null) 'lon': lon,
        },
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          return [];
        }

        return apiResponse.data!;
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching recommendations', e, stackTrace);
      return [];
    }
  }
}

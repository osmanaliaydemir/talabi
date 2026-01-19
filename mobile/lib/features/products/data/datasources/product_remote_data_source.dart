import 'package:injectable/injectable.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/constants/vendor_api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:dio/dio.dart';
import 'package:mobile/features/products/data/models/product.dart';

import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/features/home/data/models/promotional_banner.dart';

@lazySingleton
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._networkClient);

  final NetworkClient _networkClient;

  Future<List<Product>> getProducts(
    String vendorId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    // Note: This endpoint '/vendors/$vendorId/products' is dynamic.
    // We can keep it as string interpolation or add a method in ApiEndpoints to generate it.
    // For now, I will stick to string interpolation for path param based URLs if not strictly defined as base + param.
    // But `ApiEndpoints.vendors` is `/vendors`. So usage: '${ApiEndpoints.vendors}/$vendorId/products'
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.vendors}/$vendorId/products',
      queryParameters: {'page': page, 'pageSize': pageSize},
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
        throw Exception(apiResponse.message ?? 'Satıcı ürünleri getirilemedi');
      }

      return apiResponse.data!.map((json) => Product.fromJson(json)).toList();
    } else {
      // Legacy format
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('items')) {
        final items = response.data['items'] as List;
        return items.map((json) => Product.fromJson(json)).toList();
      } else {
        final List<dynamic> data = response.data;
        return data.map((json) => Product.fromJson(json)).toList();
      }
    }
  }

  Future<List<Product>> getPopularProducts({
    int page = 1,
    int pageSize = 6,
    int? vendorType,
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
      ApiEndpoints.popularProducts,
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        if (json is Map<String, dynamic> && json.containsKey('items')) {
          return (json['items'] as List)
              .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (json is List) {
          return json
              .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ProductDto>[];
      },
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Popüler ürünler getirilemedi');
    }

    if (apiResponse.data == null) return [];

    return apiResponse.data!.map((dto) => dto.toProduct()).toList();
  }

  Future<Product> getProduct(String productId) async {
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.products}/$productId',
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Ürün detayları getirilemedi');
    }

    return apiResponse.data!;
  }

  Future<List<Product>> getSimilarProducts(
    String productId, {
    int page = 1,
    int pageSize = 6,
    double? userLatitude,
    double? userLongitude,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (userLatitude != null && userLongitude != null) {
      queryParams['userLatitude'] = userLatitude;
      queryParams['userLongitude'] = userLongitude;
    }
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.products}/$productId/similar',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        if (json is Map<String, dynamic> && json.containsKey('items')) {
          return (json['items'] as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (json is List) {
          return (json)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <Product>[];
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Benzer ürünler getirilemedi');
    }

    return apiResponse.data!;
  }

  Future<List<PromotionalBanner>> getBanners({
    String? language,
    int? vendorType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (language != null) queryParams['language'] = language;
    if (vendorType != null) queryParams['vendorType'] = vendorType;

    final response = await _networkClient.dio.get(
      ApiEndpoints.banners,
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => (json as List)
          .map((e) => PromotionalBanner.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Bannerlar getirilemedi');
    }

    return apiResponse.data!;
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await _networkClient.dio.post(
      VendorApiEndpoints.products,
      data: data,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Product.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Ürün oluşturulamadı');
    }

    return apiResponse.data!;
  }

  Future<void> updateProductPrice(String productId, double price) async {
    final response = await _networkClient.dio.post(
      VendorApiEndpoints.productPrice(productId),
      data: {'price': price},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Ürün fiyatı güncellenemedi');
    }
  }

  Future<void> updateProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    final response = await _networkClient.dio.post(
      VendorApiEndpoints.productAvailability(productId),
      data: {'isAvailable': isAvailable},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Ürün müsaitlik durumu güncellenemedi',
      );
    }
  }

  Future<void> deleteProduct(String productId) async {
    final response = await _networkClient.dio.post(
      '${VendorApiEndpoints.product(productId)}/delete',
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Ürün silinemedi');
    }
  }

  Future<String> uploadProductImage(dynamic file) async {
    final formData = FormData.fromMap({'file': file});

    final response = await _networkClient.dio.post(
      ApiEndpoints.upload,
      data: formData,
    );
    // Assuming existing response structure from ApiService: response.data['data']['url']
    if (response.data is Map<String, dynamic> &&
        response.data['data'] != null) {
      return response.data['data']['url'];
    }
    // Handle ApiResponse structure if migrated
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!['url'];
      }
    }
    return response.data['data']['url'];
  }
}

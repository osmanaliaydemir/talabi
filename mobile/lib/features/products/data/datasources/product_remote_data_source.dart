import 'package:injectable/injectable.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
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
    final response = await _networkClient.dio.get(
      '/vendors/$vendorId/products',
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
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (vendorType != null) {
      queryParams['vendorType'] = vendorType;
    }
    final response = await _networkClient.dio.get(
      '/products/popular',
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
    final response = await _networkClient.dio.get('/products/$productId');

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
  }) async {
    final response = await _networkClient.dio.get(
      '/products/$productId/similar',
      queryParameters: {'page': page, 'pageSize': pageSize},
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
      '/banners',
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
}

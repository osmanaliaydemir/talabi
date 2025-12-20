import 'dart:async';
import 'package:dio/dio.dart';
import 'package:mobile/features/orders/data/models/order.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/features/home/data/models/promotional_banner.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/features/notifications/data/models/customer_notification.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart' hide Order;
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/features/vendors/data/models/delivery_zone_models.dart';
import 'package:mobile/core/models/location_item.dart';

import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mobile/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:mobile/features/vendors/data/datasources/vendor_remote_data_source.dart';

// const String _requestPermitKey = '_apiRequestPermit'; // Moved to NetworkClient

@lazySingleton
class ApiService {
  // Backwards compatibility factory
  factory ApiService() => GetIt.instance<ApiService>();

  @factoryMethod
  ApiService.init(
    this._networkClient,
    this._authRemoteDataSource,
    this._productRemoteDataSource,
    this._orderRemoteDataSource,
    this._vendorRemoteDataSource,
    this._cacheService,
  );

  final NetworkClient _networkClient;
  final AuthRemoteDataSource _authRemoteDataSource;
  final ProductRemoteDataSource _productRemoteDataSource;
  final OrderRemoteDataSource _orderRemoteDataSource;
  final VendorRemoteDataSource _vendorRemoteDataSource;
  final CacheService _cacheService;

  Dio get dio => _networkClient.dio;
  static const String baseUrl = NetworkClient.baseUrl;
  void notifyLogout() => _networkClient.notifyLogout();
  void resetLogout() => _networkClient.resetLogout();

  // Legacy body placeholder

  Future<List<Vendor>> getVendors({
    int? vendorType,
    int page = 1,
    int pageSize = 6,
  }) async {
    try {
      final vendors = await _vendorRemoteDataSource.getVendors(
        vendorType: vendorType,
        page: page,
        pageSize: pageSize,
      );

      if (page == 1) {
        await _cacheService.cacheVendors(vendors);
      }

      return vendors;
    } on DioException catch (e, stackTrace) {
      LoggerService().error('Error fetching vendors', e, stackTrace);

      if (page == 1 &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError)) {
        final cachedVendors = await _cacheService.getCachedVendors();
        if (cachedVendors != null && cachedVendors.isNotEmpty) {
          LoggerService().debug('📦 [CACHE] Returning cached vendors');
          return cachedVendors;
        }
      }

      rethrow;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendors', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Product>> getProducts(
    String vendorId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    try {
      final products = await _productRemoteDataSource.getProducts(
        vendorId,
        page: page,
        pageSize: pageSize,
      );

      if (page == 1) {
        await _cacheService.cacheProducts(products);
      }

      return products;
    } on DioException catch (e, stackTrace) {
      LoggerService().error('Error fetching products', e, stackTrace);

      if (page == 1 &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError)) {
        final cachedProducts = await _cacheService.getCachedProducts();
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          LoggerService().debug('📦 [CACHE] Returning cached products');
          return cachedProducts;
        }
      }

      rethrow;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching products', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Product>> getPopularProducts({
    int page = 1,
    int pageSize = 6,
    int? vendorType,
  }) async {
    try {
      return await _productRemoteDataSource.getPopularProducts(
        page: page,
        pageSize: pageSize,
        vendorType: vendorType,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching popular products', e, stackTrace);
      rethrow;
    }
  }

  Future<List<PromotionalBanner>> getBanners({
    String? language,
    int? vendorType,
  }) async {
    try {
      return await _productRemoteDataSource.getBanners(
        language: language,
        vendorType: vendorType,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching banners', e, stackTrace);
      rethrow;
    }
  }

  Future<Product> getProduct(String productId) async {
    try {
      return await _productRemoteDataSource.getProduct(productId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching product', e, stackTrace);
      rethrow;
    }
  }

  /// Benzer ürünleri getirir - Aynı kategorideki diğer ürünler
  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final response = await dio.get('/locations/countries');
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
      final response = await dio.get('/locations/cities/$countryId');
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
      final response = await dio.get('/locations/districts/$cityId');
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
      final response = await dio.get('/locations/localities/$districtId');
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching localities', e, stackTrace);
      return [];
    }
  }

  Future<List<Product>> getSimilarProducts(
    String productId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    try {
      return await _productRemoteDataSource.getSimilarProducts(
        productId,
        page: page,
        pageSize: pageSize,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching similar products', e, stackTrace);
      return [];
    }
  }

  Future<Order> createOrder(
    String vendorId,
    Map<String, int> items, {
    String? deliveryAddressId,
    String? paymentMethod,
    String? note,
  }) async {
    try {
      return await _orderRemoteDataSource.createOrder(
        vendorId,
        items,
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
        note: note,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error creating order', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return _authRemoteDataSource.login(email, password);
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName, {
    String? language,
  }) {
    return _authRemoteDataSource.register(
      email,
      password,
      fullName,
      language: language,
    );
  }

  // Vendor Registration
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
  }) {
    return _authRemoteDataSource.vendorRegister(
      email: email,
      password: password,
      fullName: fullName,
      businessName: businessName,
      phone: phone,
      address: address,
      city: city,
      description: description,
      language: language,
      vendorType: vendorType,
    );
  }

  Future<Map<String, dynamic>> courierRegister({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required int vehicleType,
    String? language,
  }) {
    return _authRemoteDataSource.courierRegister(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      vehicleType: vehicleType,
      language: language,
    );
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> forgotPassword(String email, {String? language}) {
    return _authRemoteDataSource.forgotPassword(email, language: language);
  }

  Future<String> verifyResetCode(String email, String code) {
    return _authRemoteDataSource.verifyResetCode(email, code);
  }

  Future<void> resetPassword(String email, String token, String newPassword) {
    return _authRemoteDataSource.resetPassword(email, token, newPassword);
  }

  Future<void> confirmEmail(String token, String email) {
    return _authRemoteDataSource.confirmEmail(token, email);
  }

  Future<Map<String, dynamic>> verifyEmailCode(String email, String code) {
    return _authRemoteDataSource.verifyEmailCode(email, code);
  }

  Future<Map<String, dynamic>> resendVerificationCode(
    String email, {
    String? language,
  }) {
    return _authRemoteDataSource.resendVerificationCode(
      email,
      language: language,
    );
  }

  // External Login (Google, Apple, Facebook)
  Future<Map<String, dynamic>> externalLogin({
    required String provider,
    required String idToken,
    required String email,
    required String fullName,
    String? language,
  }) {
    return _authRemoteDataSource.externalLogin(
      provider: provider,
      idToken: idToken,
      email: email,
      fullName: fullName,
      language: language,
    );
  }

  // Notification methods
  Future<void> registerDeviceToken(String token, String deviceType) {
    return _authRemoteDataSource.registerDeviceToken(token, deviceType);
  }

  Future<List<CustomerNotification>> getCustomerNotifications() async {
    try {
      final response = await dio.get('/customer/notifications');
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

  // Cart methods
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await dio.get('/cart');
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

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final response = await dio.post(
        '/cart/items',
        data: {'productId': productId, 'quantity': quantity},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          // ADDRESS_REQUIRED hatası için özel kontrol
          if (apiResponse.errorCode == 'ADDRESS_REQUIRED' &&
              apiResponse.data != null) {
            final data = apiResponse.data as Map<String, dynamic>;
            if (data['requiresAddress'] == true) {
              throw Exception(apiResponse.message ?? 'Adres gerekli');
            }
          }
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
      final response = await dio.put(
        '/cart/items/$itemId',
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
          throw Exception(apiResponse.message ?? 'Sepet öğesi güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating cart item', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final response = await dio.delete('/cart/items/$itemId');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Ürün sepetten çıkarılamadı');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error removing from cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      final response = await dio.delete('/cart');
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

  // Profile methods
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Try network first
      final response = await dio.get('/profile');

      // Backend artık ApiResponse<T> formatında döndürüyor
      Map<String, dynamic> profile;
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              json
                  as Map<
                    String,
                    dynamic
                  >, // UserProfileDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Profil bilgileri getirilemedi',
          );
        }

        profile = apiResponse.data!;
      } else {
        // Eski format (direkt UserProfileDto)
        profile = response.data as Map<String, dynamic>;
      }

      // Cache the result
      await _cacheService.cacheProfile(profile);

      return profile;
    } on DioException catch (e, stackTrace) {
      LoggerService().error('Error fetching profile', e, stackTrace);

      // If offline or network error, try cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedProfile = await _cacheService.getCachedProfile();
        if (cachedProfile != null) {
          LoggerService().debug('📦 [CACHE] Returning cached profile');
          return cachedProfile;
        }
      }

      rethrow;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) {
    return _authRemoteDataSource.updateProfile(data);
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await dio.put(
        '/profile/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          final errorMessage =
              apiResponse.message ??
              (apiResponse.errors?.isNotEmpty == true
                  ? apiResponse.errors!.join(', ')
                  : 'Şifre değiştirilemedi');
          throw Exception(errorMessage);
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error changing password', e, stackTrace);
      rethrow;
    }
  }

  // Address methods
  Future<List<dynamic>> getAddresses() async {
    try {
      final response = await dio.get('/addresses');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) =>
              (json as List).map((e) => e as Map<String, dynamic>).toList(),
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Adresler getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt liste)
      return response.data as List;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching addresses', e, stackTrace);
      rethrow;
    }
  }

  Future<void> createAddress(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/addresses', data: data);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Adres oluşturulamadı');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error creating address', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/addresses/$id', data: data);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Adres güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating address', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      final response = await dio.delete('/addresses/$id');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Adres silinemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error deleting address', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      final response = await dio.put('/addresses/$id/set-default');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Varsayılan adres ayarlanamadı',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error setting default address', e, stackTrace);
      rethrow;
    }
  }

  // Favorites methods
  /// Get favorites with pagination support
  Future<PagedResultDto<ProductDto>> getFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        '/favorites',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      // Backend artık ApiResponse<PagedResultDto<ProductDto>> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PagedResultDto.fromJson(
          json as Map<String, dynamic>,
          (itemJson) => ProductDto.fromJson(itemJson),
        ),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Favori ürünler getirilemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching favorites', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addToFavorites(String productId) async {
    try {
      final response = await dio.post('/favorites/$productId');
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Favorilere eklenemedi');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error adding to favorites', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      final response = await dio.delete('/favorites/$productId');
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Favorilerden çıkarılamadı');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error removing from favorites', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> isFavorite(String productId) async {
    try {
      final response = await dio.get('/favorites/check/$productId');
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>?,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        return false;
      }

      return apiResponse.data!['isFavorite'] ?? false;
    } catch (e, stackTrace) {
      LoggerService().error('Error checking favorite', e, stackTrace);
      return false;
    }
  }

  // Notification settings methods
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await dio.get('/notifications/settings');
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
      final response = await dio.put('/notifications/settings', data: data);
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

  // Orders methods
  // Orders methods
  Future<List<dynamic>> getOrders({int? vendorType}) async {
    try {
      return await _orderRemoteDataSource.getOrders(vendorType: vendorType);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching orders', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final order = await _orderRemoteDataSource.getOrderDetails(orderId);
      // Convert Order object back to Map for compatibility if needed, or update return type.
      // Assuming legacy code expects Map, but new DS returns Order object.
      // Wait, getOrderDetails signature in ApiService returns Future<Map<String, dynamic>>.
      // But OrderRemoteDataSource.getCustomerOrderDetails returns Future<Order>.
      // I should update ApiService return type OR convert Order to Map.
      // Better to convert to Map to minimize breakage in calling code for now.
      return order;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching order details', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetailFull(String orderId) async {
    try {
      return await _orderRemoteDataSource.getOrderDetailFull(orderId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching order detail', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _orderRemoteDataSource.cancelOrder(orderId, reason);
    } catch (e, stackTrace) {
      LoggerService().error('Error cancelling order', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelOrderItem(
    String customerOrderItemId,
    String reason,
  ) async {
    try {
      await _orderRemoteDataSource.cancelOrderItem(customerOrderItemId, reason);
    } catch (e, stackTrace) {
      LoggerService().error('Error cancelling order item', e, stackTrace);
      rethrow;
    }
  }

  // Search and filter methods
  Future<PagedResultDto<ProductDto>> searchProducts(
    ProductSearchRequestDto request,
  ) async {
    try {
      final response = await dio.get(
        '/products/search',
        queryParameters: request.toJson(),
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => PagedResultDto.fromJson(
          json as Map<String, dynamic>,
          (itemJson) => ProductDto.fromJson(itemJson),
        ),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Ürün arama başarısız');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error searching products', e, stackTrace);
      rethrow;
    }
  }

  Future<PagedResultDto<VendorDto>> searchVendors(
    VendorSearchRequestDto request,
  ) async {
    try {
      final response = await dio.get(
        '/vendors/search',
        queryParameters: request.toJson(),
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
                  >, // PagedResultDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı arama sonuçları getirilemedi',
          );
        }

        return PagedResultDto.fromJson(
          apiResponse.data!,
          (json) => VendorDto.fromJson(json),
        );
      }
      // Eski format (direkt PagedResultDto)
      return PagedResultDto.fromJson(
        response.data,
        (json) => VendorDto.fromJson(json),
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error searching vendors', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories({
    String? language,
    int? vendorType,
    int page = 1,
    int pageSize = 6,
  }) async {
    try {
      // Try network first
      final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
      if (language != null) {
        queryParams['lang'] = language;
      }
      if (vendorType != null) {
        queryParams['vendorType'] = vendorType;
      }
      final response = await dio.get(
        '/products/categories',
        queryParameters: queryParams,
      );
      // Backend artık ApiResponse<PagedResultDto<CategoryDto>> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) {
          // Check if pagination wrapper exists (data: { items: [...] })
          if (json is Map<String, dynamic> && json.containsKey('items')) {
            return (json['items'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }
          // Fallback for direct list (data: [...])
          if (json is List) {
            return (json).map((e) => e as Map<String, dynamic>).toList();
          }
          return <Map<String, dynamic>>[];
        },
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Kategoriler getirilemedi');
      }

      final categories = apiResponse.data!;

      // İstemci tarafı filtreleme (Backend tarafında filtreleme çalışmıyorsa)
      if (vendorType != null) {
        return categories.where((c) {
          final itemVendorType = c['vendorType'];
          // Eğer vendorType belirtilmemişse göster, belirtilmişse eşleşeni göster
          return itemVendorType == null || itemVendorType == vendorType;
        }).toList();
      }

      // Cache the result
      // await _cacheService.cacheCategories(categories);

      return categories;
    } on DioException catch (e, stackTrace) {
      LoggerService().error('Error fetching categories', e, stackTrace);

      // If offline or network error, try cache
      /*
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedCategories = await _cacheService.getCachedCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          LoggerService().debug('📦 [CACHE] Returning cached categories');
          return cachedCategories;
        }
      }
      */

      rethrow;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching categories', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> getCities({int page = 1, int pageSize = 6}) async {
    try {
      final response = await dio.get(
        '/vendors/cities',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      // Backend artık ApiResponse<PagedResultDto<string>> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) {
            // Check if pagination wrapper exists (data: { items: [...] })
            if (json is Map<String, dynamic> && json.containsKey('items')) {
              return (json['items'] as List).map((e) => e as String).toList();
            }
            // Fallback for direct list (data: [...])
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
      // Eski format (direkt liste)
      return List<String>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cities', e, stackTrace);
      rethrow;
    }
  }

  Future<List<AutocompleteResultDto>> autocomplete(String query) async {
    try {
      final response = await dio.get(
        '/search/autocomplete',
        queryParameters: {'query': query},
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
            apiResponse.message ?? 'Otomatik tamamlama sonuçları getirilemedi',
          );
        }

        return apiResponse.data!
            .map((e) => AutocompleteResultDto.fromJson(e))
            .toList();
      }
      // Eski format (direkt liste)
      return (response.data as List)
          .map((e) => AutocompleteResultDto.fromJson(e))
          .toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error during autocomplete', e, stackTrace);
      rethrow;
    }
  }

  // Map and location methods
  Future<String> getGoogleMapsApiKey() async {
    try {
      final response = await dio.get('/map/api-key');
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
                  >, // ApiKey objesi direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Google Maps API anahtarı getirilemedi',
          );
        }

        return apiResponse.data!['apiKey'] as String;
      }
      // Eski format (direkt { apiKey: "..." })
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

  Future<List<Map<String, dynamic>>> getVendorsForMap({
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userLatitude != null) queryParams['userLatitude'] = userLatitude;
      if (userLongitude != null) queryParams['userLongitude'] = userLongitude;

      final response = await dio.get(
        '/map/vendors',
        queryParameters: queryParams,
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
            apiResponse.message ?? 'Satıcı harita bilgileri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt liste)
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendors for map', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    try {
      final response = await dio.get('/map/delivery-tracking/$orderId');
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
                  >, // DeliveryTrackingDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Teslimat takip bilgileri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt DeliveryTrackingDto)
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching delivery tracking', e, stackTrace);
      rethrow;
    }
  }

  // Courier location methods
  Future<void> updateCourierLocation(
    String courierId,
    double latitude,
    double longitude,
  ) async {
    try {
      await dio.put(
        '/courier/$courierId/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error updating courier location', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourierLocation(String courierId) async {
    try {
      final response = await dio.get('/courier/$courierId/location');
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching courier location', e, stackTrace);
      rethrow;
    }
  }

  // Review methods
  Future<Review> createReview(
    String targetId,
    String targetType,
    int rating,
    String comment,
  ) async {
    try {
      final response = await dio.post(
        '/reviews',
        data: {
          'targetId': targetId,
          'targetType': targetType,
          'rating': rating,
          'comment': comment,
        },
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
                  >, // ReviewDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Değerlendirme oluşturulamadı',
          );
        }

        return Review.fromJson(apiResponse.data!);
      }
      // Eski format (direkt ReviewDto)
      return Review.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error creating review', e, stackTrace);
      rethrow;
    }
  }

  Future<ProductReviewsSummary> getProductReviews(String productId) async {
    try {
      final response = await dio.get('/reviews/products/$productId');

      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) {
            // Eğer data bir Map ise (yeni format - ProductReviewsSummaryDto)
            if (json is Map<String, dynamic>) {
              return json;
            }
            // Eğer data bir List ise (eski format)
            return null;
          },
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Ürün değerlendirmeleri getirilemedi',
          );
        }

        // Yeni format: ProductReviewsSummaryDto (Map)
        if (apiResponse.data is Map<String, dynamic>) {
          return ProductReviewsSummary.fromJson(
            apiResponse.data as Map<String, dynamic>,
          );
        }

        // Eski format: Direkt List<ReviewDto>
        if (apiResponse.data is List) {
          final List<dynamic> data = apiResponse.data as List;
          final reviews = data
              .map((json) => Review.fromJson(json as Map<String, dynamic>))
              .toList();
          final avgRating = reviews.isNotEmpty
              ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                    reviews.length
              : 0.0;
          return ProductReviewsSummary(
            averageRating: avgRating,
            totalRatings: reviews.length,
            totalComments: reviews.where((r) => r.comment.isNotEmpty).length,
            reviews: reviews,
          );
        }
      }

      // Eski format (direkt liste) - geriye dönük uyumluluk
      if (response.data is List) {
        final List<dynamic> data = response.data as List;
        final reviews = data
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();
        final avgRating = reviews.isNotEmpty
            ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length
            : 0.0;
        return ProductReviewsSummary(
          averageRating: avgRating,
          totalRatings: reviews.length,
          totalComments: reviews.where((r) => r.comment.isNotEmpty).length,
          reviews: reviews,
        );
      }

      throw Exception('Beklenmeyen response formatı');
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching product reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Review>> getVendorReviews(String vendorId) async {
    try {
      final response = await dio.get('/reviews/vendors/$vendorId');
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
            apiResponse.message ?? 'Satıcı değerlendirmeleri getirilemedi',
          );
        }

        return apiResponse.data!.map((json) => Review.fromJson(json)).toList();
      }
      // Eski format (direkt liste)
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Review>> getPendingReviews() async {
    try {
      final response = await dio.get('/reviews/pending');
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
            apiResponse.message ?? 'Bekleyen değerlendirmeler getirilemedi',
          );
        }

        return apiResponse.data!.map((json) => Review.fromJson(json)).toList();
      }
      // Eski format (direkt liste)
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching pending reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<void> approveReview(String reviewId) async {
    try {
      final response = await dio.patch('/reviews/$reviewId/approve');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Değerlendirme onaylanamadı');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error approving review', e, stackTrace);
      rethrow;
    }
  }

  Future<void> rejectReview(String reviewId) async {
    try {
      final response = await dio.patch('/reviews/$reviewId/reject');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Değerlendirme reddedilemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error rejecting review', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveCouriers() async {
    try {
      final response = await dio.get('/courier/active');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching active couriers', e, stackTrace);
      rethrow;
    }
  }

  // User preferences methods
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await dio.get('/userpreferences');
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

      final response = await dio.put('/userpreferences', data: data);
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

  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    try {
      final response = await dio.get('/userpreferences/supported-languages');
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

  Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      final response = await dio.get('/userpreferences/supported-currencies');
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

  // Vendor Orders methods
  Future<List<dynamic>> getVendorOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    try {
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

      final response = await dio.get(
        '/vendor/orders',
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
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor orders', e, stackTrace);
      rethrow;
    }
  }

  /// Vendor orders'ı totalCount ile birlikte getirir (count için optimize edilmiş)
  Future<Map<String, dynamic>> getVendorOrdersWithCount({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? pageSize,
  }) async {
    try {
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

      final response = await dio.get(
        '/vendor/orders',
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

        // PagedResultDto'dan hem items hem de totalCount'u döndür
        final pagedResult = apiResponse.data!;
        return {
          'items': pagedResult['items'] as List<dynamic>? ?? [],
          'totalCount': pagedResult['totalCount'] as int? ?? 0,
        };
      }
      // Eski format (direkt liste)
      return {
        'items': response.data ?? [],
        'totalCount': (response.data as List?)?.length ?? 0,
      };
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching vendor orders with count',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorOrder(String orderId) async {
    try {
      final response = await dio.get('/vendor/orders/$orderId');
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
                  >, // VendorOrderDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı siparişi getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt VendorOrderDto)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor order', e, stackTrace);
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      final response = await dio.post('/vendor/orders/$orderId/accept');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş kabul edilemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error accepting order', e, stackTrace);
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    try {
      final response = await dio.post(
        '/vendor/orders/$orderId/reject',
        data: {'reason': reason},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Sipariş reddedilemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error rejecting order', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    try {
      final response = await dio.put(
        '/vendor/orders/$orderId/status',
        data: {'status': status, 'note': note},
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
            apiResponse.message ?? 'Sipariş durumu güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating order status', e, stackTrace);
      rethrow;
    }
  }

  // Get available couriers for order
  Future<List<Map<String, dynamic>>> getAvailableCouriers(
    String orderId,
  ) async {
    try {
      final response = await dio.get(
        '/vendor/orders/$orderId/available-couriers',
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
            apiResponse.message ?? 'Müsait kuryeler getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt liste)
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error getting available couriers', e, stackTrace);
      rethrow;
    }
  }

  // Assign courier to order
  Future<void> assignCourierToOrder(String orderId, String courierId) async {
    try {
      final response = await dio.post(
        '/vendor/orders/$orderId/assign-courier',
        data: {'courierId': courierId},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Kurye atanamadı');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error assigning courier', e, stackTrace);
      rethrow;
    }
  }

  // Auto-assign best courier
  Future<Map<String, dynamic>> autoAssignCourier(String orderId) async {
    try {
      final response = await dio.post(
        '/vendor/orders/$orderId/auto-assign-courier',
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Kurye otomatik atanamadı');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt Map)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error auto-assigning courier', e, stackTrace);
      rethrow;
    }
  }

  // Vendor Reports methods
  Future<Map<String, dynamic>> getSalesReport({
    DateTime? startDate,
    DateTime? endDate,
    String period = 'week',
  }) async {
    try {
      final queryParams = <String, dynamic>{'period': period};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await dio.get(
        '/vendor/reports/sales',
        queryParameters: queryParams,
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
                  >, // SalesReportDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Satış raporu getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt SalesReportDto)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching sales report', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorSummary() async {
    try {
      final response = await dio.get('/vendor/reports/summary');
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
                  >, // Summary object direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı özet istatistikleri getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt summary object)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor summary', e, stackTrace);
      rethrow;
    }
  }

  // Vendor Product Management Methods
  Future<List<Product>> getVendorProducts({
    String? category,
    bool? isAvailable,
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;

      final response = await dio.get(
        '/vendor/products',
        queryParameters: queryParams,
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) {
            // Check if pagination wrapper exists (data: { items: [...] })
            if (json is Map<String, dynamic> && json.containsKey('items')) {
              return (json['items'] as List)
                  .map((e) => e as Map<String, dynamic>)
                  .toList();
            }
            // Fallback for direct list (data: [...])
            if (json is List) {
              return (json).map((e) => e as Map<String, dynamic>).toList();
            }
            return [];
          },
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı ürünleri getirilemedi',
          );
        }

        return apiResponse.data!.map((json) => Product.fromJson(json)).toList();
      }
      // Eski formatlar
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('items')) {
        // Direct pagination object without standard ApiResponse wrapper
        final items = response.data['items'] as List;
        return items.map((json) => Product.fromJson(json)).toList();
      } else if (response.data is List) {
        // Direct list
        final List<dynamic> data = response.data;
        return data.map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor products', e, stackTrace);
      rethrow;
    }
  }

  Future<Product> getVendorProduct(String productId) async {
    try {
      final response = await dio.get('/vendor/products/$productId');
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
                  >, // VendorProductDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Satıcı ürünü getirilemedi');
        }

        return Product.fromJson(apiResponse.data!);
      }
      // Eski format (direkt ProductDto)
      return Product.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor product', e, stackTrace);
      rethrow;
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/vendor/products', data: data);
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
                  >, // VendorProductDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Ürün oluşturulamadı');
        }

        return Product.fromJson(apiResponse.data!);
      }
      // Eski format (direkt ProductDto)
      return Product.fromJson(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error creating product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await dio.put('/vendor/products/$productId', data: data);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Ürün güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final response = await dio.delete('/vendor/products/$productId');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Ürün silinemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error deleting product', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    try {
      final response = await dio.put(
        '/vendor/products/$productId/availability',
        data: {'isAvailable': isAvailable},
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
            apiResponse.message ?? 'Ürün müsaitlik durumu güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error updating product availability',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> updateProductPrice(String productId, double price) async {
    try {
      final response = await dio.put(
        '/vendor/products/$productId/price',
        data: {'price': price},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(apiResponse.message ?? 'Ürün fiyatı güncellenemedi');
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating product price', e, stackTrace);
      rethrow;
    }
  }

  Future<List<String>> getVendorProductCategories() async {
    try {
      final response = await dio.get('/vendor/products/categories');
      // Backend artık ApiResponse<T> formatında döndürüyor
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
      // Eski format (direkt liste)
      return List<String>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching vendor product categories',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<String> uploadProductImage(dynamic file) async {
    try {
      final formData = FormData.fromMap({'file': file});

      final response = await dio.post('/upload', data: formData);
      return response.data['data']['url'];
    } catch (e, stackTrace) {
      LoggerService().error('Error uploading product image', e, stackTrace);
      rethrow;
    }
  }

  // Vendor Profile Management Methods
  Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await dio.get(
        '/vendor/profile',
        options: Options(
          validateStatus: (status) {
            return status! < 500; // 404 dahil tüm 500 altı kodları kabul et
          },
        ),
      );

      if (response.statusCode == 404) {
        return {}; // Profil yoksa boş map dön
      }
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
                  >, // VendorProfileDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(apiResponse.message ?? 'Satıcı profili getirilemedi');
        }

        return apiResponse.data!;
      }
      // Eski format (direkt VendorProfileDto)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/vendor/profile', data: data);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Satıcı profili güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorImage(String imageUrl) async {
    try {
      final response = await dio.put(
        '/vendor/profile/image',
        data: {'imageUrl': imageUrl},
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
            apiResponse.message ?? 'Satıcı profil resmi güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor image', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateBusyStatus(int status) async {
    try {
      final response = await dio.put(
        '/vendor/profile/settings/status',
        data: {'busyStatus': status},
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Satıcı yoğunluk durumu güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating busy status', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorSettings() async {
    try {
      final response = await dio.get('/vendor/profile/settings');
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
                  >, // VendorSettingsDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı ayarları getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      // Eski format (direkt VendorSettingsDto)
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor settings', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorSettings(Map<String, dynamic> data) async {
    try {
      final response = await dio.put('/vendor/profile/settings', data: data);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Satıcı ayarları güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor settings', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleVendorActive(bool isActive) async {
    try {
      final response = await dio.put(
        '/vendor/profile/settings/active',
        data: {'isActive': isActive},
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
            apiResponse.message ?? 'Satıcı aktiflik durumu güncellenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error toggling vendor active', e, stackTrace);
      rethrow;
    }
  }

  // Unused helper removed

  // Legal documents methods
  Future<Map<String, dynamic>> getLegalContent(
    String type,
    String langCode,
  ) async {
    try {
      final response = await dio.get(
        '/content/legal/$type',
        queryParameters: {'lang': langCode},
      );
      // Backend artık ApiResponse<T> formatında döndürüyor
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            json
                as Map<
                  String,
                  dynamic
                >, // Legal document direkt Map olarak döndürüyoruz
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

  // Vendor notifications
  Future<List<dynamic>> getVendorNotifications() async {
    try {
      final response = await dio.get('/vendor/notifications');
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
                  >, // VendorNotificationResponseDto direkt Map olarak döndürüyoruz
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Satıcı bildirimleri getirilemedi',
          );
        }

        // VendorNotificationResponseDto içindeki 'items' alanını döndür
        return apiResponse.data!['items'] ?? [];
      }
      // Eski format (direkt VendorNotificationResponseDto)
      return response.data['items'] ?? [];
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching vendor notifications',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String type, String id) async {
    try {
      final endpoint = type == 'vendor'
          ? '/vendor/notifications/$id/read'
          : type == 'customer'
          ? '/customer/notifications/$id/read'
          : '/courier/notifications/$id/read';
      final response = await dio.post(endpoint);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ?? 'Bildirim okundu olarak işaretlenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error marking notification as read',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead(String type) async {
    try {
      final endpoint = type == 'vendor'
          ? '/vendor/notifications/read-all'
          : type == 'customer'
          ? '/customer/notifications/read-all'
          : '/courier/notifications/read-all';
      final response = await dio.post(endpoint);
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>?,
        );

        if (!apiResponse.success) {
          throw Exception(
            apiResponse.message ??
                'Tüm bildirimler okundu olarak işaretlenemedi',
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error marking all notifications as read',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Delivery Zones
  Future<dynamic> getDeliveryZones({String? cityId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (cityId != null) {
        queryParams['cityId'] = cityId;
      }

      final response = await dio.get(
        '/vendor/delivery-zones',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json, // Data is dynamic (List or Object)
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Failed to load zones');
      }

      // If cityId is null, we expect List<LocationItem>
      // If cityId is set, we expect CityZoneDto
      if (cityId == null) {
        return (apiResponse.data as List)
            .map((e) => LocationItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return CityZoneDto.fromJson(apiResponse.data as Map<String, dynamic>);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching delivery zones', e, stackTrace);
      rethrow;
    }
  }

  Future<void> syncDeliveryZones(DeliveryZoneSyncDto dto) async {
    try {
      final response = await dio.put(
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
    } catch (e, stackTrace) {
      LoggerService().error('Error syncing delivery zones', e, stackTrace);
      rethrow;
    }
  }
}

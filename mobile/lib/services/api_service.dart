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
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/features/coupons/data/models/coupon.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/settings/data/models/version_settings_model.dart';
import 'package:mobile/features/orders/data/models/order_calculation_models.dart';
import 'package:mobile/features/wallet/data/models/wallet_model.dart';
import 'package:mobile/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:mobile/features/wallet/data/models/bank_account_model.dart';
import 'package:mobile/features/wallet/data/models/withdrawal_request_model.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mobile/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:mobile/features/vendors/data/datasources/vendor_remote_data_source.dart';
import 'package:mobile/features/cart/data/datasources/cart_remote_data_source.dart';
import 'package:mobile/features/common/data/datasources/location_remote_data_source.dart';
import 'package:mobile/features/reviews/data/datasources/review_remote_data_source.dart';
import 'package:mobile/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:mobile/features/profile/data/datasources/user_remote_data_source.dart';

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
    this._cartRemoteDataSource,
    this._locationRemoteDataSource,
    this._reviewRemoteDataSource,
    this._notificationRemoteDataSource,
    this._userRemoteDataSource,
    this._cacheService,
  );

  final NetworkClient _networkClient;
  final AuthRemoteDataSource _authRemoteDataSource;
  final ProductRemoteDataSource _productRemoteDataSource;
  final OrderRemoteDataSource _orderRemoteDataSource;
  final VendorRemoteDataSource _vendorRemoteDataSource;
  final CartRemoteDataSource _cartRemoteDataSource;
  final LocationRemoteDataSource _locationRemoteDataSource;
  final ReviewRemoteDataSource _reviewRemoteDataSource;
  final NotificationRemoteDataSource _notificationRemoteDataSource;
  final UserRemoteDataSource _userRemoteDataSource;
  final CacheService _cacheService;
  Map<String, String>? _cachedSystemSettings;
  List<dynamic>? _cachedAddresses;
  final Map<String, List<Campaign>> _cachedCampaigns = {};

  Dio get dio => _networkClient.dio;
  static const String baseUrl = NetworkClient.baseUrl;
  void notifyLogout() => _networkClient.notifyLogout();
  void resetLogout() => _networkClient.resetLogout();

  // Legacy body placeholder

  Future<List<Vendor>> getVendors({
    int? vendorType,
    int page = 1,
    int pageSize = 6,
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      final vendors = await _vendorRemoteDataSource.getVendors(
        vendorType: vendorType,
        page: page,
        pageSize: pageSize,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
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
          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
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
          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
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
    double? userLatitude,
    double? userLongitude,
  }) async {
    try {
      return await _productRemoteDataSource.getPopularProducts(
        page: page,
        pageSize: pageSize,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
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
      return await _locationRemoteDataSource.getCountries();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching countries', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationCities(String countryId) async {
    try {
      return await _locationRemoteDataSource.getLocationCities(countryId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cities', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationDistricts(String cityId) async {
    try {
      return await _locationRemoteDataSource.getLocationDistricts(cityId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching districts', e, stackTrace);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLocationLocalities(
    String districtId,
  ) async {
    try {
      return await _locationRemoteDataSource.getLocationLocalities(districtId);
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
    List<Map<String, dynamic>> items, {
    String? deliveryAddressId,
    String? paymentMethod,
    String? note,
    String? couponCode,
    String? campaignId,
  }) async {
    try {
      return await _orderRemoteDataSource.createOrder(
        vendorId,
        items,
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
        note: note,
        couponCode: couponCode,
        campaignId: campaignId,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error creating order', e, stackTrace);
      rethrow;
    }
  }

  Future<OrderCalculationResult> calculateOrder(
    CalculateOrderRequest request,
  ) async {
    try {
      final response = await dio.post(
        '/orders/calculate',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => OrderCalculationResult.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Hesaplama yapılamadı');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error calculating order', e, stackTrace);
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

  Future<void> deleteAccount() {
    return _authRemoteDataSource.deleteAccount();
  }

  Future<List<CustomerNotification>> getCustomerNotifications() async {
    try {
      return await _notificationRemoteDataSource.getCustomerNotifications();
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
  // Cart methods
  Future<Map<String, dynamic>> getCart() async {
    try {
      return await _cartRemoteDataSource.getCart();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCartPromotions({
    String? couponCode,
    String? campaignId,
  }) async {
    try {
      await _cartRemoteDataSource.updateCartPromotions(
        couponCode: couponCode,
        campaignId: campaignId,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error updating cart promotions', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCartPromotions() async {
    try {
      await _cartRemoteDataSource.clearCartPromotions();
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart promotions', e, stackTrace);
      rethrow;
    }
  }

  Future<void> addToCart(
    String productId,
    int quantity, {
    List<Map<String, dynamic>>? selectedOptions,
  }) async {
    try {
      await _cartRemoteDataSource.addToCart(
        productId,
        quantity,
        selectedOptions: selectedOptions,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error adding to cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCartItem(String itemId, int quantity) async {
    try {
      await _cartRemoteDataSource.updateCartItem(itemId, quantity);
    } catch (e, stackTrace) {
      LoggerService().error('Error updating cart item', e, stackTrace);
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartRemoteDataSource.clearCart();
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart', e, stackTrace);
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      await _cartRemoteDataSource.removeFromCart(itemId);
    } catch (e, stackTrace) {
      LoggerService().error('Error removing from cart', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecommendations({
    int? type,
    double? lat,
    double? lon,
  }) async {
    try {
      final apiResponse = await _cartRemoteDataSource.getRecommendations(
        type: type,
        lat: lat,
        lon: lon,
      );

      final products =
          (apiResponse.data as List?)
              ?.map((e) => Product.fromJson(e))
              .toList() ??
          [];
      return {'products': products, 'message': apiResponse.message};
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching recommendations', e, stackTrace);
      return {'products': <Product>[], 'message': null};
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
          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
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
    if (_cachedAddresses != null) {
      return _cachedAddresses!;
    }
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

        _cachedAddresses = apiResponse.data!;
        return _cachedAddresses!;
      }
      // Eski format (direkt liste)
      _cachedAddresses = response.data as List;
      return _cachedAddresses!;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching addresses', e, stackTrace);
      rethrow;
    }
  }

  Future<void> createAddress(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/addresses', data: data);
      _cachedAddresses = null; // Invalidate cache
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
      _cachedAddresses = null; // Invalidate cache
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
      _cachedAddresses = null; // Invalidate cache
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
        ApiEndpoints.favorites,
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

  // Notification settings methods
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      return await _notificationRemoteDataSource.getNotificationSettings();
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
      await _notificationRemoteDataSource.updateNotificationSettings(data);
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error updating notification settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> addToFavorites(String productId) async {
    try {
      final response = await dio.post('${ApiEndpoints.favorites}/$productId');
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
      final response = await dio.delete('${ApiEndpoints.favorites}/$productId');
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
      final response = await dio.get(
        '${ApiEndpoints.favoriteCheck}/$productId',
      );
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

  // System Settings
  Future<Map<String, String>> getSystemSettings() async {
    if (_cachedSystemSettings != null) {
      return _cachedSystemSettings!;
    }
    try {
      final response = await dio.get('/system-settings');
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        Map<String, String> settings = {};
        // Check if wrapped in ApiResponse (just in case future changes)
        if (data.containsKey('success') && data.containsKey('data')) {
          final apiData = data['data'];
          if (apiData is Map<String, dynamic>) {
            settings = Map<String, String>.from(
              apiData.map((key, value) => MapEntry(key, value.toString())),
            );
          }
        } else {
          // Assume raw map
          settings = Map<String, String>.from(
            data.map((key, value) => MapEntry(key, value.toString())),
          );
        }
        _cachedSystemSettings = settings;
        return settings;
      }
      return {};
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching system settings', e, stackTrace);
      return {};
    }
  }

  void clearSettingsCache() {
    _cachedSystemSettings = null;
  }

  Future<VersionSettingsModel?> getVersionSettings() async {
    try {
      final response = await _networkClient.get(
        '/system-settings/version-check',
      );
      if (response != null) {
        return VersionSettingsModel.fromJson(response);
      }
      return null;
    } catch (e) {
      LoggerService().error('Failed to fetch version settings', e);
      return null;
    }
  }

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

  // Coupons & Campaigns
  Future<List<Campaign>> getCampaigns({
    int? vendorType,
    String? cityId,
    String? districtId,
  }) async {
    final cacheKey = '${vendorType}_${cityId}_$districtId';
    if (_cachedCampaigns.containsKey(cacheKey)) {
      return _cachedCampaigns[cacheKey]!;
    }
    try {
      final queryParams = <String, dynamic>{};
      if (vendorType != null) queryParams['vendorType'] = vendorType;
      if (cityId != null) queryParams['cityId'] = cityId;
      if (districtId != null) queryParams['districtId'] = districtId;

      final response = await dio.get(
        '/campaigns',
        queryParameters: queryParams,
      );
      if (response.data is List) {
        final campaigns = (response.data as List)
            .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
            .toList();
        _cachedCampaigns[cacheKey] = campaigns;
        return campaigns;
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching campaigns', e, stackTrace);
      return [];
    }
  }

  Future<Campaign?> getCampaign(String id) async {
    try {
      final response = await dio.get('/campaigns/$id');
      if (response.data is Map<String, dynamic>) {
        if (response.data.containsKey('data')) {
          return Campaign.fromJson(
            response.data['data'] as Map<String, dynamic>,
          );
        }
        return Campaign.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching campaign $id', e, stackTrace);
      return null;
    }
  }

  Future<List<Product>> getCampaignProducts(String campaignId) async {
    try {
      final response = await dio.get('/campaigns/$campaignId/products');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching campaign products', e, stackTrace);
      return [];
    }
  }

  Future<List<Coupon>> getCoupons() async {
    try {
      final response = await dio.get('/coupons');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching coupons', e, stackTrace);
      return [];
    }
  }

  Future<Coupon?> validateCoupon(
    String code, {
    String? cityId,
    String? districtId,
  }) async {
    try {
      final data = <String, dynamic>{'code': code};
      if (cityId != null) data['cityId'] = cityId;
      if (districtId != null) data['districtId'] = districtId;

      final response = await dio.post(
        '/coupons/validate',
        data: data,
        options: Options(contentType: Headers.jsonContentType),
      );
      if (response.data != null) {
        return Coupon.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e, stackTrace) {
      LoggerService().error('Error validating coupon', e, stackTrace);
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        // Return null or throw specific error message from backend
        final msg = e.response?.data['message'] ?? 'Geçersiz kupon';
        throw Exception(msg);
      }
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
        ApiEndpoints.productSearch,
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
    double? userLatitude,
    double? userLongitude,
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
      if (userLatitude != null && userLongitude != null) {
        queryParams['userLatitude'] = userLatitude;
        queryParams['userLongitude'] = userLongitude;
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
          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
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
      return await _locationRemoteDataSource.getCities(
        page: page,
        pageSize: pageSize,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching cities', e, stackTrace);
      rethrow;
    }
  }

  Future<List<AutocompleteResultDto>> autocomplete(String query) async {
    try {
      final results = await _locationRemoteDataSource.autocomplete(query);
      return results.map((e) => AutocompleteResultDto.fromJson(e)).toList();
    } catch (e, stackTrace) {
      LoggerService().error('Error during autocomplete', e, stackTrace);
      rethrow;
    }
  }

  // Map and location methods
  Future<String> getGoogleMapsApiKey() async {
    try {
      return await _locationRemoteDataSource.getGoogleMapsApiKey();
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
      return await _vendorRemoteDataSource.getVendorsForMap(
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendors for map', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    try {
      return await _locationRemoteDataSource.getDeliveryTracking(orderId);
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
      await _locationRemoteDataSource.updateCourierLocation(
        courierId,
        latitude,
        longitude,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error updating courier location', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourierLocation(String courierId) async {
    try {
      return await _locationRemoteDataSource.getCourierLocation(courierId);
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
      return await _reviewRemoteDataSource.createReview(
        targetId,
        targetType,
        rating,
        comment,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error creating review', e, stackTrace);
      rethrow;
    }
  }

  Future<ProductReviewsSummary> getProductReviews(String productId) async {
    try {
      final reviews = await _reviewRemoteDataSource.getProductReviews(
        productId,
      );

      if (reviews.isEmpty) {
        return ProductReviewsSummary(
          averageRating: 0.0,
          totalRatings: 0,
          totalComments: 0,
          reviews: [],
        );
      }

      final avgRating =
          reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

      return ProductReviewsSummary(
        averageRating: avgRating,
        totalRatings: reviews.length,
        totalComments: reviews.where((r) => r.comment.isNotEmpty).length,
        reviews: reviews,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching product reviews', e, stackTrace);
      return ProductReviewsSummary(
        averageRating: 0.0,
        totalRatings: 0,
        totalComments: 0,
        reviews: [],
      );
    }
  }

  Future<List<Review>> getVendorReviews(String vendorId) async {
    try {
      return await _reviewRemoteDataSource.getVendorReviews(vendorId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<bool> canReviewProduct(String productId) async {
    try {
      final response = await dio.get('/reviews/can-review/$productId');
      return response.data['data'] as bool;
    } catch (e, stackTrace) {
      LoggerService().error('Error checking review eligibility', e, stackTrace);
      return false;
    }
  }

  Future<List<Review>> getUserReviews() async {
    try {
      return await _reviewRemoteDataSource.getUserReviews();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching user reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Review>> getPendingReviews() async {
    try {
      return await _reviewRemoteDataSource.getPendingReviews();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching pending reviews', e, stackTrace);
      rethrow;
    }
  }

  Future<Review> getReviewById(String reviewId) async {
    try {
      return await _reviewRemoteDataSource.getReview(reviewId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching review', e, stackTrace);
      rethrow;
    }
  }

  Future<void> approveReview(String reviewId) async {
    try {
      await _reviewRemoteDataSource.approveReview(reviewId);
    } catch (e, stackTrace) {
      LoggerService().error('Error approving review', e, stackTrace);
      rethrow;
    }
  }

  Future<void> rejectReview(String reviewId) async {
    try {
      await _reviewRemoteDataSource.rejectReview(reviewId);
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
      return await _userRemoteDataSource.getUserPreferences();
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
      await _userRemoteDataSource.updateUserPreferences(
        language: language,
        currency: currency,
        timeZone: timeZone,
        dateFormat: dateFormat,
        timeFormat: timeFormat,
      );
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
      return await _vendorRemoteDataSource.getVendorOrders(
        // Note: VendorRemoteDataSource needs update to support search params if missing
        status: status,
        page: page ?? 1,
        pageSize: pageSize ?? 20,
      );
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
      return await _orderRemoteDataSource.getVendorOrdersWithCount(
        status: status,
        page: page ?? 1,
        pageSize: pageSize ?? 20,
      );
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
      return await _orderRemoteDataSource.getVendorOrder(orderId);
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
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        try {
          if (e.response?.data is Map<String, dynamic>) {
            final data = e.response?.data as Map<String, dynamic>;
            final message = data['message'] ?? (data['errors']?.toString());

            if (message != null) {
              throw Exception(message);
            }
          }
        } catch (_) {}
        throw Exception(
          e.response?.data['message'] ?? 'Kurye atama işlemi başarısız',
        );
      }
      LoggerService().error(
        'Error auto-assigning courier',
        e,
        StackTrace.current,
      );
      rethrow;
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

  Future<List<Map<String, dynamic>>> getHourlySales() async {
    try {
      final response = await dio.get('/vendor/reports/hourly-sales');
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
            apiResponse.message ?? 'Saatlik satış raporu getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching hourly sales', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardAlerts() async {
    try {
      final response = await dio.get('/vendor/reports/alerts');
      // Backend artık ApiResponse<T> formatında döndürüyor
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('success')) {
        final apiResponse = ApiResponse.fromJson(
          response.data as Map<String, dynamic>,
          (json) => json as Map<String, dynamic>,
        );

        if (!apiResponse.success || apiResponse.data == null) {
          throw Exception(
            apiResponse.message ?? 'Dashboard uyarıları getirilemedi',
          );
        }

        return apiResponse.data!;
      }
      return response.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching dashboard alerts', e, stackTrace);
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
      return await _vendorRemoteDataSource.getVendorProductCategories();
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
      return await _vendorRemoteDataSource.getVendorProfile();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    try {
      await _vendorRemoteDataSource.updateVendorProfile(data);
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor profile', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorImage(String imageUrl) async {
    try {
      await _vendorRemoteDataSource.updateVendorImage(imageUrl);
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor image', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateBusyStatus(int status) async {
    try {
      // API expects bool for isBusy, checks status == 1
      await _vendorRemoteDataSource.updateVendorBusyStatus(status == 1);
    } catch (e, stackTrace) {
      LoggerService().error('Error updating busy status', e, stackTrace);
      rethrow;
    }
  }

  Future<void> updateVendorSettings(Map<String, dynamic> data) async {
    try {
      await _vendorRemoteDataSource.updateVendorSettings(data);
    } catch (e, stackTrace) {
      LoggerService().error('Error updating vendor settings', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleVendorActive(bool isActive) async {
    try {
      await _vendorRemoteDataSource.toggleVendorActive(isActive);
    } catch (e, stackTrace) {
      LoggerService().error('Error toggling vendor active', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorSettings() async {
    try {
      return await _vendorRemoteDataSource.getVendorSettings();
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching vendor settings', e, stackTrace);
      rethrow;
    }
  }

  // Legal documents methods
  Future<Map<String, dynamic>> getLegalContent(
    String type,
    String langCode,
  ) async {
    try {
      return await _locationRemoteDataSource.getLegalContent(type, langCode);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching legal content', e, stackTrace);
      rethrow;
    }
  }

  // Vendor notifications
  Future<List<dynamic>> getVendorNotifications() async {
    try {
      return await _vendorRemoteDataSource.getVendorNotifications();
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
      await _vendorRemoteDataSource.markNotificationAsRead(type, id);
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
      await _vendorRemoteDataSource.markAllNotificationsAsRead(type);
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
      return await _vendorRemoteDataSource.getDeliveryZones(cityId: cityId);
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching delivery zones', e, stackTrace);
      rethrow;
    }
  }

  Future<void> syncDeliveryZones(DeliveryZoneSyncDto dto) async {
    try {
      await _vendorRemoteDataSource.syncDeliveryZones(dto);
    } catch (e, stackTrace) {
      LoggerService().error('Error syncing delivery zones', e, stackTrace);
      rethrow;
    }
  }

  Future<void> submitOrderFeedback(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('/reviews/order-feedback', data: data);

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Feedback submission failed');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error submitting feedback', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderReviewStatus(String orderId) async {
    try {
      final response = await dio.get('/reviews/order-status/$orderId');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return apiResponse.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching order review status',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUnreviewedOrder() async {
    try {
      final response = await dio.get('/reviews/unreviewed');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );
      return apiResponse.data;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching unreviewed order', e, stackTrace);
      return null;
    }
  }

  // System Settings
  Future<String?> getSystemSetting(String key) async {
    try {
      final response = await _networkClient.get('/system-settings/$key');
      if (response != null && response['value'] != null) {
        return response['value'].toString();
      }
      return null;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching system setting $key',
        e,
        stackTrace,
      );
      return null;
    }
  }

  // Wallet methods
  Future<Wallet> getWallet() async {
    try {
      final response = await dio.get('/wallet');

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => Wallet.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Cüzdan bulunamadı');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching wallet', e, stackTrace);
      rethrow;
    }
  }

  Future<List<WalletTransaction>> getWalletTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        '/wallet/transactions',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List)
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'İşlemler alınamadı');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching wallet transactions',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<WalletTransaction> deposit(double amount) async {
    try {
      final response = await dio.post(
        '/wallet/deposit',
        data: {'amount': amount},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WalletTransaction.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Para yüklenemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error depositing to wallet', e, stackTrace);
      rethrow;
    }
  }

  Future<WalletTransaction> withdraw(double amount, String iban) async {
    try {
      final response = await dio.post(
        '/wallet/withdraw',
        data: {'amount': amount, 'iban': iban},
      );

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WalletTransaction.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(
          apiResponse.message ?? 'Para çekme talebi oluşturulamadı',
        );
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error withdrawing from wallet', e, stackTrace);
      rethrow;
    }
  }

  // Bank Account Management
  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final response = await dio.get('/bankaccount');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) =>
            (json as List).map((item) => BankAccount.fromJson(item)).toList(),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Banka hesapları getirilemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error fetching bank accounts', e, stackTrace);
      rethrow;
    }
  }

  Future<BankAccount> addBankAccount(CreateBankAccountRequest request) async {
    try {
      final response = await dio.post('/bankaccount', data: request.toJson());
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BankAccount.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Banka hesabı eklenemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error adding bank account', e, stackTrace);
      rethrow;
    }
  }

  Future<BankAccount> updateBankAccount(
    UpdateBankAccountRequest request,
  ) async {
    try {
      final response = await dio.put('/bankaccount', data: request.toJson());
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => BankAccount.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Banka hesabı güncellenemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error updating bank account', e, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteBankAccount(String id) async {
    try {
      final response = await dio.delete('/bankaccount/$id');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Banka hesabı silinemedi');
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error deleting bank account', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setDefaultBankAccount(String id) async {
    try {
      final response = await dio.post('/bankaccount/$id/default');
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json,
      );

      if (!apiResponse.success) {
        throw Exception(apiResponse.message ?? 'Varsayılan hesap ayarlanamadı');
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error setting default bank account',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Withdrawal Requests
  Future<List<WithdrawalRequest>> getWithdrawalRequests({
    WithdrawalStatus? status,
  }) async {
    try {
      final response = await dio.get(
        '/withdrawal/requests',
        queryParameters: status != null ? {'status': status.index} : null,
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => (json as List)
            .map((item) => WithdrawalRequest.fromJson(item))
            .toList(),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Talepler getirilemedi');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error fetching withdrawal requests',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<WithdrawalRequest> createWithdrawalRequest(
    CreateWithdrawalRequestParams params,
  ) async {
    try {
      final response = await dio.post(
        '/withdrawal/request',
        data: params.toJson(),
      );
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => WithdrawalRequest.fromJson(json as Map<String, dynamic>),
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Talep oluşturulamadı');
      }

      return apiResponse.data!;
    } catch (e, stackTrace) {
      LoggerService().error('Error creating withdrawal request', e, stackTrace);
      rethrow;
    }
  }
}

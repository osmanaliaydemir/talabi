import 'dart:async';
import 'package:dio/dio.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://talabi.runasp.net/api';
  static ApiService? _instance;
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  final CacheService _cacheService = CacheService();
  ConnectivityService? _connectivityService;

  // Track refresh token operation to prevent concurrent calls
  bool _isRefreshing = false;
  Completer<Map<String, String>>? _refreshCompleter;

  void setConnectivityService(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
  }

  // Singleton pattern
  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  ApiService._internal() {
    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Automatically add token from SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          print('📤 [HTTP REQUEST] ${options.method} ${options.uri}');
          print('📤 [HTTP REQUEST] Headers: ${options.headers}');
          print('📤 [HTTP REQUEST] Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '📥 [HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('📥 [HTTP RESPONSE] Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print(
            '❌ [HTTP ERROR] ${error.requestOptions.method} ${error.requestOptions.uri}',
          );
          print('❌ [HTTP ERROR] Status: ${error.response?.statusCode}');
          print('❌ [HTTP ERROR] Message: ${error.message}');
          print('❌ [HTTP ERROR] Response: ${error.response?.data}');

          // Handle 401 Unauthorized - Refresh Token Logic
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('login') &&
              !error.requestOptions.path.contains('refresh-token')) {
            print('🔄 [REFRESH TOKEN] 401 detected. Attempting to refresh...');

            try {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              final refreshToken = prefs.getString('refreshToken');

              if (token != null && refreshToken != null) {
                Map<String, String> newTokens;

                // If already refreshing, wait for the existing refresh to complete
                if (_isRefreshing && _refreshCompleter != null) {
                  print('🔄 [REFRESH TOKEN] Already refreshing, waiting...');
                  newTokens = await _refreshCompleter!.future;
                } else {
                  // Start new refresh operation
                  _isRefreshing = true;
                  _refreshCompleter = Completer<Map<String, String>>();

                  try {
                    newTokens = await _refreshToken(token, refreshToken);

                    // Update tokens in SharedPreferences
                    await prefs.setString('token', newTokens['token']!);
                    await prefs.setString(
                      'refreshToken',
                      newTokens['refreshToken']!,
                    );

                    _refreshCompleter!.complete(newTokens);
                  } catch (e) {
                    _refreshCompleter!.completeError(e);
                    rethrow;
                  } finally {
                    _isRefreshing = false;
                    _refreshCompleter = null;
                  }
                }

                // Retry the original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] =
                    'Bearer ${newTokens['token']!}';

                final cloneReq = await _dio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: Options(
                    method: options.method,
                    headers: options.headers,
                  ),
                );

                return handler.resolve(cloneReq);
              }
            } catch (e) {
              print('🔴 [REFRESH TOKEN] Failed: $e');
              _isRefreshing = false;
              _refreshCompleter = null;
              // If refresh fails, let the error propagate (user will be logged out by AuthProvider)
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, String>> _refreshToken(
    String token,
    String refreshToken,
  ) async {
    // Create a separate Dio instance to avoid interceptor loops
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    final response = await dio.post(
      '/auth/refresh-token',
      data: {'token': token, 'refreshToken': refreshToken},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'token': data['token'] as String,
      'refreshToken': data['refreshToken'] as String,
    };
  }

  Future<List<Vendor>> getVendors() async {
    try {
      // Try network first
      final response = await _dio.get('/vendors');
      final List<dynamic> data = response.data;
      final vendors = data.map((json) => Vendor.fromJson(json)).toList();

      // Cache the result
      await _cacheService.cacheVendors(vendors);

      return vendors;
    } on DioException catch (e) {
      print('Error fetching vendors: $e');

      // If offline or network error, try cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedVendors = await _cacheService.getCachedVendors();
        if (cachedVendors != null && cachedVendors.isNotEmpty) {
          print('📦 [CACHE] Returning cached vendors');
          return cachedVendors;
        }
      }

      rethrow;
    } catch (e) {
      print('Error fetching vendors: $e');
      rethrow;
    }
  }

  Future<List<Product>> getProducts(int vendorId) async {
    try {
      // Try network first
      final response = await _dio.get('/vendors/$vendorId/products');
      final List<dynamic> data = response.data;
      final products = data.map((json) => Product.fromJson(json)).toList();

      // Cache the result
      await _cacheService.cacheProducts(products);

      return products;
    } on DioException catch (e) {
      print('Error fetching products: $e');

      // If offline or network error, try cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedProducts = await _cacheService.getCachedProducts();
        if (cachedProducts != null && cachedProducts.isNotEmpty) {
          print('📦 [CACHE] Returning cached products');
          return cachedProducts;
        }
      }

      rethrow;
    } catch (e) {
      print('Error fetching products: $e');
      rethrow;
    }
  }

  Future<List<Product>> getPopularProducts({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/products/popular',
        queryParameters: {'limit': limit},
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching popular products: $e');
      rethrow;
    }
  }

  Future<Product> getProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      return Product.fromJson(response.data);
    } catch (e) {
      print('Error fetching product: $e');
      rethrow;
    }
  }

  Future<Order> createOrder(int vendorId, Map<int, int> items) async {
    try {
      final orderItems = items.entries
          .map((e) => {'productId': e.key, 'quantity': e.value})
          .toList();

      final response = await _dio.post(
        '/orders',
        data: {'vendorId': vendorId, 'items': orderItems},
      );

      return Order.fromJson(response.data);
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      print('🔵 [REGISTER] Starting registration...');
      print('🔵 [REGISTER] URL: $baseUrl/auth/register');
      print('🔵 [REGISTER] Email: $email');
      print('🔵 [REGISTER] FullName: $fullName');
      print('🔵 [REGISTER] Password length: ${password.length}');

      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
      };
      print('🔵 [REGISTER] Request data: $requestData');

      final response = await _dio.post('/auth/register', data: requestData);

      print('🟢 [REGISTER] Success! Status: ${response.statusCode}');
      print('🟢 [REGISTER] Response data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('🔴 [REGISTER] DioException occurred!');
      print('🔴 [REGISTER] Error type: ${e.type}');
      print('🔴 [REGISTER] Error message: ${e.message}');
      print('🔴 [REGISTER] Request path: ${e.requestOptions.path}');
      print('🔴 [REGISTER] Request data: ${e.requestOptions.data}');
      print('🔴 [REGISTER] Response status: ${e.response?.statusCode}');
      print('🔴 [REGISTER] Response data: ${e.response?.data}');
      print('🔴 [REGISTER] Stack trace: ${e.stackTrace}');

      if (e.response != null) {
        final responseData = e.response?.data;
        String errorMessage = 'Unknown error';

        // Handle array response (ASP.NET Identity format)
        if (responseData is List && responseData.isNotEmpty) {
          final firstError = responseData[0];
          if (firstError is Map) {
            errorMessage =
                firstError['description'] ??
                firstError['message'] ??
                firstError['error'] ??
                firstError.toString();
          } else {
            errorMessage = firstError.toString();
          }
        }
        // Handle object response
        else if (responseData is Map) {
          errorMessage =
              responseData['description'] ??
              responseData['message'] ??
              responseData['error'] ??
              responseData.toString();
        }
        // Handle string response
        else if (responseData is String) {
          errorMessage = responseData;
        }
        // Fallback
        else {
          errorMessage =
              responseData?.toString() ?? e.message ?? 'Unknown error';
        }

        print('🔴 [REGISTER] Parsed error message: $errorMessage');
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      print('🔴 [REGISTER] Unexpected error: $e');
      print('🔴 [REGISTER] Stack trace: $stackTrace');
      rethrow;
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      print('Error sending forgot password request: $e');
      rethrow;
    }
  }

  Future<void> confirmEmail(String token, String email) async {
    try {
      await _dio.get(
        '/auth/confirm-email',
        queryParameters: {'token': token, 'email': email},
      );
    } catch (e) {
      print('Error confirming email: $e');
      rethrow;
    }
  }

  // Cart methods
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _dio.get('/cart');
      return response.data;
    } catch (e) {
      print('Error fetching cart: $e');
      rethrow;
    }
  }

  Future<void> addToCart(int productId, int quantity) async {
    try {
      await _dio.post(
        '/cart/items',
        data: {'productId': productId, 'quantity': quantity},
      );
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateCartItem(int itemId, int quantity) async {
    try {
      await _dio.put('/cart/items/$itemId', data: {'quantity': quantity});
    } catch (e) {
      print('Error updating cart item: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(int itemId) async {
    try {
      await _dio.delete('/cart/items/$itemId');
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete('/cart');
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }

  // Profile methods
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Try network first
      final response = await _dio.get('/profile');
      final profile = response.data as Map<String, dynamic>;

      // Cache the result
      await _cacheService.cacheProfile(profile);

      return profile;
    } on DioException catch (e) {
      print('Error fetching profile: $e');

      // If offline or network error, try cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedProfile = await _cacheService.getCachedProfile();
        if (cachedProfile != null) {
          print('📦 [CACHE] Returning cached profile');
          return cachedProfile;
        }
      }

      rethrow;
    } catch (e) {
      print('Error fetching profile: $e');
      rethrow;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/profile', data: data);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await _dio.put(
        '/profile/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (e) {
      print('Error changing password: $e');
      rethrow;
    }
  }

  // Address methods
  Future<List<dynamic>> getAddresses() async {
    try {
      final response = await _dio.get('/addresses');
      return response.data;
    } catch (e) {
      print('Error fetching addresses: $e');
      rethrow;
    }
  }

  Future<void> createAddress(Map<String, dynamic> data) async {
    try {
      await _dio.post('/addresses', data: data);
    } catch (e) {
      print('Error creating address: $e');
      rethrow;
    }
  }

  Future<void> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/addresses/$id', data: data);
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      await _dio.delete('/addresses/$id');
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(int id) async {
    try {
      await _dio.put('/addresses/$id/set-default');
    } catch (e) {
      print('Error setting default address: $e');
      rethrow;
    }
  }

  // Favorites methods
  Future<List<dynamic>> getFavorites() async {
    try {
      final response = await _dio.get('/favorites');
      return response.data;
    } catch (e) {
      print('Error fetching favorites: $e');
      rethrow;
    }
  }

  Future<void> addToFavorites(int productId) async {
    try {
      await _dio.post('/favorites/$productId');
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(int productId) async {
    try {
      await _dio.delete('/favorites/$productId');
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(int productId) async {
    try {
      final response = await _dio.get('/favorites/check/$productId');
      return response.data['isFavorite'];
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Notification settings methods
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get('/notifications/settings');
      return response.data;
    } catch (e) {
      print('Error fetching notification settings: $e');
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(Map<String, dynamic> data) async {
    try {
      await _dio.put('/notifications/settings', data: data);
    } catch (e) {
      print('Error updating notification settings: $e');
      rethrow;
    }
  }

  // Orders methods
  Future<List<dynamic>> getOrders() async {
    try {
      final response = await _dio.get('/orders');
      return response.data;
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return response.data;
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetailFull(int orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/detail');
      return response.data;
    } catch (e) {
      print('Error fetching order detail: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(int orderId, String reason) async {
    try {
      await _dio.post('/orders/$orderId/cancel', data: {'reason': reason});
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  // Search and filter methods
  Future<PagedResultDto<ProductDto>> searchProducts(
    ProductSearchRequestDto request,
  ) async {
    try {
      final response = await _dio.get(
        '/products/search',
        queryParameters: request.toJson(),
      );
      return PagedResultDto.fromJson(
        response.data,
        (json) => ProductDto.fromJson(json),
      );
    } catch (e) {
      print('Error searching products: $e');
      rethrow;
    }
  }

  Future<PagedResultDto<VendorDto>> searchVendors(
    VendorSearchRequestDto request,
  ) async {
    try {
      final response = await _dio.get(
        '/vendors/search',
        queryParameters: request.toJson(),
      );
      return PagedResultDto.fromJson(
        response.data,
        (json) => VendorDto.fromJson(json),
      );
    } catch (e) {
      print('Error searching vendors: $e');
      rethrow;
    }
  }

  Future<List<String>> getCategories() async {
    try {
      // Try network first
      final response = await _dio.get('/products/categories');
      final categories = List<String>.from(response.data);

      // Cache the result
      await _cacheService.cacheCategories(categories);

      return categories;
    } on DioException catch (e) {
      print('Error fetching categories: $e');

      // If offline or network error, try cache
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedCategories = await _cacheService.getCachedCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          print('📦 [CACHE] Returning cached categories');
          return cachedCategories;
        }
      }

      rethrow;
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<List<String>> getCities() async {
    try {
      final response = await _dio.get('/vendors/cities');
      return List<String>.from(response.data);
    } catch (e) {
      print('Error fetching cities: $e');
      rethrow;
    }
  }

  Future<List<AutocompleteResultDto>> autocomplete(String query) async {
    try {
      final response = await _dio.get(
        '/search/autocomplete',
        queryParameters: {'query': query},
      );
      return (response.data as List)
          .map((e) => AutocompleteResultDto.fromJson(e))
          .toList();
    } catch (e) {
      print('Error during autocomplete: $e');
      rethrow;
    }
  }

  // Map and location methods
  Future<String> getGoogleMapsApiKey() async {
    try {
      final response = await _dio.get('/map/api-key');
      return response.data['apiKey'];
    } catch (e) {
      print('Error fetching Google Maps API key: $e');
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

      final response = await _dio.get(
        '/map/vendors',
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching vendors for map: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeliveryTracking(int orderId) async {
    try {
      final response = await _dio.get('/map/delivery-tracking/$orderId');
      return response.data;
    } catch (e) {
      print('Error fetching delivery tracking: $e');
      rethrow;
    }
  }

  // Courier location methods
  Future<void> updateCourierLocation(
    int courierId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _dio.put(
        '/courier/$courierId/location',
        data: {'latitude': latitude, 'longitude': longitude},
      );
    } catch (e) {
      print('Error updating courier location: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCourierLocation(int courierId) async {
    try {
      final response = await _dio.get('/courier/$courierId/location');
      return response.data;
    } catch (e) {
      print('Error fetching courier location: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveCouriers() async {
    try {
      final response = await _dio.get('/courier/active');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching active couriers: $e');
      rethrow;
    }
  }

  // User preferences methods
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final response = await _dio.get('/userpreferences');
      return response.data;
    } catch (e) {
      print('Error fetching user preferences: $e');
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

      await _dio.put('/userpreferences', data: data);
    } catch (e) {
      print('Error updating user preferences: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    try {
      final response = await _dio.get('/userpreferences/supported-languages');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching supported languages: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedCurrencies() async {
    try {
      final response = await _dio.get('/userpreferences/supported-currencies');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error fetching supported currencies: $e');
      rethrow;
    }
  }

  // Vendor Orders methods
  Future<List<dynamic>> getVendorOrders({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/vendor/orders',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      print('Error fetching vendor orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorOrder(int orderId) async {
    try {
      final response = await _dio.get('/vendor/orders/$orderId');
      return response.data;
    } catch (e) {
      print('Error fetching vendor order: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(int orderId) async {
    try {
      await _dio.post('/vendor/orders/$orderId/accept');
    } catch (e) {
      print('Error accepting order: $e');
      rethrow;
    }
  }

  Future<void> rejectOrder(int orderId, String reason) async {
    try {
      await _dio.post(
        '/vendor/orders/$orderId/reject',
        data: {'reason': reason},
      );
    } catch (e) {
      print('Error rejecting order: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(
    int orderId,
    String status, {
    String? note,
  }) async {
    try {
      await _dio.put(
        '/vendor/orders/$orderId/status',
        data: {'status': status, 'note': note},
      );
    } catch (e) {
      print('Error updating order status: $e');
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
      if (startDate != null)
        queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/vendor/reports/sales',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      print('Error fetching sales report: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorSummary() async {
    try {
      final response = await _dio.get('/vendor/reports/summary');
      return response.data;
    } catch (e) {
      print('Error fetching vendor summary: $e');
      rethrow;
    }
  }
}

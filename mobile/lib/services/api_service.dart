import 'dart:async';
import 'package:dio/dio.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/models/review.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/services/api_request_scheduler.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _requestPermitKey = '_apiRequestPermit';

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
  final ApiRequestScheduler _requestScheduler = ApiRequestScheduler();
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
          // Check connectivity before making request
          if (_connectivityService != null && !_connectivityService!.isOnline) {
            final isOnline = await _connectivityService!.checkConnectivity();
            if (!isOnline) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'No internet connection',
                  type: DioExceptionType.connectionError,
                ),
              );
            }
          }

          final permit = await _requestScheduler.acquire(
            highPriority: _isHighPriorityRequest(options),
          );
          options.extra[_requestPermitKey] = permit;

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
          _releasePermit(response.requestOptions);
          print(
            '📥 [HTTP RESPONSE] ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('📥 [HTTP RESPONSE] Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          _releasePermit(error.requestOptions);
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
    final permit = await _requestScheduler.acquire(highPriority: true);
    try {
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
    } finally {
      permit.release();
    }
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

  Future<List<Product>> getProducts(String vendorId) async {
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

  Future<List<PromotionalBanner>> getBanners({String? language}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (language != null) {
        queryParams['language'] = language;
      }
      final response = await _dio.get(
        '/banners',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => PromotionalBanner.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching banners: $e');
      rethrow;
    }
  }

  Future<Product> getProduct(String productId) async {
    try {
      final response = await _dio.get('/products/$productId');
      return Product.fromJson(response.data);
    } catch (e) {
      print('Error fetching product: $e');
      rethrow;
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
      final data = {
        'vendorId': vendorId,
        'items': items.entries
            .map((e) => {'productId': e.key, 'quantity': e.value})
            .toList(),
        if (deliveryAddressId != null) 'deliveryAddressId': deliveryAddressId,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (note != null) 'note': note,
      };

      final response = await _dio.post('/orders', data: data);
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
    String fullName, {
    String? language,
  }) async {
    try {
      print('🔵 [REGISTER] Starting registration...');
      print('🔵 [REGISTER] URL: $baseUrl/auth/register');
      print('🔵 [REGISTER] Email: $email');
      print('🔵 [REGISTER] FullName: $fullName');
      print('🔵 [REGISTER] Password length: ${password.length}');
      print('🔵 [REGISTER] Language: ${language ?? "not specified"}');

      final requestData = {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (language != null) 'language': language,
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

  // Vendor Registration - Creates both User and Vendor records
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
  }) async {
    try {
      print('🔵 [VENDOR_REGISTER] Starting vendor registration...');
      print('🔵 [VENDOR_REGISTER] URL: $baseUrl/auth/vendor-register');
      print('🔵 [VENDOR_REGISTER] Email: $email');
      print('🔵 [VENDOR_REGISTER] FullName: $fullName');
      print('🔵 [VENDOR_REGISTER] BusinessName: $businessName');
      print('🔵 [VENDOR_REGISTER] Phone: $phone');
      print('🔵 [VENDOR_REGISTER] Language: ${language ?? "not specified"}');

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
      };
      print('🔵 [VENDOR_REGISTER] Request data: $requestData');

      final response = await _dio.post(
        '/auth/vendor-register',
        data: requestData,
      );

      print('🟢 [VENDOR_REGISTER] Success! Status: ${response.statusCode}');
      print('🟢 [VENDOR_REGISTER] Response data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('🔴 [VENDOR_REGISTER] DioException occurred!');
      print('🔴 [VENDOR_REGISTER] Error type: ${e.type}');
      print('🔴 [VENDOR_REGISTER] Error message: ${e.message}');
      print('🔴 [VENDOR_REGISTER] Request path: ${e.requestOptions.path}');
      print('🔴 [VENDOR_REGISTER] Request data: ${e.requestOptions.data}');
      print('🔴 [VENDOR_REGISTER] Response status: ${e.response?.statusCode}');
      print('🔴 [VENDOR_REGISTER] Response data: ${e.response?.data}');

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

        print('🔴 [VENDOR_REGISTER] Parsed error message: $errorMessage');
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      print('🔴 [VENDOR_REGISTER] Unexpected error: $e');
      print('🔴 [VENDOR_REGISTER] Stack trace: $stackTrace');
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

  Future<Map<String, dynamic>> verifyEmailCode(
    String email,
    String code,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email-code',
        data: {'email': email, 'code': code},
      );
      return response.data;
    } catch (e) {
      print('Error verifying email code: $e');
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

      final response = await _dio.post(
        '/auth/resend-verification-code',
        data: requestData,
      );
      return response.data;
    } catch (e) {
      print('Error resending verification code: $e');
      rethrow;
    }
  }

  // External Login (Google, Apple, Facebook)
  Future<Map<String, dynamic>> externalLogin({
    required String provider,
    required String idToken,
    required String email,
    required String fullName,
    String? language,
  }) async {
    try {
      print('🔵 [EXTERNAL_LOGIN] Starting $provider login...');
      print('🔵 [EXTERNAL_LOGIN] Email: $email');
      print('🔵 [EXTERNAL_LOGIN] FullName: $fullName');

      final requestData = {
        'provider': provider,
        'idToken': idToken,
        'email': email,
        'fullName': fullName,
        if (language != null) 'language': language,
      };

      final response = await _dio.post(
        '/auth/external-login',
        data: requestData,
      );

      print('🟢 [EXTERNAL_LOGIN] Success! Status: ${response.statusCode}');
      print('🟢 [EXTERNAL_LOGIN] Response data: ${response.data}');

      return response.data;
    } on DioException catch (e) {
      print('🔴 [EXTERNAL_LOGIN] DioException occurred!');
      print('🔴 [EXTERNAL_LOGIN] Error type: ${e.type}');
      print('🔴 [EXTERNAL_LOGIN] Error message: ${e.message}');
      print('🔴 [EXTERNAL_LOGIN] Response status: ${e.response?.statusCode}');
      print('🔴 [EXTERNAL_LOGIN] Response data: ${e.response?.data}');

      if (e.response != null) {
        final responseData = e.response?.data;
        String errorMessage = 'Unknown error';

        if (responseData is Map) {
          errorMessage =
              responseData['message'] ??
              responseData['error'] ??
              responseData.toString();
        } else if (responseData is String) {
          errorMessage = responseData;
        }

        print('🔴 [EXTERNAL_LOGIN] Parsed error message: $errorMessage');
        throw Exception(errorMessage);
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e, stackTrace) {
      print('🔴 [EXTERNAL_LOGIN] Unexpected error: $e');
      print('🔴 [EXTERNAL_LOGIN] Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Notification methods
  Future<void> registerDeviceToken(String token, String deviceType) async {
    try {
      await _dio.post(
        '/notification/register-device',
        data: {'token': token, 'deviceType': deviceType},
      );
    } catch (e) {
      print('Error registering device token: $e');
      // Don't rethrow, just log, as this shouldn't block app usage
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

  Future<void> addToCart(String productId, int quantity) async {
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

  Future<void> updateCartItem(String itemId, int quantity) async {
    try {
      await _dio.put('/cart/items/$itemId', data: {'quantity': quantity});
    } catch (e) {
      print('Error updating cart item: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId) async {
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

  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/addresses/$id', data: data);
    } catch (e) {
      print('Error updating address: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete('/addresses/$id');
    } catch (e) {
      print('Error deleting address: $e');
      rethrow;
    }
  }

  Future<void> setDefaultAddress(String id) async {
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

  Future<void> addToFavorites(String productId) async {
    try {
      await _dio.post('/favorites/$productId');
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      await _dio.delete('/favorites/$productId');
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<bool> isFavorite(String productId) async {
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

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId');
      return response.data;
    } catch (e) {
      print('Error fetching order details: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getOrderDetailFull(String orderId) async {
    try {
      final response = await _dio.get('/orders/$orderId/detail');
      return response.data;
    } catch (e) {
      print('Error fetching order detail: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _dio.post('/orders/$orderId/cancel', data: {'reason': reason});
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }

  Future<void> cancelOrderItem(
    String customerOrderItemId,
    String reason,
  ) async {
    try {
      await _dio.post(
        '/orders/items/$customerOrderItemId/cancel',
        data: {'reason': reason},
      );
    } catch (e) {
      print('Error cancelling order item: $e');
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

  Future<List<Map<String, dynamic>>> getCategories({String? language}) async {
    try {
      // Try network first
      final response = await _dio.get(
        '/products/categories',
        queryParameters: language != null ? {'lang': language} : null,
      );
      final List<dynamic> data = response.data;
      final categories = List<Map<String, dynamic>>.from(data);

      // Cache the result
      // await _cacheService.cacheCategories(categories);

      return categories;
    } on DioException catch (e) {
      print('Error fetching categories: $e');

      // If offline or network error, try cache
      /*
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        final cachedCategories = await _cacheService.getCachedCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          print('📦 [CACHE] Returning cached categories');
          return cachedCategories;
        }
      }
      */

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

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
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
    String courierId,
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

  Future<Map<String, dynamic>> getCourierLocation(String courierId) async {
    try {
      final response = await _dio.get('/courier/$courierId/location');
      return response.data;
    } catch (e) {
      print('Error fetching courier location: $e');
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
      final response = await _dio.post(
        '/reviews',
        data: {
          'targetId': targetId,
          'targetType': targetType,
          'rating': rating,
          'comment': comment,
        },
      );
      return Review.fromJson(response.data);
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  Future<List<Review>> getProductReviews(String productId) async {
    try {
      final response = await _dio.get('/reviews/products/$productId');
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching product reviews: $e');
      rethrow;
    }
  }

  Future<List<Review>> getVendorReviews(String vendorId) async {
    try {
      final response = await _dio.get('/reviews/vendors/$vendorId');
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching vendor reviews: $e');
      rethrow;
    }
  }

  Future<List<Review>> getPendingReviews() async {
    try {
      final response = await _dio.get('/reviews/pending');
      final List<dynamic> data = response.data;
      return data.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching pending reviews: $e');
      rethrow;
    }
  }

  Future<void> approveReview(String reviewId) async {
    try {
      await _dio.patch('/reviews/$reviewId/approve');
    } catch (e) {
      print('Error approving review: $e');
      rethrow;
    }
  }

  Future<void> rejectReview(String reviewId) async {
    try {
      await _dio.patch('/reviews/$reviewId/reject');
    } catch (e) {
      print('Error rejecting review: $e');
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
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

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

  Future<Map<String, dynamic>> getVendorOrder(String orderId) async {
    try {
      final response = await _dio.get('/vendor/orders/$orderId');
      return response.data;
    } catch (e) {
      print('Error fetching vendor order: $e');
      rethrow;
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      await _dio.post('/vendor/orders/$orderId/accept');
    } catch (e) {
      print('Error accepting order: $e');
      rethrow;
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
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
    String orderId,
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

  // Get available couriers for order
  Future<List<Map<String, dynamic>>> getAvailableCouriers(
    String orderId,
  ) async {
    try {
      final response = await _dio.get(
        '/vendor/orders/$orderId/available-couriers',
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Error getting available couriers: $e');
      rethrow;
    }
  }

  // Assign courier to order
  Future<void> assignCourierToOrder(String orderId, String courierId) async {
    try {
      await _dio.post(
        '/vendor/orders/$orderId/assign-courier',
        data: {'courierId': courierId},
      );
    } catch (e) {
      print('Error assigning courier: $e');
      rethrow;
    }
  }

  // Auto-assign best courier
  Future<Map<String, dynamic>> autoAssignCourier(String orderId) async {
    try {
      final response = await _dio.post(
        '/vendor/orders/$orderId/auto-assign-courier',
      );
      return response.data;
    } catch (e) {
      print('Error auto-assigning courier: $e');
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

  // Vendor Product Management Methods
  Future<List<Product>> getVendorProducts({
    String? category,
    bool? isAvailable,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null) queryParams['category'] = category;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable;

      final response = await _dio.get(
        '/vendor/products',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching vendor products: $e');
      rethrow;
    }
  }

  Future<Product> getVendorProduct(String productId) async {
    try {
      final response = await _dio.get('/vendor/products/$productId');
      return Product.fromJson(response.data);
    } catch (e) {
      print('Error fetching vendor product: $e');
      rethrow;
    }
  }

  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/vendor/products', data: data);
      return Product.fromJson(response.data);
    } catch (e) {
      print('Error creating product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.put('/vendor/products/$productId', data: data);
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _dio.delete('/vendor/products/$productId');
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> updateProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    try {
      await _dio.put(
        '/vendor/products/$productId/availability',
        data: {'isAvailable': isAvailable},
      );
    } catch (e) {
      print('Error updating product availability: $e');
      rethrow;
    }
  }

  Future<void> updateProductPrice(String productId, double price) async {
    try {
      await _dio.put(
        '/vendor/products/$productId/price',
        data: {'price': price},
      );
    } catch (e) {
      print('Error updating product price: $e');
      rethrow;
    }
  }

  Future<List<String>> getVendorProductCategories() async {
    try {
      final response = await _dio.get('/vendor/products/categories');
      return List<String>.from(response.data);
    } catch (e) {
      print('Error fetching vendor product categories: $e');
      rethrow;
    }
  }

  Future<String> uploadProductImage(dynamic file) async {
    try {
      FormData formData = FormData.fromMap({'file': file});

      final response = await _dio.post('/upload', data: formData);
      return response.data['url'];
    } catch (e) {
      print('Error uploading product image: $e');
      rethrow;
    }
  }

  // Vendor Profile Management Methods
  Future<Map<String, dynamic>> getVendorProfile() async {
    try {
      final response = await _dio.get('/vendor/profile');
      return response.data;
    } catch (e) {
      print('Error fetching vendor profile: $e');
      rethrow;
    }
  }

  Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    try {
      await _dio.put('/vendor/profile', data: data);
    } catch (e) {
      print('Error updating vendor profile: $e');
      rethrow;
    }
  }

  Future<void> updateVendorImage(String imageUrl) async {
    try {
      await _dio.put('/vendor/profile/image', data: {'imageUrl': imageUrl});
    } catch (e) {
      print('Error updating vendor image: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getVendorSettings() async {
    try {
      final response = await _dio.get('/vendor/profile/settings');
      return response.data;
    } catch (e) {
      print('Error fetching vendor settings: $e');
      rethrow;
    }
  }

  Future<void> updateVendorSettings(Map<String, dynamic> data) async {
    try {
      await _dio.put('/vendor/profile/settings', data: data);
    } catch (e) {
      print('Error updating vendor settings: $e');
      rethrow;
    }
  }

  Future<void> toggleVendorActive(bool isActive) async {
    try {
      await _dio.put(
        '/vendor/profile/settings/active',
        data: {'isActive': isActive},
      );
    } catch (e) {
      print('Error toggling vendor active: $e');
      rethrow;
    }
  }

  bool _isHighPriorityRequest(RequestOptions options) {
    const prioritySegments = [
      '/auth/login',
      '/auth/register',
      '/auth/refresh-token',
      '/auth/confirm-email',
      '/auth/forgot-password',
    ];

    return prioritySegments.any(
      (segment) => options.path.toLowerCase().contains(segment),
    );
  }

  void _releasePermit(RequestOptions options) {
    final permit = options.extra.remove(_requestPermitKey);
    if (permit is RequestPermit) {
      permit.release();
    }
  }

  // Legal documents methods
  Future<Map<String, dynamic>> getLegalContent(
    String type,
    String langCode,
  ) async {
    try {
      final response = await _dio.get(
        '/content/legal/$type',
        queryParameters: {'lang': langCode},
      );
      return response.data;
    } catch (e) {
      print('Error fetching legal content: $e');
      rethrow;
    }
  }

  // Vendor notifications
  Future<List<dynamic>> getVendorNotifications() async {
    try {
      final response = await _dio.get('/vendor/notifications');
      return response.data['items'] ?? [];
    } catch (e) {
      print('Error fetching vendor notifications: $e');
      rethrow;
    }
  }

  // Customer notifications
  Future<List<dynamic>> getCustomerNotifications() async {
    try {
      final response = await _dio.get('/customer/notifications');
      return response.data['items'] ?? [];
    } catch (e) {
      print('Error fetching customer notifications: $e');
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
      await _dio.post(endpoint);
    } catch (e) {
      print('Error marking notification as read: $e');
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
      await _dio.post(endpoint);
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }
}

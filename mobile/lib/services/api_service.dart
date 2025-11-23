import 'package:dio/dio.dart';
import 'package:mobile/models/order.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/models/search_dtos.dart';
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
        onError: (error, handler) {
          print(
            '❌ [HTTP ERROR] ${error.requestOptions.method} ${error.requestOptions.uri}',
          );
          print('❌ [HTTP ERROR] Status: ${error.response?.statusCode}');
          print('❌ [HTTP ERROR] Message: ${error.message}');
          print('❌ [HTTP ERROR] Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<List<Vendor>> getVendors() async {
    try {
      final response = await _dio.get('/vendors');
      final List<dynamic> data = response.data;
      return data.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching vendors: $e');
      rethrow;
    }
  }

  Future<List<Product>> getProducts(int vendorId) async {
    try {
      final response = await _dio.get('/vendors/$vendorId/products');
      final List<dynamic> data = response.data;
      return data.map((json) => Product.fromJson(json)).toList();
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
      final response = await _dio.get('/profile');
      return response.data;
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
      final response = await _dio.get('/products/categories');
      return List<String>.from(response.data);
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

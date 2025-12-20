import 'package:injectable/injectable.dart' hide Order;
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/orders/data/models/order.dart';

@lazySingleton
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._networkClient);

  final NetworkClient _networkClient;

  Future<Order> createOrder(
    String vendorId,
    Map<String, int> items, {
    String? deliveryAddressId,
    String? paymentMethod,
    String? note,
  }) async {
    final data = {
      'vendorId': vendorId,
      'items': items, // {productId: quantity} format
      'deliveryAddressId': deliveryAddressId,
      'paymentMethod': paymentMethod,
      'note': note,
    };

    final response = await _networkClient.dio.post('/orders', data: data);

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Order.fromJson(json as Map<String, dynamic>),
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Sipariş oluşturulamadı');
    }

    return apiResponse.data!;
  }

  Future<List<dynamic>> getOrders({int? vendorType}) async {
    final queryParams = <String, dynamic>{};
    if (vendorType != null) {
      queryParams['vendorType'] = vendorType;
    }

    final response = await _networkClient.dio.get(
      '/orders',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) {
        if (json is Map<String, dynamic> && json.containsKey('items')) {
          return json['items'] as List;
        }
        if (json is List) {
          return json;
        }
        return [];
      },
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Siparişler getirilemedi');
    }

    return apiResponse.data!;
  }

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final response = await _networkClient.dio.get('/orders/$orderId');

    // Backend Response format: ApiResponse<OrderDto>
    // We return Map for now to match current ApiService signature,
    // but ideally should return OrderDto
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      return response.data as Map<String, dynamic>;
    }

    // Legacy support
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrderDetailFull(String orderId) async {
    final response = await _networkClient.dio.get('/orders/$orderId/detail');
    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    final response = await _networkClient.dio.post(
      '/orders/$orderId/cancel',
      data: {'reason': reason},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ??
            'Server error while cancelling order. Please contact support.',
      );
    }
  }

  Future<void> cancelOrderItem(
    String customerOrderItemId,
    String reason,
  ) async {
    final response = await _networkClient.dio.post(
      '/orders/items/$customerOrderItemId/cancel',
      data: {'reason': reason},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Sipariş ürünü iptal edilemedi');
    }
  }

  Future<Map<String, dynamic>> getDeliveryTracking(String orderId) async {
    final response = await _networkClient.dio.get(
      '/map/delivery-tracking/$orderId',
    );
    return response.data as Map<String, dynamic>;
  }

  // Vendor Methods

  Future<List<dynamic>> getVendorOrders({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _networkClient.dio.get(
      '/vendor/orders',
      queryParameters: queryParams,
    );

    // Simplified handling based on ApiService
    return response.data['items'] ?? [];
  }

  Future<Map<String, dynamic>> getVendorOrdersWithCount({
    int page = 1,
    int pageSize = 20,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (status != null) {
      queryParams['status'] = status;
    }

    final response = await _networkClient.dio.get(
      '/vendor/orders',
      queryParameters: queryParams,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.success) {
      throw Exception(
        apiResponse.message ?? 'Error fetching vendor orders with count',
      );
    }

    return apiResponse.data!;
  }

  Future<Map<String, dynamic>> getVendorOrder(String orderId) async {
    final response = await _networkClient.dio.get('/vendor/orders/$orderId');
    return response.data as Map<String, dynamic>;
  }

  Future<void> acceptOrder(String orderId) async {
    final response = await _networkClient.dio.post(
      '/vendor/orders/$orderId/accept',
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Sipariş onaylanamadı');
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    final response = await _networkClient.dio.post(
      '/vendor/orders/$orderId/reject',
      data: {'reason': reason},
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Sipariş reddedilemedi');
    }
  }

  Future<void> updateOrderStatus(
    String orderId,
    String status, {
    String? note,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (note != null) {
      data['note'] = note;
    }

    final response = await _networkClient.dio.put(
      '/vendor/orders/$orderId/status',
      data: data,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json,
    );

    if (!apiResponse.success) {
      throw Exception(apiResponse.message ?? 'Sipariş durumu güncellenemedi');
    }
  }
}

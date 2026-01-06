import 'package:injectable/injectable.dart' hide Order;
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/orders/data/models/order.dart';

@lazySingleton
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._networkClient);

  final NetworkClient _networkClient;

  Future<Order> createOrder(
    String vendorId,
    List<Map<String, dynamic>> items, {
    String? deliveryAddressId,
    String? paymentMethod,
    String? note,
    String? couponCode,
    String? campaignId,
  }) async {
    final data = {
      'vendorId': vendorId,
      'items': items,
      'deliveryAddressId': deliveryAddressId,
      'paymentMethod': paymentMethod,
      'note': note,
      'couponCode': couponCode,
      'campaignId': campaignId,
    };

    final response = await _networkClient.dio.post(
      ApiEndpoints.createOrder,
      data: data,
    );

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
      ApiEndpoints.orders,
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
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.orders}/$orderId',
    );

    // Backend Response format: ApiResponse<OrderDto>
    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Sipariş detayı alınamadı');
      }

      return apiResponse.data!;
    }

    // Legacy support
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrderDetailFull(String orderId) async {
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.orders}/$orderId/detail',
    );

    if (response.data is Map<String, dynamic> &&
        response.data.containsKey('success')) {
      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => json as Map<String, dynamic>,
      );

      if (!apiResponse.success || apiResponse.data == null) {
        throw Exception(apiResponse.message ?? 'Sipariş detayı alınamadı');
      }

      return apiResponse.data!;
    }

    return response.data as Map<String, dynamic>;
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    final response = await _networkClient.dio.post(
      '${ApiEndpoints.orders}/$orderId/cancel',
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
      '${ApiEndpoints.orders}/items/$customerOrderItemId/cancel', // Assuming path logic matches existing
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
      '${ApiEndpoints.deliveryTracking}/$orderId',
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
      ApiEndpoints.vendorOrders,
      queryParameters: queryParams,
    );

    // Unwrap ApiResponse -> PagedResultDto -> Items
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      final innerData = data['data'];
      if (innerData is Map<String, dynamic> && innerData.containsKey('items')) {
        return innerData['items'] as List<dynamic>? ?? [];
      }
    }

    return [];
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
      ApiEndpoints.vendorOrders,
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
    final response = await _networkClient.dio.get(
      '${ApiEndpoints.vendorOrders}/$orderId',
    );

    // Unwrap the ApiResponse to return the Order DTO directly
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (json) => json as Map<String, dynamic>,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw Exception(apiResponse.message ?? 'Sipariş detayı alınamadı');
    }

    return apiResponse.data!;
  }

  Future<void> acceptOrder(String orderId) async {
    final response = await _networkClient.dio.post(
      '${ApiEndpoints.vendorOrders}/$orderId/accept',
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
      '${ApiEndpoints.vendorOrders}/$orderId/reject',
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
      '${ApiEndpoints.vendorOrders}/$orderId/status',
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

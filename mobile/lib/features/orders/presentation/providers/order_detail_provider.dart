import 'package:flutter/material.dart';
import 'package:mobile/features/orders/data/models/order_detail.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';

class OrderDetailProvider extends ChangeNotifier {
  OrderDetailProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  OrderDetail? _orderDetail;
  Map<String, dynamic>? _reviewStatus;
  bool _isLoading = true;
  String? _error;

  OrderDetail? get orderDetail => _orderDetail;
  Map<String, dynamic>? get reviewStatus => _reviewStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOrderDetail(String orderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getOrderDetailFull(orderId);
      final order = OrderDetail.fromJson(data);

      Map<String, dynamic>? status;
      if (order.status == 'Delivered') {
        try {
          status = await _apiService.getOrderReviewStatus(orderId);
        } catch (_) {
          // Ignore review status error
        }
      }

      _orderDetail = order;
      _reviewStatus = status;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _apiService.cancelOrder(orderId, reason);
      await loadOrderDetail(orderId); // Reload to show updated status
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrderItem(
    String orderId,
    OrderItemDetail item,
    String reason,
  ) async {
    try {
      await _apiService.cancelOrderItem(item.customerOrderItemId, reason);
      await loadOrderDetail(orderId); // Reload to show updated status
    } catch (e) {
      rethrow;
    }
  }

  Future<void> reorder(
    OrderDetail order,
    CartProvider cartProvider,
    BuildContext context,
  ) async {
    _isLoading = true; // Show loading while reordering
    notifyListeners();

    try {
      for (final item in order.items) {
        final product = Product(
          id: item.productId,
          vendorId: order.vendorId,
          vendorName: order.vendorName,
          name: item.productName,
          price: item.unitPrice,
          imageUrl: item.productImageUrl,
          description: '',
          isAvailable: true,
        );

        // Add item quantity times (since addItem adds 1)
        for (int i = 0; i < item.quantity; i++) {
          await cartProvider.addItem(product, context);
        }
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to refresh data (alias for loadOrderDetail)
  Future<void> refresh(String orderId) => loadOrderDetail(orderId);
}

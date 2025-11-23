import 'package:flutter/foundation.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Map<int, CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cartData = await _apiService.getCart();
      _items.clear();

      if (cartData['items'] != null) {
        for (var item in cartData['items']) {
          final product = Product(
            id: item['productId'],
            vendorId: 0, // Not needed for cart display
            name: item['productName'],
            description: null,
            price: (item['productPrice'] as num).toDouble(),
            imageUrl: item['productImageUrl'],
          );

          _items[product.id] = CartItem(
            product: product,
            quantity: item['quantity'],
            backendId: item['id'], // Store backend cart item ID
          );
        }
      }
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Product product) async {
    try {
      await _apiService.addToCart(product.id, 1);

      // Update local state
      if (_items.containsKey(product.id)) {
        _items[product.id]!.quantity++;
      } else {
        _items[product.id] = CartItem(product: product);
      }

      // Reload from backend to get correct IDs
      await loadCart();
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      final cartItem = _items[productId];
      if (cartItem?.backendId != null) {
        await _apiService.removeFromCart(cartItem!.backendId!);
      }

      _items.remove(productId);
      notifyListeners();
    } catch (e) {
      print('Error removing item: $e');
      rethrow;
    }
  }

  Future<void> increaseQuantity(int productId) async {
    if (!_items.containsKey(productId)) return;

    try {
      final cartItem = _items[productId]!;

      if (cartItem.backendId != null) {
        await _apiService.updateCartItem(
          cartItem.backendId!,
          cartItem.quantity + 1,
        );
      }
      cartItem.quantity++;

      notifyListeners();
    } catch (e) {
      print('Error increasing quantity: $e');
      rethrow;
    }
  }

  Future<void> decreaseQuantity(int productId) async {
    if (!_items.containsKey(productId)) return;

    try {
      final cartItem = _items[productId]!;

      if (cartItem.quantity > 1) {
        if (cartItem.backendId != null) {
          await _apiService.updateCartItem(
            cartItem.backendId!,
            cartItem.quantity - 1,
          );
        }
        cartItem.quantity--;
      } else {
        await removeItem(productId);
        return;
      }

      notifyListeners();
    } catch (e) {
      print('Error decreasing quantity: $e');
      rethrow;
    }
  }

  Future<void> clear() async {
    try {
      await _apiService.clearCart();
      _items.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }
}

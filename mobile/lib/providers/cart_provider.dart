import 'package:flutter/foundation.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  final Map<int, CartItem> _items = {};
  final ApiService _apiService = ApiService();
  final SyncService? _syncService;
  final ConnectivityProvider? _connectivityProvider;
  final _uuid = const Uuid();
  bool _isLoading = false;

  CartProvider({
    SyncService? syncService,
    ConnectivityProvider? connectivityProvider,
  }) : _syncService = syncService,
       _connectivityProvider = connectivityProvider;

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
    final isOnline = _connectivityProvider?.isOnline ?? true;

    // Update local state immediately for better UX
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();

    if (isOnline) {
      try {
        await _apiService.addToCart(product.id, 1);
        // Reload from backend to get correct IDs
        await loadCart();
      } catch (e) {
        print('Error adding item: $e');
        // If online but request failed, queue it
        if (_syncService != null) {
          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.addToCart,
            data: {'productId': product.id, 'quantity': 1},
          );
          await _syncService!.addToQueue(action);
          print('📦 [CART] Action queued: addToCart');
        }
      }
    } else {
      // Offline: queue the action
      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.addToCart,
          data: {'productId': product.id, 'quantity': 1},
        );
        await _syncService!.addToQueue(action);
        print('📦 [CART] Offline - Action queued: addToCart');
      }
    }
  }

  Future<void> removeItem(int productId) async {
    final cartItem = _items[productId];
    final isOnline = _connectivityProvider?.isOnline ?? true;

    // Update local state immediately
    _items.remove(productId);
    notifyListeners();

    if (isOnline && cartItem != null && cartItem.backendId != null) {
      try {
        await _apiService.removeFromCart(cartItem.backendId!);
      } catch (e) {
        print('Error removing item: $e');
        // If online but request failed, queue it
        if (_syncService != null) {
          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.removeFromCart,
            data: {'itemId': cartItem.backendId!},
          );
          await _syncService!.addToQueue(action);
          print('📦 [CART] Action queued: removeFromCart');
        }
      }
    } else if (!isOnline && cartItem != null && cartItem.backendId != null) {
      // Offline: queue the action
      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.removeFromCart,
          data: {'itemId': cartItem!.backendId!},
        );
        await _syncService!.addToQueue(action);
        print('📦 [CART] Offline - Action queued: removeFromCart');
      }
    }
  }

  Future<void> increaseQuantity(int productId) async {
    if (!_items.containsKey(productId)) return;

    final cartItem = _items[productId]!;
    final isOnline = _connectivityProvider?.isOnline ?? true;

    // Update local state immediately
    cartItem.quantity++;
    notifyListeners();

    if (isOnline && cartItem.backendId != null) {
      try {
        await _apiService.updateCartItem(
          cartItem.backendId!,
          cartItem.quantity,
        );
      } catch (e) {
        print('Error increasing quantity: $e');
        // If online but request failed, queue it
        if (_syncService != null) {
          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.updateCartItem,
            data: {
              'itemId': cartItem.backendId!,
              'quantity': cartItem.quantity,
            },
          );
          await _syncService!.addToQueue(action);
          print('📦 [CART] Action queued: updateCartItem');
        }
      }
    } else if (!isOnline && cartItem.backendId != null) {
      // Offline: queue the action
      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.updateCartItem,
          data: {'itemId': cartItem.backendId!, 'quantity': cartItem.quantity},
        );
        await _syncService!.addToQueue(action);
        print('📦 [CART] Offline - Action queued: updateCartItem');
      }
    }
  }

  Future<void> decreaseQuantity(int productId) async {
    if (!_items.containsKey(productId)) return;

    final cartItem = _items[productId]!;
    final isOnline = _connectivityProvider?.isOnline ?? true;

    if (cartItem.quantity > 1) {
      // Update local state immediately
      cartItem.quantity--;
      notifyListeners();

      if (isOnline && cartItem.backendId != null) {
        try {
          await _apiService.updateCartItem(
            cartItem.backendId!,
            cartItem.quantity,
          );
        } catch (e) {
          print('Error decreasing quantity: $e');
          // If online but request failed, queue it
          if (_syncService != null) {
            final action = SyncAction(
              id: _uuid.v4(),
              type: SyncActionType.updateCartItem,
              data: {
                'itemId': cartItem.backendId!,
                'quantity': cartItem.quantity,
              },
            );
            await _syncService!.addToQueue(action);
            print('📦 [CART] Action queued: updateCartItem');
          }
        }
      } else if (!isOnline && cartItem.backendId != null) {
        // Offline: queue the action
        if (_syncService != null) {
          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.updateCartItem,
            data: {
              'itemId': cartItem.backendId!,
              'quantity': cartItem.quantity,
            },
          );
          await _syncService!.addToQueue(action);
          print('📦 [CART] Offline - Action queued: updateCartItem');
        }
      }
    } else {
      await removeItem(productId);
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

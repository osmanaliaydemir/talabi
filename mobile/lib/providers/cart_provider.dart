import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/screens/shared/profile/add_edit_address_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:dio/dio.dart';
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
          int vendorId = item['vendorId'] ?? 0;
          String? vendorName = item['vendorName'];

          // If backend doesn't provide vendorId, fetch it from product endpoint
          if (vendorId == 0) {
            try {
              print(
                '🛒 [CART] Backend missing vendorId for product ${item['productId']}, fetching...',
              );
              final productData = await _apiService.getProduct(
                item['productId'],
              );
              vendorId = productData.vendorId;
              vendorName = productData.vendorName;
              print('🛒 [CART] Fetched vendorId: $vendorId');
            } catch (e) {
              print('🛒 [CART] Error fetching product details: $e');
              // Continue with vendorId = 0 if fetch fails
            }
          }

          final product = Product(
            id: item['productId'],
            vendorId: vendorId,
            vendorName: vendorName,
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

  Future<void> addItem(Product product, BuildContext? context) async {
    final isOnline = _connectivityProvider?.isOnline ?? true;

    if (isOnline) {
      try {
        // First, check API - don't update local state until success
        await _apiService.addToCart(product.id, 1);
        // Reload from backend to get correct IDs
        await loadCart();
      } catch (e) {
        print('Error adding item: $e');

        // Check if error is ADDRESS_REQUIRED
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map &&
              (responseData['code'] == 'ADDRESS_REQUIRED' ||
                  responseData['requiresAddress'] == true) &&
              context != null) {
            // Show popup dialog - don't update state
            await _showAddressRequiredDialog(context, product);
            return; // Don't queue the action if address is required
          }
        }

        // If online but request failed, update local state optimistically and queue it
        if (_syncService != null) {
          // Update local state for offline/queued scenarios
          if (_items.containsKey(product.id)) {
            _items[product.id]!.quantity++;
          } else {
            _items[product.id] = CartItem(product: product);
          }
          notifyListeners();

          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.addToCart,
            data: {'productId': product.id, 'quantity': 1},
          );
          await _syncService.addToQueue(action);
          print('📦 [CART] Action queued: addToCart');
        } else {
          // Re-throw error if no sync service available
          rethrow;
        }
      }
    } else {
      // Offline: update local state and queue the action
      if (_items.containsKey(product.id)) {
        _items[product.id]!.quantity++;
      } else {
        _items[product.id] = CartItem(product: product);
      }
      notifyListeners();

      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.addToCart,
          data: {'productId': product.id, 'quantity': 1},
        );
        await _syncService.addToQueue(action);
        print('📦 [CART] Offline - Action queued: addToCart');
      }
    }
  }

  Future<void> _showAddressRequiredDialog(
    BuildContext context,
    Product product,
  ) async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          localizations.addressRequiredTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          localizations.addressRequiredMessage,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('🟡 [CART] Address dialog: Cancel clicked');
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              localizations.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              print('🟢 [CART] Address dialog: Add Address clicked');
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(localizations.addAddress),
          ),
        ],
      ),
    );

    print('🟡 [CART] Address dialog result: $result');

    if (result == true) {
      // Use a small delay to ensure dialog is fully closed before navigation
      await Future.delayed(const Duration(milliseconds: 100));

      if (!context.mounted) {
        print('🔴 [CART] Context not mounted after dialog close');
        return;
      }

      print('🟢 [CART] Navigating to AddEditAddressScreen');
      // Navigate to add address screen
      final addressResult = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
      );

      print('🟡 [CART] Returned from AddEditAddressScreen: $addressResult');

      // After returning from address screen, try to add to cart again
      if (context.mounted) {
        print('🟢 [CART] Retrying addItem after address added');
        await addItem(product, context);
      } else {
        print('🔴 [CART] Context not mounted after address screen');
      }
    } else {
      print('🟡 [CART] User cancelled address dialog');
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
          await _syncService.addToQueue(action);
          print('📦 [CART] Action queued: removeFromCart');
        }
      }
    } else if (!isOnline && cartItem != null && cartItem.backendId != null) {
      // Offline: queue the action
      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.removeFromCart,
          data: {'itemId': cartItem.backendId!},
        );
        await _syncService.addToQueue(action);
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
          await _syncService.addToQueue(action);
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
        await _syncService.addToQueue(action);
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
            await _syncService.addToQueue(action);
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
          await _syncService.addToQueue(action);
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

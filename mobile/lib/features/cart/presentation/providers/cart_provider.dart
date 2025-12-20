import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/profile/presentation/screens/customer/add_edit_address_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class CartProvider with ChangeNotifier {
  CartProvider({
    ApiService? apiService,
    SyncService? syncService,
    ConnectivityProvider? connectivityProvider,
  }) : _apiService = apiService ?? ApiService(),
       _syncService = syncService,
       _connectivityProvider = connectivityProvider;

  final Map<String, CartItem> _items = {};
  final ApiService _apiService;
  final SyncService? _syncService;
  final ConnectivityProvider? _connectivityProvider;
  final _uuid = const Uuid();
  bool _isLoading = false;

  Map<String, CartItem> get items => _items;
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
        for (final item in cartData['items']) {
          String vendorId = item['vendorId']?.toString() ?? '0';
          String? vendorName = item['vendorName'];

          // If backend doesn't provide vendorId, fetch it from product endpoint
          if (vendorId == '0') {
            try {
              LoggerService().debug(
                '🛒 [CART] Backend missing vendorId for product ${item['productId']}, fetching...',
              );
              // Log the raw item to see what's missing
              LoggerService().debug('🛒 [CART] Raw Item Data: $item');

              final productData = await _apiService.getProduct(
                item['productId'],
              );
              vendorId = productData.vendorId;
              vendorName = productData.vendorName;
              LoggerService().debug('🛒 [CART] Fetched vendorId: $vendorId');
            } catch (e, stackTrace) {
              LoggerService().warning(
                '🛒 [CART] Error fetching product details',
                e,
                stackTrace,
              );
              // Continue with vendorId = 0 if fetch fails
            }
          }

          final product = Product(
            id: item['productId'].toString(),
            vendorId: vendorId,
            vendorName: vendorName,
            name: item['productName'],
            description: null,
            price: (item['productPrice'] as num).toDouble(),
            currency: item['currency'] != null
                ? Currency.fromInt(item['currency'] as int?)
                : Currency.fromString(item['currencyCode'] as String?),
            imageUrl: item['productImageUrl'],
            vendorType: item['vendorType'],
          );

          _items[product.id] = CartItem(
            product: product,
            quantity: item['quantity'],
            backendId: item['id'].toString(), // Store backend cart item ID
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error loading cart', e, stackTrace);
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

        // Log add_to_cart
        await AnalyticsService.logAddToCart(product: product, quantity: 1);

        // Reload from backend to get correct IDs
        await loadCart();
      } catch (e, stackTrace) {
        LoggerService().error('Error adding item', e, stackTrace);

        // Check if error is ADDRESS_REQUIRED
        if (e is DioException && e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map &&
              (responseData['code'] == 'ADDRESS_REQUIRED' ||
                  responseData['requiresAddress'] == true) &&
              context != null &&
              context.mounted) {
            // Show popup dialog - don't update state
            await _showAddressRequiredDialog(context, product);
            return; // Don't queue the action if address is required
          }
        }

        // If online but request failed, update local state optimistically and queue it
        if (_syncService != null) {
          // Check if it's a 409 Conflict or other non-retriable error
          if (e is DioException && e.response?.statusCode == 409) {
            LoggerService().warning(
              '🔴 [CART] Conflict error (409), NOT queuing action.',
            );
            rethrow;
          }

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
          LoggerService().debug('📦 [CART] Action queued: addToCart');
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
        LoggerService().debug('📦 [CART] Offline - Action queued: addToCart');
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
              LoggerService().debug('🟡 [CART] Address dialog: Cancel clicked');
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              localizations.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              LoggerService().debug(
                '🟢 [CART] Address dialog: Add Address clicked',
              );
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

    LoggerService().debug('🟡 [CART] Address dialog result: $result');

    if (result == true) {
      // Use a small delay to ensure dialog is fully closed before navigation
      await Future.delayed(const Duration(milliseconds: 100));

      if (!context.mounted) {
        LoggerService().warning(
          '🔴 [CART] Context not mounted after dialog close',
        );
        return;
      }

      LoggerService().debug('🟢 [CART] Navigating to AddEditAddressScreen');
      // Navigate to add address screen
      final addressResult = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
      );

      LoggerService().debug(
        '🟡 [CART] Returned from AddEditAddressScreen: $addressResult',
      );

      // After returning from address screen, try to add to cart again
      if (context.mounted) {
        LoggerService().debug('🟢 [CART] Retrying addItem after address added');
        await addItem(product, context);
      } else {
        LoggerService().warning(
          '🔴 [CART] Context not mounted after address screen',
        );
      }
    } else {
      LoggerService().debug('🟡 [CART] User cancelled address dialog');
    }
  }

  Future<void> removeItem(String productId) async {
    final cartItem = _items[productId];
    final isOnline = _connectivityProvider?.isOnline ?? true;

    // Update local state immediately
    _items.remove(productId);
    notifyListeners();

    if (isOnline && cartItem != null && cartItem.backendId != null) {
      try {
        await _apiService.removeFromCart(cartItem.backendId!);

        // Log remove_from_cart
        await AnalyticsService.logRemoveFromCart(
          product: cartItem.product,
          quantity: cartItem.quantity,
        );
      } catch (e, stackTrace) {
        LoggerService().error('Error removing item', e, stackTrace);
        // If online but request failed, queue it
        if (_syncService != null) {
          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.removeFromCart,
            data: {'itemId': cartItem.backendId!},
          );
          await _syncService.addToQueue(action);
          LoggerService().debug('📦 [CART] Action queued: removeFromCart');
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
        LoggerService().debug(
          '📦 [CART] Offline - Action queued: removeFromCart',
        );
      }
    }
  }

  Future<void> increaseQuantity(String productId) async {
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
      } catch (e, stackTrace) {
        LoggerService().error('Error increasing quantity', e, stackTrace);
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
          LoggerService().debug('📦 [CART] Action queued: updateCartItem');
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
        LoggerService().debug(
          '📦 [CART] Offline - Action queued: updateCartItem',
        );
      }
    }
  }

  Future<void> decreaseQuantity(String productId) async {
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
        } catch (e, stackTrace) {
          LoggerService().error('Error decreasing quantity', e, stackTrace);
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
            LoggerService().debug('📦 [CART] Action queued: updateCartItem');
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
          LoggerService().debug(
            '📦 [CART] Offline - Action queued: updateCartItem',
          );
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
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart', e, stackTrace);
      rethrow;
    }
  }
}

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
import 'package:mobile/features/coupons/data/models/coupon.dart';
import 'package:mobile/features/coupons/services/coupon_service.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';

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
  List<Product> _recommendations = [];

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;
  List<Product> get recommendations => _recommendations;

  Future<void> fetchRecommendations({
    int? type,
    double? lat,
    double? lon,
  }) async {
    try {
      _recommendations = await _apiService.getRecommendations(
        type: type,
        lat: lat,
        lon: lon,
      );
      notifyListeners();
    } catch (e) {
      LoggerService().error('Error fetching recommendations in provider', e);
    }
  }

  // System Settings
  double _deliveryFee = 0.0;
  double _freeDeliveryThreshold = 0.0;

  double get deliveryFee => isFreeDeliveryReached ? 0.0 : _deliveryFee;
  double get freeDeliveryThreshold => _freeDeliveryThreshold;

  bool get isFreeDeliveryEnabled =>
      _freeDeliveryThreshold > 0 && _deliveryFee > 0;
  bool get isFreeDeliveryReached =>
      isFreeDeliveryEnabled && subtotalAmount >= _freeDeliveryThreshold;

  double get freeDeliveryProgress {
    if (_freeDeliveryThreshold <= 0) return 0;
    return (subtotalAmount / _freeDeliveryThreshold).clamp(0.0, 1.0);
  }

  double get remainingForFreeDelivery {
    if (_freeDeliveryThreshold <= 0) return 0;
    final remaining = _freeDeliveryThreshold - subtotalAmount;
    return remaining < 0 ? 0 : remaining;
  }

  // Coupon handling
  final CouponService _couponService = CouponService();
  Coupon? _appliedCoupon;
  Coupon? get appliedCoupon => _appliedCoupon;

  // Campaign handling
  Campaign? _selectedCampaign;
  Campaign? get selectedCampaign => _selectedCampaign;

  double _backendDiscountAmount = 0.0;
  List<String> _discountedItemIds = [];

  bool isItemDiscounted(String itemId) {
    // Check if backend specifically flagged this item AND we have a backend discount
    if (_backendDiscountAmount > 0 && _discountedItemIds.isNotEmpty) {
      // Backend IDs are GUIDs usually, but let's ensure we match format
      // Mobile item IDs are Product IDs (GUIDs).
      // The backend 'DiscountedItemIds' list contains CartItem IDs usually?
      // Wait, let's check Backend logic:
      // result.ApplicableItemIds = applicableItems.Select(i => i.Id).ToList();
      // These are CartItem IDs, NOT Product IDs.
      // In Mobile, _items key is ProductId.
      // CartItem model has 'backendId'. We should check against that.

      final item = _items[itemId];
      if (item != null && item.backendId != null) {
        return _discountedItemIds.contains(item.backendId);
      }
    }
    return false;
  }

  double get subtotalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  double get discountAmount {
    // 1. Use Backend Calculated Discount if available
    // This allows advanced rules (item-based, limits, etc.) to be handled by server
    if (_backendDiscountAmount > 0) {
      // If we have a backend discount, trust it.
      // However, check if we are in "modification mode" (e.g. user just changed quantity and waiting for sync).
      // Ideally, we wait for clean state. But for now, returning backend value is safer than incorrect local calc.
      return _backendDiscountAmount;
    }

    // Fallback or Local estimation (only if backend value is 0 or not synced yet)
    // Actually, if we rely on backend, we should probably prefer 0 until sync if strict.
    // But for responsiveness, maybe keep coupon logic if no backend campaign?
    // Let's keep existing logic as fallback BUT Campaign logic should be removed if we exclusively rely on backend for Campaign.

    // 1. Campaign Discount (Local - Deprecated/Fallback)
    if (_selectedCampaign != null) {
      // Local calc logic...
      // For consistency, if we moved to backend calc, we should try to avoid this.
      // But until fully tested, let's leave it as a "prediction" if backend value is missing.
      if (_selectedCampaign!.minCartAmount != null &&
          subtotalAmount < _selectedCampaign!.minCartAmount!) {
        return 0.0;
      }

      if (_selectedCampaign!.discountType == DiscountType.percentage) {
        return subtotalAmount * (_selectedCampaign!.discountValue / 100);
      } else {
        return _selectedCampaign!.discountValue;
      }
    }

    // 2. Check Coupon Discount (fallback if no campaign)
    if (_appliedCoupon == null) return 0.0;

    // Check min amount requirement again to be safe
    if (subtotalAmount < _appliedCoupon!.minCartAmount) {
      return 0.0;
    }

    if (_appliedCoupon!.discountType == DiscountType.percentage) {
      return subtotalAmount * (_appliedCoupon!.discountValue / 100);
    } else {
      return _appliedCoupon!.discountValue;
    }
  }

  double get totalAmount {
    final total = subtotalAmount - discountAmount;
    return total < 0 ? 0 : total;
  }

  Future<void> selectCampaign(Campaign campaign) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (campaign.minCartAmount != null &&
          subtotalAmount < campaign.minCartAmount!) {
        throw Exception(
          'Kampanya için sepet tutarı en az ${campaign.minCartAmount} TL olmalıdır.',
        );
      }

      // Sync with Backend
      // When selecting campaign, we clear coupon implicitly on backend?
      // Our backend logic handles them independently. But Mobile logic makes them exclusive.
      // So we should send couponCode: null explicitly.
      await _apiService.updateCartPromotions(
        campaignId: campaign.id,
        couponCode: null, // Clear coupon
      );

      // Remove coupon if selecting campaign (Mutually Exclusive)
      _appliedCoupon = null;
      _selectedCampaign = campaign;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCampaign() async {
    try {
      await _apiService.updateCartPromotions(
        campaignId: null, // Clear campaign
        // Preserve coupon? Use current state?
        // If we are removing campaign, coupon is already null because of exclusivity.
        couponCode: _appliedCoupon?.code,
      );
      _selectedCampaign = null;
      notifyListeners();
    } catch (e) {
      // Handle error?
      LoggerService().error('Error removing campaign from cart', e);
    }
  }

  Future<void> applyCoupon(String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final coupon = await _couponService.validateCoupon(code);
      if (coupon == null) {
        throw Exception('Geçersiz kupon kodu');
      }

      if (subtotalAmount < coupon.minCartAmount) {
        throw Exception(
          'Kupon için sepet tutarı en az ${coupon.minCartAmount} TL olmalıdır.',
        );
      }

      // Sync with Backend
      await _apiService.updateCartPromotions(
        couponCode: code,
        campaignId: null, // Clear campaign
      );

      // Remove campaign if applying coupon (Mutually Exclusive)
      _selectedCampaign = null;
      _appliedCoupon = coupon;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCoupon() async {
    try {
      await _apiService.updateCartPromotions(
        couponCode: null, // Clear coupon
        campaignId: _selectedCampaign?.id, // Preserve campaign (should be null)
      );
      _appliedCoupon = null;
      notifyListeners();
    } catch (e) {
      LoggerService().error('Error removing coupon from cart', e);
    }
  }

  void _checkCouponValidity() {
    if (_appliedCoupon != null) {
      if (subtotalAmount < _appliedCoupon!.minCartAmount) {
        _appliedCoupon = null;
      }
    }

    if (_selectedCampaign != null) {
      if (_selectedCampaign!.minCartAmount != null &&
          subtotalAmount < _selectedCampaign!.minCartAmount!) {
        _selectedCampaign = null;
      }
    }
  }

  Future<void> loadCart() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final cartData = await _apiService.getCart();
      final Map<String, CartItem> newItems = {};

      if (cartData['items'] != null) {
        final List<Future<void>> fetchTasks = [];
        for (final item in cartData['items']) {
          fetchTasks.add(() async {
            String vendorId = item['vendorId']?.toString() ?? '0';
            String? vendorName = item['vendorName'];

            // If backend doesn't provide vendorId, fetch it from product endpoint
            if (vendorId == '0') {
              try {
                final productData = await _apiService.getProduct(
                  item['productId'],
                );
                vendorId = productData.vendorId;
                vendorName = productData.vendorName;
              } catch (e, stackTrace) {
                LoggerService().warning(
                  '🛒 [CART] Error fetching product details for ${item['productId']}',
                  e,
                  stackTrace,
                );
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

            newItems[product.id] = CartItem(
              product: product,
              quantity: item['quantity'],
              backendId: item['id'].toString(), // Store backend cart item ID
            );
          }());
        }
        await Future.wait(fetchTasks);
      }

      // Update _items with the new data
      _items.clear();
      _items.addAll(newItems);

      // Parse Backend Discount
      _backendDiscountAmount =
          (cartData['campaignDiscountAmount'] as num?)?.toDouble() ?? 0.0;

      if (cartData['discountedItemIds'] != null) {
        _discountedItemIds = (cartData['discountedItemIds'] as List)
            .map((e) => e.toString())
            .toList();
      } else {
        _discountedItemIds = [];
      }

      _checkCouponValidity();

      // Fetch System Settings (Delivery Fee & Threshold)
      try {
        final settings = await _apiService.getSystemSettings();
        if (settings.containsKey('DeliveryFee')) {
          final fee = double.tryParse(settings['DeliveryFee']!);
          if (fee != null) {
            _deliveryFee = fee;
          }
        }
        if (settings.containsKey('FreeDeliveryThreshold')) {
          final threshold = double.tryParse(settings['FreeDeliveryThreshold']!);
          if (threshold != null) {
            _freeDeliveryThreshold = threshold;
          }
        }
      } catch (e) {
        LoggerService().warning('Error loading system settings for cart', e);
        // Default to 0 or keep previous
      }

      // Hydrate Promotions (Persisted from Backend)
      try {
        // Reset local state first
        _appliedCoupon = null;
        _selectedCampaign = null;

        if (cartData['couponCode'] != null &&
            cartData['couponCode'].toString().isNotEmpty) {
          final code = cartData['couponCode'].toString();
          // Validate and fetch full coupon object
          final coupon = await _couponService.validateCoupon(code);
          if (coupon != null && subtotalAmount >= coupon.minCartAmount) {
            _appliedCoupon = coupon;
          }
        }

        // Campaign loading moved to CheckoutScreen
        // We only store the campaignId from backend, but don't fetch campaign details here
        // This improves cart screen performance

        _checkCouponValidity();
      } catch (e) {
        LoggerService().error('Error hydrating promotions', e);
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
          _checkCouponValidity();
          notifyListeners();

          final action = SyncAction(
            id: _uuid.v4(),
            type: SyncActionType.addToCart,
            data: {'productId': product.id, 'quantity': 1},
          );
          await _syncService.addToQueue(action);
          // LoggerService().debug('📦 [CART] Action queued: addToCart');
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
      _checkCouponValidity();
      notifyListeners();

      if (_syncService != null) {
        final action = SyncAction(
          id: _uuid.v4(),
          type: SyncActionType.addToCart,
          data: {'productId': product.id, 'quantity': 1},
        );
        await _syncService.addToQueue(action);
        // LoggerService().debug('📦 [CART] Offline - Action queued: addToCart');
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
    _checkCouponValidity();
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
          // LoggerService().debug('📦 [CART] Action queued: removeFromCart');
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
        // LoggerService().debug('📦 [CART] Offline - Action queued: removeFromCart');
      }
    }
  }

  Future<void> increaseQuantity(String productId) async {
    if (!_items.containsKey(productId)) return;

    final cartItem = _items[productId]!;
    final isOnline = _connectivityProvider?.isOnline ?? true;

    // Update local state immediately
    cartItem.quantity++;
    _checkCouponValidity();
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
      _checkCouponValidity();
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
      _appliedCoupon = null;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing cart', e, stackTrace);
      rethrow;
    }
  }
}

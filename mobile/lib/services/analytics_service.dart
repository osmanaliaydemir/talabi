import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static bool _initialized = false;

  static void _initializeAnalytics() {
    if (_initialized) return;
    _initialized = true;

    try {
      // Check if Firebase is initialized first
      Firebase.app();
      _analytics = FirebaseAnalytics.instance;
    } catch (e) {
      // Firebase not initialized or not available - silently fail
      // Error is expected when Firebase is not configured, no need to log
      _analytics = null;
    }
  }

  static bool get isAvailable => _analytics != null;

  // Kullanıcı giriş yaptığında
  static Future<void> logLogin({required String method}) async {
    _initializeAnalytics();
    if (_analytics != null) {
      try {
        await _analytics!.logLogin(loginMethod: method);
      } catch (e) {
        if (kDebugMode) {
          print('Analytics logLogin failed: $e');
        }
      }
    }
  }

  // Kullanıcı kayıt olduğunda
  static Future<void> logSignUp({required String method}) async {
    _initializeAnalytics();
    if (_analytics != null) {
      try {
        await _analytics!.logSignUp(signUpMethod: method);
      } catch (e) {
        if (kDebugMode) {
          print('Analytics logSignUp failed: $e');
        }
      }
    }
  }

  // Ürün detayına bakıldığında
  static Future<void> logViewItem({required Product product}) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logViewItem(
        currency: product.currency.code,
        value: product.price,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.categoryId,
            price: product.price,
            currency: product.currency.code,
            quantity: 1,
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logViewItem failed: $e');
      }
    }
  }

  // Sepete ürün eklendiğinde
  static Future<void> logAddToCart({
    required Product product,
    required int quantity,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logAddToCart(
        currency: product.currency.code,
        value: product.price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.categoryId,
            price: product.price,
            currency: product.currency.code,
            quantity: quantity,
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logAddToCart failed: $e');
      }
    }
  }

  // Sepetten ürün çıkarıldığında
  static Future<void> logRemoveFromCart({
    required Product product,
    required int quantity,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logRemoveFromCart(
        currency: product.currency.code,
        value: product.price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: product.id,
            itemName: product.name,
            itemCategory: product.categoryId,
            price: product.price,
            currency: product.currency.code,
            quantity: quantity,
          ),
        ],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logRemoveFromCart failed: $e');
      }
    }
  }

  // Ödeme sayfasına geçildiğinde (Checkout)
  static Future<void> logBeginCheckout({
    required double totalAmount,
    required String currency,
    required List<CartItem> cartItems,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logBeginCheckout(
        value: totalAmount,
        currency: currency,
        items: cartItems
            .map(
              (item) => AnalyticsEventItem(
                itemId: item.product.id,
                itemName: item.product.name,
                itemCategory: item.product.categoryId,
                price: item.product.price,
                currency: item.product.currency.code,
                quantity: item.quantity,
              ),
            )
            .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logBeginCheckout failed: $e');
      }
    }
  }

  // Sipariş tamamlandığında (Purchase)
  static Future<void> logPurchase({
    required String orderId,
    required double totalAmount,
    required String currency,
    required List<CartItem> cartItems,
    String? shippingAddress,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      // Adres bilgisini parametre olarak ekleyelim
      final params = <String, Object>{
        'shipping_address': shippingAddress ?? 'Unknown',
      };

      await _analytics!.logPurchase(
        transactionId: orderId,
        value: totalAmount,
        currency: currency,
        items: cartItems
            .map(
              (item) => AnalyticsEventItem(
                itemId: item.product.id,
                itemName: item.product.name,
                itemCategory: item.product.categoryId,
                price: item.product.price,
                currency: item.product.currency.code,
                quantity: item.quantity,
              ),
            )
            .toList(),
        parameters: params,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logPurchase failed: $e');
      }
    }
  }

  // Arama yapıldığında
  static Future<void> logSearch({required String searchTerm}) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logSearch(searchTerm: searchTerm);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logSearch failed: $e');
      }
    }
  }

  // Sepet görüntülendiğinde
  static Future<void> logViewCart({
    double? totalAmount,
    String? currency,
    List<CartItem>? cartItems,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logViewCart(
        currency: currency,
        value: totalAmount,
        items: cartItems
            ?.map(
              (item) => AnalyticsEventItem(
                itemId: item.product.id,
                itemName: item.product.name,
                itemCategory: item.product.categoryId,
                price: item.product.price,
                currency: item.product.currency.code,
                quantity: item.quantity,
              ),
            )
            .toList(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logViewCart failed: $e');
      }
    }
  }

  // Özel bir event loglamak için
  static Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logCustomEvent failed: $e');
      }
    }
  }

  // Kullanıcı ID'sini ayarlamak için (Login sonrası)
  static Future<void> setUserId(String userId) async {
    _initializeAnalytics();
    if (_analytics != null && userId.isNotEmpty) {
      try {
        await _analytics!.setUserId(id: userId);
      } catch (e) {
        if (kDebugMode) {
          print('Analytics setUserId failed: $e');
        }
      }
    }
  }
}

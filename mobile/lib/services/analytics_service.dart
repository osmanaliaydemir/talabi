import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile/features/cart/data/models/cart_item.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/logger_service.dart';

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
      } catch (e, stackTrace) {
        LoggerService().warning('Analytics logLogin failed', e, stackTrace);
      }
    }
  }

  // Kullanıcı kayıt olduğunda
  static Future<void> logSignUp({required String method}) async {
    _initializeAnalytics();
    if (_analytics != null) {
      try {
        await _analytics!.logSignUp(signUpMethod: method);
      } catch (e, stackTrace) {
        LoggerService().warning('Analytics logSignUp failed', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logViewItem failed', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logAddToCart failed', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Analytics logRemoveFromCart failed',
        e,
        stackTrace,
      );
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
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Analytics logBeginCheckout failed',
        e,
        stackTrace,
      );
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
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logPurchase failed', e, stackTrace);
    }
  }

  // Arama yapıldığında
  static Future<void> logSearch({required String searchTerm}) async {
    _initializeAnalytics();
    if (_analytics == null) return;
    try {
      await _analytics!.logSearch(searchTerm: searchTerm);
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logSearch failed', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logViewCart failed', e, stackTrace);
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
    } catch (e, stackTrace) {
      LoggerService().warning('Analytics logCustomEvent failed', e, stackTrace);
    }
  }

  // Kullanıcı ID'sini ayarlamak için (Login sonrası)
  static Future<void> setUserId(String userId) async {
    _initializeAnalytics();
    if (_analytics != null && userId.isNotEmpty) {
      try {
        await _analytics!.setUserId(id: userId);
      } catch (e, stackTrace) {
        LoggerService().warning('Analytics setUserId failed', e, stackTrace);
      }
    }
  }
}

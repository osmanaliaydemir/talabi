import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Kullanıcı giriş yaptığında
  static Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Kullanıcı kayıt olduğunda
  static Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // Ürün detayına bakıldığında
  static Future<void> logViewItem({required Product product}) async {
    await _analytics.logViewItem(
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
  }

  // Sepete ürün eklendiğinde
  static Future<void> logAddToCart({
    required Product product,
    required int quantity,
  }) async {
    await _analytics.logAddToCart(
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
  }

  // Sepetten ürün çıkarıldığında
  static Future<void> logRemoveFromCart({
    required Product product,
    required int quantity,
  }) async {
    await _analytics.logRemoveFromCart(
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
  }

  // Ödeme sayfasına geçildiğinde (Checkout)
  static Future<void> logBeginCheckout({
    required double totalAmount,
    required String currency,
    required List<CartItem> cartItems,
  }) async {
    await _analytics.logBeginCheckout(
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
  }

  // Sipariş tamamlandığında (Purchase)
  static Future<void> logPurchase({
    required String orderId,
    required double totalAmount,
    required String currency,
    required List<CartItem> cartItems,
    String? shippingAddress,
  }) async {
    // Adres bilgisini parametre olarak ekleyelim
    final params = <String, Object>{
      'shipping_address': shippingAddress ?? 'Unknown',
    };

    await _analytics.logPurchase(
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
  }

  // Arama yapıldığında
  static Future<void> logSearch({required String searchTerm}) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Sepet görüntülendiğinde
  static Future<void> logViewCart({
    double? totalAmount,
    String? currency,
    List<CartItem>? cartItems,
  }) async {
    await _analytics.logViewCart(
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
  }

  // Özel bir event loglamak için
  static Future<void> logCustomEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  // Kullanıcı ID'sini ayarlamak için (Login sonrası)
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}

import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:flutter/widgets.dart';

/// UI-specific state for CartScreen (favorites & loading flags).
///
/// Ana sepet state'i zaten CartProvider'da; burada yalnızca:
/// - önerilen ürünlerin favori durumları
/// - favori yükleme spinner flag'i
/// tutulur.
class CartUiProvider with ChangeNotifier {
  CartUiProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  final Map<String, bool> _favoriteStatus = {};
  bool _isLoadingFavorites = false;

  Map<String, bool> get favoriteStatus => Map.unmodifiable(_favoriteStatus);
  bool get isLoadingFavorites => _isLoadingFavorites;

  Future<void> loadFavorites() async {
    if (_isLoadingFavorites) return;
    _isLoadingFavorites = true;
    notifyListeners();
    try {
      final favoritesResult = await _apiService.getFavorites();
      _favoriteStatus
        ..clear()
        ..addEntries(
          favoritesResult.items.map((fav) => MapEntry(fav.id.toString(), true)),
        );
      _isLoadingFavorites = false;
      notifyListeners();
    } catch (_) {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(BuildContext context, Product product) async {
    final productId = product.id.toString();
    final isFav = _favoriteStatus[productId] ?? false;

    try {
      if (isFav) {
        await _apiService.removeFromFavorites(productId);
      } else {
        await _apiService.addToFavorites(productId);
      }
      _favoriteStatus[productId] = !isFav;
      notifyListeners();

      if (!context.mounted) return;

      // Not: Lokalizasyon anahtarları bu provider bağlamında bilinmediği için
      // burada basit mesajlar kullanıyoruz. İstenirse çağıran ekran özelleştirebilir.
      ToastMessage.show(
        context,
        message: !isFav ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
        isSuccess: true,
      );
    } catch (e) {
      if (context.mounted) {
        ToastMessage.show(context, message: 'Hata: $e', isSuccess: false);
      }
    }
  }
}

import 'package:mobile/features/products/data/models/product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.backendId,
    this.selectedOptions,
  });

  double get totalPrice {
    double price = product.price;
    if (selectedOptions != null) {
      for (final option in selectedOptions!) {
        if (option['priceAdjustment'] != null) {
          price += (option['priceAdjustment'] as num).toDouble();
        }
      }
    }
    return price * quantity;
  }

  final Product product;
  int quantity;
  String? backendId; // Backend cart item ID
  List<Map<String, dynamic>>? selectedOptions;
}

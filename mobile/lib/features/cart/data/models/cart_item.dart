import 'package:mobile/features/products/data/models/product.dart';

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.backendId,
    this.selectedOptions,
  });

  double get unitPrice {
    double price = product.price;
    if (selectedOptions != null) {
      for (final option in selectedOptions!) {
        // Handle various key formats for priceAdjustment due to backend inconsistencies
        final adjustment =
            option['priceAdjustment'] ?? option['PriceAdjustment'];

        if (adjustment != null) {
          price += (adjustment as num).toDouble();
        }
      }
    }
    return price;
  }

  double get totalPrice {
    return unitPrice * quantity;
  }

  final Product product;
  int quantity;
  String? backendId; // Backend cart item ID
  List<Map<String, dynamic>>? selectedOptions;
}

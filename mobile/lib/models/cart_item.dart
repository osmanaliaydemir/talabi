import 'package:mobile/models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  int? backendId; // Backend cart item ID

  CartItem({
    required this.product,
    this.quantity = 1,
    this.backendId,
  });

  double get totalPrice => product.price * quantity;
}

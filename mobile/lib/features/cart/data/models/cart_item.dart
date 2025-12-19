import 'package:mobile/features/products/data/models/product.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1, this.backendId});

  double get totalPrice => product.price * quantity;

  final Product product;
  int quantity;
  String? backendId; // Backend cart item ID
}

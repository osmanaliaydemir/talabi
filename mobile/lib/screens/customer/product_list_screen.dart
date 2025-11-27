import 'package:flutter/material.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/product_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/widgets/common/skeleton_loader.dart';
import 'package:mobile/widgets/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class ProductListScreen extends StatefulWidget {
  final Vendor vendor;

  const ProductListScreen({super.key, required this.vendor});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _apiService.getProducts(widget.vendor.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.vendor.name)),
      bottomNavigationBar: const PersistentBottomNavBar(),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (context, index) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: ProductSkeletonItem(),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz ürün yok.'));
          }

          final products = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _productsFuture = _apiService.getProducts(widget.vendor.id);
              });
              await _productsFuture;
            },
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: product.imageUrl != null
                        ? Hero(
                            tag: 'product-${product.id}',
                            child: Image.network(
                              product.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.fastfood, size: 60);
                              },
                            ),
                          )
                        : const Icon(Icons.fastfood, size: 60),
                    title: Text(product.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.description != null)
                          Text(product.description!),
                        const SizedBox(height: 4),
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            TapLogger.logButtonPress(
                              'Add to Cart',
                              context: 'ProductListScreen',
                            );
                            TapLogger.logTap(
                              'Product: ${product.name}',
                              action: 'Add to Cart',
                            );
                            final cart = Provider.of<CartProvider>(
                              context,
                              listen: false,
                            );
                            cart
                                .addItem(product, context)
                                .then((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${product.name} sepete eklendi',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                })
                                .catchError((e) {
                                  // Error is handled by CartProvider (popup shown)
                                });
                          },
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      TapLogger.logTap(
                        'Product: ${product.name}',
                        action: 'View Detail',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(
                            productId: product.id,
                            product: product,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

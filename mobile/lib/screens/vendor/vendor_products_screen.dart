import 'package:flutter/material.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/vendor/vendor_product_form_screen.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/widgets/vendor/vendor_header.dart';
import 'package:mobile/widgets/vendor/vendor_bottom_nav.dart';
import 'package:provider/provider.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _selectedCategory;
  bool? _availabilityFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _apiService.getVendorProducts(
        category: _selectedCategory,
        isAvailable: _availabilityFilter,
      );
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ürünler yüklenemedi: $e')));
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()) ||
                  (p.description?.toLowerCase().contains(query.toLowerCase()) ??
                      false),
            )
            .toList();
      }
    });
  }

  Future<void> _toggleAvailability(Product product) async {
    try {
      await _apiService.updateProductAvailability(
        product.id,
        !product.isAvailable,
      );
      _loadProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.isAvailable
                  ? '${product.name} stok dışı yapıldı'
                  : '${product.name} stokta',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text(
          '${product.name} ürününü silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteProduct(product.id);
        _loadProducts();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${product.name} silindi')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VendorHeader(
        title: 'Ürünlerim',
        leadingIcon: Icons.inventory_2_outlined,
        showBackButton: false,
        onRefresh: _loadProducts,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Ürün ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterProducts,
            ),
          ),

          // Products list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ürün bulunamadı',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const VendorProductFormScreen(),
                                ),
                              );
                              if (result == true) _loadProducts();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('İlk Ürününü Ekle'),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return _buildProductCard(product, localizationProvider);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          TapLogger.logNavigation('VendorProducts', 'VendorProductForm');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VendorProductFormScreen(),
            ),
          );
          if (result == true) _loadProducts();
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Ürün', style: TextStyle(color: Colors.white)),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 2),
    );
  }

  Widget _buildProductCard(Product product, LocalizationProvider localization) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () async {
          TapLogger.logTap('Product #${product.id}', action: 'Edit');
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorProductFormScreen(product: product),
            ),
          );
          if (result == true) _loadProducts();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.fastfood, size: 48),
                        )
                      : const Icon(Icons.fastfood, size: 48),
                ),
                // Availability badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.isAvailable ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.isAvailable ? 'Stokta' : 'Stok Dışı',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(
                        product.price,
                        localization.currency,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: IconButton(
                      icon: Icon(
                        product.isAvailable
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => _toggleAvailability(product),
                      tooltip: product.isAvailable
                          ? 'Stok Dışı Yap'
                          : 'Stokta Yap',
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => _deleteProduct(product),
                      tooltip: 'Sil',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

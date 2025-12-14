import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/vendor/product_form_screen.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/screens/vendor/widgets/header.dart';
import 'package:mobile/screens/vendor/widgets/bottom_nav.dart';
//Todo: Remove this import OAA
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';

class VendorProductsScreen extends StatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  State<VendorProductsScreen> createState() => _VendorProductsScreenState();
}

class _VendorProductsScreenState extends State<VendorProductsScreen> {
  final ApiService _apiService = ApiService();

  // Data
  List<Product> _products = [];

  // Pagination State
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  // Filtering
  String? _selectedCategory;
  bool? _availabilityFilter;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadProducts(isRefresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _products.clear();
      });
    }

    try {
      final products = await _apiService.getVendorProducts(
        category: _selectedCategory,
        isAvailable: _availabilityFilter,
        page: _currentPage,
        pageSize: _pageSize,
      );

      // Client-side search logic if needed, but ideally search should be server-side along with pagination.
      // Since the API doesn't support search param yet in getVendorProducts signature shown,
      // we can only filter what we have locally or request search implementation.
      // Assuming for now we just show what we get. The previous filter was client-side on ALL products.
      // Pagination breaks client-side *global* filtering unless we fetch everything.
      // Let's stick to simple pagination for now. If search is active, pagination might behave weirdly unless supported by backend.

      // Basic filtering for currently loaded items if search query exists (not ideal for pagination)
      // If search is critical, we should search all or ask backend to search.
      // Proceeding with basic pagination logic.

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _products = products;
          } else {
            _products.addAll(products);
          }

          _isFirstLoad = false;
          _isLoadingMore = false;

          if (products.length < _pageSize) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.vendorProductsLoadError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadProducts(isRefresh: false);
  }

  // Note: Client-side filtering while pagination is active interacts poorly.
  // We'll keep the search bar but it will only filter *visible* items for now,
  // or we can disable search until backend supports it.
  // Let's implement local filtering on the _products list for display.
  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (p.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _toggleAvailability(Product product) async {
    try {
      await _apiService.updateProductAvailability(
        product.id,
        !product.isAvailable,
      );

      // Update locally to avoid full reload
      setState(() {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          // We need to create a new Product instance since it might be immutable or just for clean state
          // Assuming Product has copyWith, if not we construct new one or just rely on reload if preferred.
          // Since Product is immutable usually, we might not have copyWith.
          // Let's just reload to be safe and consistent with previous code.
          _loadProducts(isRefresh: true);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              product.isAvailable
                  ? AppLocalizations.of(
                      context,
                    )!.vendorProductsSetOutOfStock(product.name)
                  : AppLocalizations.of(
                      context,
                    )!.vendorProductsSetInStock(product.name),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorWithMessage(e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: localizations.vendorProductsDeleteTitle,
        message: localizations.vendorProductsDeleteConfirmation(product.name),
        confirmText: localizations.delete,
        cancelText: localizations.cancel,
        icon: Icons.delete_outline,
        iconColor: Colors.red,
        confirmButtonColor: Colors.red,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteProduct(product.id);
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations.vendorProductsDeleteSuccess(product.name),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.errorWithMessage(e.toString())),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final displayProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VendorHeader(
        title: localizations.vendorProductsTitle,
        leadingIcon: Icons.inventory_2_outlined,
        showBackButton: false,
        onRefresh: () => _loadProducts(isRefresh: true),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: localizations.vendorProductsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Products list
          Expanded(
            child: RefreshIndicator(
              color: Colors.white,
              backgroundColor: Colors.deepPurple,
              onRefresh: () => _loadProducts(isRefresh: true),
              child: _isFirstLoad
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : displayProducts.isEmpty && !_isLoadingMore
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
                            localizations.vendorProductsEmpty,
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
                                NoSlidePageRoute(
                                  builder: (context) =>
                                      const VendorProductFormScreen(),
                                ),
                              );
                              if (result == true) {
                                _loadProducts(isRefresh: true);
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(localizations.vendorProductsAddFirst),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.all(16),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 2,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final product = displayProducts[index];
                              return ProductCard(
                                product: product,
                                onTap: () async {
                                  TapLogger.logTap(
                                    'Product #${product.id}',
                                    action: localizations.edit,
                                  );
                                  final result = await Navigator.push(
                                    context,
                                    NoSlidePageRoute(
                                      builder: (context) =>
                                          VendorProductFormScreen(
                                            product: product,
                                          ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadProducts(isRefresh: true);
                                  }
                                },
                                onToggleAvailability: () =>
                                    _toggleAvailability(product),
                                onDelete: () => _deleteProduct(product),
                              );
                            }, childCount: displayProducts.length),
                          ),
                        ),
                        if (_isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ),
                          ),
                        // Safe area spacing at bottom
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
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
            NoSlidePageRoute(
              builder: (context) => const VendorProductFormScreen(),
            ),
          );
          if (result == true) _loadProducts(isRefresh: true);
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          localizations.vendorProductsAddNew,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 2),
    );
  }
}

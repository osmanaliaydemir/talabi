import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/product_list_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  // Search state
  String _currentQuery = '';
  List<AutocompleteResultDto> _autocompleteResults = [];
  bool _showAutocomplete = false;

  // Products search
  PagedResultDto<ProductDto>? _productResults;
  bool _isLoadingProducts = false;

  // Vendors search
  PagedResultDto<VendorDto>? _vendorResults;
  bool _isLoadingVendors = false;

  // Filters
  String? _selectedCategoryId;
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  double? _maxDistance;
  String? _sortBy;

  // Filter options
  List<Map<String, dynamic>> _categories = [];
  List<String> _cities = [];

  // Search history
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilterOptions();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _showAutocomplete = false;
        _autocompleteResults = [];
      });
      return;
    }

    _performAutocomplete(query);
  }

  Future<void> _loadFilterOptions() async {
    try {
      final categories = await _apiService.getCategories(
        language: AppLocalizations.of(context)?.localeName,
      );
      final cities = await _apiService.getCities();
      setState(() {
        _categories = categories;
        _cities = cities;
      });
    } catch (e) {
      print('Error loading filter options: $e');
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];

      // Remove if exists and add to beginning
      history.remove(query);
      history.insert(0, query);

      // Keep only last 10
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }

      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  Future<void> _performAutocomplete(String query) async {
    try {
      final results = await _apiService.autocomplete(query);
      setState(() {
        _autocompleteResults = results;
        _showAutocomplete = true;
      });
    } catch (e) {
      print('Error performing autocomplete: $e');
    }
  }

  Future<void> _searchProducts() async {
    if (_currentQuery.isEmpty &&
        _selectedCategoryId == null &&
        _minPrice == null &&
        _maxPrice == null) {
      setState(() {
        _productResults = null;
      });
      return;
    }

    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final request = ProductSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
      );

      final results = await _apiService.searchProducts(request);
      setState(() {
        _productResults = results;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.searchError(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _searchVendors() async {
    if (_currentQuery.isEmpty &&
        _selectedCity == null &&
        _minRating == null &&
        _maxDistance == null) {
      setState(() {
        _vendorResults = null;
      });
      return;
    }

    setState(() {
      _isLoadingVendors = true;
    });

    try {
      final request = VendorSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        city: _selectedCity,
        minRating: _minRating,
        maxDistanceInKm: _maxDistance,
        sortBy: _sortBy,
      );

      final results = await _apiService.searchVendors(request);
      setState(() {
        _vendorResults = results;
        _isLoadingVendors = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingVendors = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.searchError(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  void _onSearchSubmitted(String query) {
    setState(() {
      _currentQuery = query;
      _showAutocomplete = false;
    });

    _saveToSearchHistory(query);
    _searchProducts();
    _searchVendors();
  }

  void _onAutocompleteSelected(AutocompleteResultDto result) {
    setState(() {
      _searchController.text = result.name;
      _currentQuery = result.name;
      _showAutocomplete = false;
    });

    _saveToSearchHistory(result.name);
    _searchProducts();
    _searchVendors();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFiltersSheet(),
    );
  }

  Widget _buildFiltersSheet() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.filters,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedCity = null;
                    _minPrice = null;
                    _maxPrice = null;
                    _minRating = null;
                    _maxDistance = null;
                    _sortBy = null;
                  });
                  _searchProducts();
                  _searchVendors();
                  Navigator.pop(context);
                },
                child: Text(l10n.clear),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category filter (for products)
          if (_tabController.index == 0) ...[
            Text(
              l10n.category,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.selectCategory,
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category['id'].toString(),
                  child: Text(category['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Price range
            Text(
              l10n.priceRange,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.minPrice,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _minPrice = value.isEmpty ? null : double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.maxPrice,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxPrice = value.isEmpty ? null : double.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
          ],

          // City and Rating filter (for vendors)
          if (_tabController.index == 1) ...[
            Text(
              l10n.city,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.selectCity,
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Rating filter
            Text(
              l10n.minimumRating,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _minRating ?? 0.0,
              min: 0.0,
              max: 5.0,
              divisions: 10,
              label: _minRating?.toStringAsFixed(1) ?? '0.0',
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Distance filter
            Text(
              l10n.maximumDistance,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.distanceKm,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _maxDistance = value.isEmpty ? null : double.tryParse(value);
              },
            ),
          ],

          const SizedBox(height: 16),

          // Sort options
          Text(
            l10n.sortBy,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.selectSortBy,
            ),
            items: _tabController.index == 0
                ? [
                    DropdownMenuItem(
                      value: 'price_asc',
                      child: Text(l10n.priceLowToHigh),
                    ),
                    DropdownMenuItem(
                      value: 'price_desc',
                      child: Text(l10n.priceHighToLow),
                    ),
                    DropdownMenuItem(
                      value: 'name',
                      child: Text(l10n.sortByName),
                    ),
                    DropdownMenuItem(value: 'newest', child: Text(l10n.newest)),
                  ]
                : [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text(l10n.sortByName),
                    ),
                    DropdownMenuItem(value: 'newest', child: Text(l10n.newest)),
                    DropdownMenuItem(
                      value: 'rating_desc',
                      child: Text(l10n.ratingHighToLow),
                    ),
                    DropdownMenuItem(
                      value: 'popularity',
                      child: Text(l10n.popularity),
                    ),
                    DropdownMenuItem(
                      value: 'distance',
                      child: Text(l10n.distance),
                    ),
                  ],
            onChanged: (value) {
              setState(() {
                _sortBy = value;
              });
            },
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _searchProducts();
                _searchVendors();
                Navigator.pop(context);
              },
              child: Text(l10n.applyFilters),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: l10n.searchProductsOrVendors,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _onSearchSubmitted,
          autofocus: true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _searchProducts();
            _searchVendors();
          },
          tabs: [
            Tab(text: l10n.products),
            Tab(text: l10n.vendors),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [_buildProductsTab(), _buildVendorsTab()],
          ),
          if (_showAutocomplete && _searchController.text.isNotEmpty)
            _buildAutocompleteOverlay(),
        ],
      ),
    );
  }

  Widget _buildAutocompleteOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          color: Colors.white,
          child: _autocompleteResults.isEmpty && _searchHistory.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  shrinkWrap: true,
                  children: [
                    if (_autocompleteResults.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppLocalizations.of(context)!.suggestions,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ..._autocompleteResults.map((result) {
                        final l10n = AppLocalizations.of(context)!;
                        return ListTile(
                          leading: Icon(
                            result.type == 'product'
                                ? Icons.shopping_bag
                                : Icons.store,
                          ),
                          title: Text(result.name),
                          subtitle: Text(
                            result.type == 'product'
                                ? l10n.product
                                : l10n.vendor,
                          ),
                          onTap: () => _onAutocompleteSelected(result),
                        );
                      }),
                    ],
                    if (_searchHistory.isNotEmpty &&
                        _autocompleteResults.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          AppLocalizations.of(context)!.searchHistory,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ..._searchHistory.take(5).map((query) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query),
                          onTap: () {
                            _searchController.text = query;
                            _onSearchSubmitted(query);
                          },
                        );
                      }),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    if (_isLoadingProducts) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_productResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.typeToSearch,
              style: const TextStyle(color: Colors.grey),
            ),
            if (_searchHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.recentSearches,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._searchHistory.take(5).map((query) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(query),
                  onTap: () {
                    _searchController.text = query;
                    _onSearchSubmitted(query);
                  },
                );
              }),
            ],
          ],
        ),
      );
    }

    if (_productResults!.items.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noResultsFound));
    }

    final cart = Provider.of<CartProvider>(context, listen: false);

    return ListView.builder(
      itemCount: _productResults!.items.length,
      itemBuilder: (context, index) {
        final productDto = _productResults!.items[index];
        final product = productDto.toProduct();

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.fastfood, size: 60);
                    },
                  )
                : const Icon(Icons.fastfood, size: 60),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.description != null) Text(product.description!),
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
            trailing: IconButton(
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () {
                cart
                    .addItem(product, context)
                    .then((_) {
                      final l10n = AppLocalizations.of(context)!;
                      ToastMessage.show(
                        context,
                        message: l10n.productAddedToCart(product.name),
                        isSuccess: true,
                      );
                    })
                    .catchError((e) {
                      // Error is handled by CartProvider (popup shown)
                    });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildVendorsTab() {
    if (_isLoadingVendors) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      );
    }

    if (_vendorResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Arama yapmak için yukarıdaki kutuya yazın',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_vendorResults!.items.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noResultsFound));
    }

    return ListView.builder(
      itemCount: _vendorResults!.items.length,
      itemBuilder: (context, index) {
        final vendorDto = _vendorResults!.items[index];
        final vendor = vendorDto.toVendor();

        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: vendor.imageUrl != null
                ? Image.network(
                    vendor.imageUrl!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.store, size: 50),
            title: Text(vendor.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.address),
                if (vendor.city != null)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(l10n.cityLabel(vendor.city!));
                    },
                  ),
                if (vendor.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        ' ${vendor.rating!.toStringAsFixed(1)} (${vendor.ratingCount})',
                      ),
                    ],
                  ),
                if (vendor.distanceInKm != null)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return Text(
                        l10n.distanceLabel(
                          vendor.distanceInKm!.toStringAsFixed(1),
                        ),
                      );
                    },
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(vendor: vendor),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

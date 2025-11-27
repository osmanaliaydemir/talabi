import 'package:flutter/material.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/product_list_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:provider/provider.dart';
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
  String? _selectedCategory;
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  double? _maxDistance;
  String? _sortBy;

  // Filter options
  List<String> _categories = [];
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
      final categories = await _apiService.getCategories();
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
        _selectedCategory == null &&
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
        category: _selectedCategory,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arama hatası: $e')));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Arama hatası: $e')));
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtreler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
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
                child: const Text('Temizle'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category filter (for products)
          if (_tabController.index == 0) ...[
            const Text(
              'Kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Kategori seçin',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Price range
            const Text(
              'Fiyat Aralığı',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Min Fiyat',
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
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Max Fiyat',
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
            const Text('Şehir', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Şehir seçin',
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
            const Text(
              'Minimum Rating',
              style: TextStyle(fontWeight: FontWeight.bold),
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
            const Text(
              'Maksimum Mesafe (km)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mesafe (km)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _maxDistance = value.isEmpty ? null : double.tryParse(value);
              },
            ),
          ],

          const SizedBox(height: 16),

          // Sort options
          const Text('Sıralama', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Sıralama seçin',
            ),
            items: _tabController.index == 0
                ? [
                    const DropdownMenuItem(
                      value: 'price_asc',
                      child: Text('Fiyat (Düşükten Yükseğe)'),
                    ),
                    const DropdownMenuItem(
                      value: 'price_desc',
                      child: Text('Fiyat (Yüksekten Düşüğe)'),
                    ),
                    const DropdownMenuItem(
                      value: 'name',
                      child: Text('İsme Göre'),
                    ),
                    const DropdownMenuItem(
                      value: 'newest',
                      child: Text('En Yeni'),
                    ),
                  ]
                : [
                    const DropdownMenuItem(
                      value: 'name',
                      child: Text('İsme Göre'),
                    ),
                    const DropdownMenuItem(
                      value: 'newest',
                      child: Text('En Yeni'),
                    ),
                    const DropdownMenuItem(
                      value: 'rating_desc',
                      child: Text('Rating (Yüksekten Düşüğe)'),
                    ),
                    const DropdownMenuItem(
                      value: 'popularity',
                      child: Text('Popülerlik'),
                    ),
                    const DropdownMenuItem(
                      value: 'distance',
                      child: Text('Mesafe'),
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
              child: const Text('Filtreleri Uygula'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Ürün veya market ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
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
          tabs: const [
            Tab(text: 'Ürünler'),
            Tab(text: 'Marketler'),
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
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Öneriler',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ..._autocompleteResults.map((result) {
                        return ListTile(
                          leading: Icon(
                            result.type == 'product'
                                ? Icons.shopping_bag
                                : Icons.store,
                          ),
                          title: Text(result.name),
                          subtitle: Text(
                            result.type == 'product' ? 'Ürün' : 'Market',
                          ),
                          onTap: () => _onAutocompleteSelected(result),
                        );
                      }),
                    ],
                    if (_searchHistory.isNotEmpty &&
                        _autocompleteResults.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Arama Geçmişi',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
      return Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (_productResults == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Arama yapmak için yukarıdaki kutuya yazın',
              style: TextStyle(color: Colors.grey),
            ),
            if (_searchHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Son Aramalar',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      return const Center(child: Text('Sonuç bulunamadı'));
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} sepete eklendi'),
                          duration: const Duration(seconds: 1),
                        ),
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
      return Center(child: CircularProgressIndicator(color: Colors.orange));
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
      return const Center(child: Text('Sonuç bulunamadı'));
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
                if (vendor.city != null) Text('Şehir: ${vendor.city}'),
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
                  Text('Mesafe: ${vendor.distanceInKm!.toStringAsFixed(1)} km'),
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

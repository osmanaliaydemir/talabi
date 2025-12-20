import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';

import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Search state
  String _currentQuery = '';
  List<AutocompleteResultDto> _autocompleteResults = [];
  bool _showAutocomplete = false;

  // Products search
  List<ProductDto> _productItems = [];
  int _productCurrentPage = 1;
  static const int _productPageSize = 20;
  bool _isLoadingProducts = false;
  bool _isLoadingMoreProducts = false;
  bool _hasMoreProducts = true;

  // Vendors search
  List<VendorDto> _vendorItems = [];
  int _vendorCurrentPage = 1;
  static const int _vendorPageSize = 20;
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

  // Flag to ensure filter options are loaded only once
  bool _hasLoadedFilterOptions = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadSearchHistory();
    _searchController
      ..addListener(_onSearchChanged)
      ..addListener(() {
        setState(() {}); // Rebuild to show/hide clear button
      });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreProducts &&
        _hasMoreProducts &&
        !_isLoadingProducts) {
      _loadMoreProducts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load filter options after context is available
    if (!_hasLoadedFilterOptions) {
      _hasLoadedFilterOptions = true;
      _loadFilterOptions();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _scrollController
      ..removeListener(_scrollListener)
      ..dispose();
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
        language: AppLocalizations.of(context)?.localeName ?? 'en',
      );
      final cities = await _apiService.getCities();
      setState(() {
        _categories = categories;
        _cities = cities;
      });
    } catch (e, stackTrace) {
      LoggerService().error('Error loading filter options', e, stackTrace);
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      setState(() {
        _searchHistory = history;
      });
    } catch (e, stackTrace) {
      LoggerService().error('Error loading search history', e, stackTrace);
    }
  }

  Future<void> _saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? []
        // Remove if exists and add to beginning, keep only last 10
        ..remove(query)
        ..insert(0, query);
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }

      await prefs.setStringList('search_history', history);
      setState(() {
        _searchHistory = history;
      });
    } catch (e, stackTrace) {
      LoggerService().error('Error saving search history', e, stackTrace);
    }
  }

  Future<void> _performAutocomplete(String query) async {
    try {
      final results = await _apiService.autocomplete(query);
      setState(() {
        _autocompleteResults = results;
        _showAutocomplete = true;
      });
    } catch (e, stackTrace) {
      LoggerService().error('Error performing autocomplete', e, stackTrace);
    }
  }

  Future<void> _searchProducts({bool isRefresh = true}) async {
    if (_currentQuery.isEmpty &&
        _selectedCategoryId == null &&
        _minPrice == null &&
        _maxPrice == null) {
      setState(() {
        _productItems = [];
        _productCurrentPage = 1;
        _hasMoreProducts = false;
      });
      return;
    }

    if (isRefresh) {
      setState(() {
        _isLoadingProducts = true;
        _productCurrentPage = 1;
        _hasMoreProducts = true;
        _productItems = [];
      });
    } else {
      setState(() {
        _isLoadingMoreProducts = true;
      });
    }

    try {
      final request = ProductSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
        page: _productCurrentPage,
        pageSize: _productPageSize,
      );

      final results = await _apiService.searchProducts(request);
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _productItems = results.items;
          } else {
            _productItems.addAll(results.items);
          }
          _isLoadingProducts = false;
          _isLoadingMoreProducts = false;
          _hasMoreProducts =
              results.items.length >= _productPageSize &&
              _productItems.length < results.totalCount;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _isLoadingMoreProducts = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.searchError(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;
    _productCurrentPage++;
    await _searchProducts(isRefresh: false);
  }

  Future<void> _searchVendors({bool isRefresh = true}) async {
    if (_currentQuery.isEmpty &&
        _selectedCity == null &&
        _minRating == null &&
        _maxDistance == null) {
      setState(() {
        _vendorItems = [];
        _vendorCurrentPage = 1;
        _isLoadingVendors = false;
      });
      return;
    }

    if (isRefresh) {
      setState(() {
        _isLoadingVendors = true;
        _vendorCurrentPage = 1;
        _vendorItems = [];
      });
    } else {
      // Pagination not supported in merged view for vendors yet
      return;
    }

    try {
      final request = VendorSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        city: _selectedCity,
        minRating: _minRating,
        maxDistanceInKm: _maxDistance,
        sortBy: _sortBy,
        page: _vendorCurrentPage,
        pageSize: _vendorPageSize,
      );

      final results = await _apiService.searchVendors(request);
      if (mounted) {
        setState(() {
          if (isRefresh) {
            _vendorItems = results.items;
          } else {
            _vendorItems.addAll(results.items);
          }
          _isLoadingVendors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVendors = false;
        });
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
    AnalyticsService.logSearch(searchTerm: query);
    _searchProducts();
    _searchVendors();
  }

  void _onAutocompleteSelected(AutocompleteResultDto result) {
    if (result.type == 'product') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: result.id),
        ),
      );
    } else if (result.type == 'vendor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VendorDetailScreen(
            vendorId: result.id,
            vendorName: result.name,
            vendorImageUrl: result.imageUrl,
          ),
        ),
      );
    } else {
      // Fallback
      setState(() {
        _searchController.text = result.name;
        _currentQuery = result.name;
        _showAutocomplete = false;
      });

      _saveToSearchHistory(result.name);
      AnalyticsService.logSearch(searchTerm: result.name);
      _searchProducts();
      _searchVendors();
    }
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
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(
                vertical: AppTheme.spacingSmall,
              ),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.filters,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
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
                  child: Text(
                    l10n.clear,
                    style: AppTheme.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter (for products)
                  Text(
                    l10n.category,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: AppTheme.inputDecoration(
                      hint: l10n.selectCategory,
                    ),
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
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
                  const SizedBox(height: AppTheme.spacingLarge),

                  // Price range
                  Text(
                    l10n.priceRange,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: AppTheme.inputDecoration(
                            hint: l10n.minPrice,
                          ),
                          style: AppTheme.poppins(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _minPrice = value.isEmpty
                                ? null
                                : double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: TextField(
                          decoration: AppTheme.inputDecoration(
                            hint: l10n.maxPrice,
                          ),
                          style: AppTheme.poppins(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxPrice = value.isEmpty
                                ? null
                                : double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),

                  // City and Rating filter (for vendors)
                  Text(
                    l10n.city,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCity,
                    decoration: AppTheme.inputDecoration(hint: l10n.selectCity),
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
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
                  const SizedBox(height: AppTheme.spacingLarge),

                  // Rating filter
                  Text(
                    l10n.minimumRating,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                    ),
                    child: Column(
                      children: [
                        Slider(
                          value: _minRating ?? 0.0,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          activeColor: AppTheme.primaryOrange,
                          label: _minRating?.toStringAsFixed(1) ?? '0.0',
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                        Text(
                          _minRating?.toStringAsFixed(1) ?? '0.0',
                          style: AppTheme.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),

                  // Distance filter
                  Text(
                    l10n.maximumDistance,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  TextField(
                    decoration: AppTheme.inputDecoration(hint: l10n.distanceKm),
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _maxDistance = value.isEmpty
                          ? null
                          : double.tryParse(value);
                    },
                  ),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Sort options
                  Text(
                    l10n.sortBy,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  DropdownButtonFormField<String>(
                    initialValue: _sortBy,
                    decoration: AppTheme.inputDecoration(
                      hint: l10n.selectSortBy,
                    ),
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    items: [
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
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text(l10n.newest),
                      ),
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
                ],
              ),
            ),
          ),
          // Apply Button
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(
                top: BorderSide(color: AppTheme.dividerColor, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _searchProducts();
                  _searchVendors();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  l10n.applyFilters,
                  style: AppTheme.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
              ),
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: AppTheme.textOnPrimary,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spacingSmall),
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: AppTheme.textOnPrimary,
              size: 18,
            ),
          ),
        ),
        title: Text(
          l10n.searchProductsOrVendors,
          style: AppTheme.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              0,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
            ),
            child: Row(
              children: [
                Expanded(child: _buildSearchBar(l10n)),
                const SizedBox(width: AppTheme.spacingSmall),
                // Filter Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      const BoxShadow(
                        color: AppTheme.shadowColor,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFilters,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: 48,
                        height: 48,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.tune,
                              size: 24,
                              color: AppTheme.primaryOrange,
                            ),
                            if (_hasActiveFilters())
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              if (_currentQuery.isEmpty &&
                  !_hasActiveFilters() &&
                  _productItems.isEmpty &&
                  _vendorItems.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(l10n))
              else ...[
                // Vendors Section
                if (_vendorItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingMedium,
                        AppTheme.spacingMedium,
                        AppTheme.spacingMedium,
                        AppTheme.spacingSmall,
                      ),
                      child: Text(
                        l10n.vendors,
                        style: AppTheme.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final vendor = _vendorItems[index].toVendor();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                        ),
                        child: _buildVendorCard(vendor, l10n),
                      );
                    }, childCount: _vendorItems.length),
                  ),
                ],

                // Products Section
                if (_productItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingMedium,
                        AppTheme.spacingMedium,
                        AppTheme.spacingMedium,
                        AppTheme.spacingSmall,
                      ),
                      child: Text(
                        l10n.products,
                        style: AppTheme.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                    ),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: AppTheme.spacingSmall,
                            mainAxisSpacing: AppTheme.spacingSmall,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = _productItems[index].toProduct();
                        return ProductCard(
                          product: product,
                          width: null,
                          showRating: false,
                          onTap: () {
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
                        );
                      }, childCount: _productItems.length),
                    ),
                  ),
                ],

                // Loading Indicators
                if (_isLoadingProducts || _isLoadingVendors)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                if (_productItems.isEmpty &&
                    _vendorItems.isEmpty &&
                    !_isLoadingProducts &&
                    !_isLoadingVendors)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          Text(
                            l10n.noResultsFound,
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (_showAutocomplete && _searchController.text.isNotEmpty)
            _buildAutocompleteOverlay(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                size: 64,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              l10n.typeToSearch,
              style: AppTheme.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              l10n.searchProductsOrVendors,
              textAlign: TextAlign.center,
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (_searchHistory.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingXLarge),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    const BoxShadow(
                      color: AppTheme.shadowColor,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.history,
                          size: 20,
                          color: AppTheme.primaryOrange,
                        ),
                        const SizedBox(width: AppTheme.spacingSmall),
                        Text(
                          l10n.recentSearches,
                          style: AppTheme.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    ..._searchHistory.take(5).map((query) {
                      return _buildHistoryChip(query);
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          const BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        autofocus: false,
        style: AppTheme.poppins(fontSize: 16, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: l10n.searchProductsOrVendors,
          hintStyle: AppTheme.poppins(fontSize: 16, color: AppTheme.textHint),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentQuery = '';
                      _showAutocomplete = false;
                      _productItems = [];
                      _vendorItems = [];
                      _productCurrentPage = 1;
                      _vendorCurrentPage = 1;
                      _hasMoreProducts = false;
                      _isLoadingVendors = false;
                      _selectedCategoryId =
                          null; // Clear filters too or keep them? Keeping them for now.
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
        ),
        onSubmitted: _onSearchSubmitted,
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedCity != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _minRating != null ||
        _maxDistance != null ||
        _sortBy != null;
  }

  Widget _buildAutocompleteOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: AppTheme.overlayColor.withValues(alpha: 0.3),
        child: Material(
          elevation: AppTheme.elevationHigh,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.radiusLarge),
            bottomRight: Radius.circular(AppTheme.radiusLarge),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusLarge),
                bottomRight: Radius.circular(AppTheme.radiusLarge),
              ),
            ),
            child: _autocompleteResults.isEmpty && _searchHistory.isEmpty
                ? const SizedBox.shrink()
                : ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      if (_autocompleteResults.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundColor,
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 20,
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(width: AppTheme.spacingSmall),
                              Text(
                                l10n.suggestions,
                                style: AppTheme.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._autocompleteResults.map((result) {
                          return _buildAutocompleteItem(result);
                        }),
                      ],
                      if (_searchHistory.isNotEmpty &&
                          _autocompleteResults.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundColor,
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.dividerColor,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                size: 20,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: AppTheme.spacingSmall),
                              Text(
                                l10n.searchHistory,
                                style: AppTheme.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ..._searchHistory.take(5).map((query) {
                          return _buildHistoryItem(query);
                        }),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutocompleteItem(AutocompleteResultDto result) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onAutocompleteSelected(result),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: result.type == 'product'
                      ? AppTheme.primaryOrange.withValues(alpha: 0.1)
                      : AppTheme.vendorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  result.type == 'product' ? Icons.shopping_bag : Icons.store,
                  size: 20,
                  color: result.type == 'product'
                      ? AppTheme.primaryOrange
                      : AppTheme.vendorPrimary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      style: AppTheme.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.type == 'product' ? l10n.product : l10n.vendor,
                      style: AppTheme.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String query) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _searchController.text = query;
          _onSearchSubmitted(query);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.history,
                size: 20,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Text(
                  query,
                  style: AppTheme.poppins(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryChip(String? query) {
    if (query == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _searchController.text = query;
            _onSearchSubmitted(query);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.dividerColor, width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Text(
                    query,
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Card(
        elevation: AppTheme.elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorDetailScreen(vendor: vendor),
                ),
              );
            },
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: CachedNetworkImageWidget(
                          imageUrl: vendor.imageUrl ?? '',
                          fit: BoxFit.cover,
                          maxWidth: 600, // Optimize memory for card width
                          maxHeight: 300,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppTheme.primaryOrange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (vendor.rating ?? 0.0).toStringAsFixed(1),
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: AppTheme.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vendor.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

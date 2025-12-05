import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/search_dtos.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/screens/customer/product/product_list_screen.dart';
import 'package:mobile/screens/customer/product/product_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/screens/customer/widgets/product_card.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';
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

  // Flag to ensure filter options are loaded only once
  bool _hasLoadedFilterOptions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to show/hide clear button
    });
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
    AnalyticsService.logSearch(searchTerm: query);
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
    AnalyticsService.logSearch(searchTerm: result.name);
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
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.only(
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
                  if (_tabController.index == 0) ...[
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
                      value: _selectedCategoryId,
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
                  ],

                  // City and Rating filter (for vendors)
                  if (_tabController.index == 1) ...[
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
                      value: _selectedCity,
                      decoration: AppTheme.inputDecoration(
                        hint: l10n.selectCity,
                      ),
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
                      decoration: AppTheme.inputDecoration(
                        hint: l10n.distanceKm,
                      ),
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
                  ],

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
                    value: _sortBy,
                    decoration: AppTheme.inputDecoration(
                      hint: l10n.selectSortBy,
                    ),
                    style: AppTheme.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
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
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text(l10n.newest),
                            ),
                          ]
                        : [
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
            decoration: BoxDecoration(
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
            margin: EdgeInsets.all(AppTheme.spacingSmall),
            padding: EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
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
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: _buildSearchBar(l10n),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter and Tabs Row
          Container(
            color: AppTheme.cardColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: Row(
              children: [
                // Filter Button
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFilters,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingSmall,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 20,
                              color: AppTheme.primaryOrange,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Text(
                              l10n.filters,
                              style: AppTheme.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                // Active Filters Count
                if (_hasActiveFilters())
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getActiveFiltersCount().toString(),
                      style: AppTheme.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Tabs
          Container(
            color: AppTheme.cardColor,
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                _searchProducts();
                _searchVendors();
              },
              indicatorColor: AppTheme.primaryOrange,
              indicatorWeight: 3,
              labelColor: AppTheme.primaryOrange,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: AppTheme.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTheme.poppins(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(text: l10n.products),
                Tab(text: l10n.vendors),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [_buildProductsTab(), _buildVendorsTab()],
                ),
                if (_showAutocomplete && _searchController.text.isNotEmpty)
                  _buildAutocompleteOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentQuery = '';
                      _showAutocomplete = false;
                      _productResults = null;
                      _vendorResults = null;
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

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedCategoryId != null) count++;
    if (_selectedCity != null) count++;
    if (_minPrice != null) count++;
    if (_maxPrice != null) count++;
    if (_minRating != null) count++;
    if (_maxDistance != null) count++;
    if (_sortBy != null) count++;
    return count;
  }

  Widget _buildAutocompleteOverlay() {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Container(
        color: AppTheme.overlayColor.withOpacity(0.3),
        child: Material(
          elevation: AppTheme.elevationHigh,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppTheme.radiusLarge),
            bottomRight: Radius.circular(AppTheme.radiusLarge),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: const BorderRadius.only(
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
                          decoration: BoxDecoration(
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
                              Icon(
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
                          decoration: BoxDecoration(
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
                              Icon(
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
                      ? AppTheme.primaryOrange.withOpacity(0.1)
                      : AppTheme.vendorPrimary.withOpacity(0.1),
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
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textHint),
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
              Icon(Icons.history, size: 20, color: AppTheme.textSecondary),
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

  Widget _buildProductsTab() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingProducts) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
          strokeWidth: 3,
        ),
      );
    }

    if (_productResults == null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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
                        BoxShadow(
                          color: AppTheme.shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
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
        ),
      );
    }

    if (_productResults!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.textHint),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              l10n.noResultsFound,
              style: AppTheme.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              l10n.searchProductsOrVendors,
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppTheme.spacingSmall,
        mainAxisSpacing: AppTheme.spacingSmall,
      ),
      itemCount: _productResults!.items.length,
      itemBuilder: (context, index) {
        final productDto = _productResults!.items[index];
        final product = productDto.toProduct();

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
      },
    );
  }

  Widget _buildHistoryChip(String query) {
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
                Icon(Icons.history, size: 16, color: AppTheme.textSecondary),
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

  Widget _buildVendorsTab() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoadingVendors) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
          strokeWidth: 3,
        ),
      );
    }

    if (_vendorResults == null) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.vendorPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store,
                    size: 64,
                    color: AppTheme.vendorPrimary,
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
              ],
            ),
          ),
        ),
      );
    }

    if (_vendorResults!.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: AppTheme.textHint),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              l10n.noResultsFound,
              style: AppTheme.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              l10n.searchProductsOrVendors,
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingSmall),
      itemCount: _vendorResults!.items.length,
      itemBuilder: (context, index) {
        final vendorDto = _vendorResults!.items[index];
        final vendor = vendorDto.toVendor();

        return _buildVendorCard(vendor, l10n);
      },
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
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductListScreen(vendor: vendor),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      color: AppTheme.backgroundColor,
                    ),
                    child: vendor.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            child: OptimizedCachedImage.vendorLogo(
                              imageUrl: vendor.imageUrl!,
                              width: 80,
                              height: 80,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.store,
                            size: 40,
                            color: AppTheme.vendorPrimary,
                          ),
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  // Vendor Info
                  Expanded(
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (vendor.address.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  vendor.address,
                                  style: AppTheme.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        if (vendor.city != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.cityLabel(vendor.city!),
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (vendor.rating != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      vendor.rating!.toStringAsFixed(1),
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[900],
                                      ),
                                    ),
                                    if (vendor.ratingCount > 0) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${vendor.ratingCount})',
                                        style: AppTheme.poppins(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (vendor.distanceInKm != null)
                                const SizedBox(width: AppTheme.spacingSmall),
                            ],
                            if (vendor.distanceInKm != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.navigation,
                                      size: 14,
                                      color: AppTheme.info,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.distanceLabel(
                                        vendor.distanceInKm!.toStringAsFixed(1),
                                      ),
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        color: AppTheme.info,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppTheme.textHint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

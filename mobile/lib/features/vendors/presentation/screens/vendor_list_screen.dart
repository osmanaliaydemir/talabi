import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/empty_state_widget.dart';

import 'package:provider/provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final ApiService _apiService = ApiService();

  // Data
  List<Vendor> _vendors = [];

  // Pagination State
  int _currentPage = 1;
  static const int _pageSize = 6;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  int? _currentVendorType;
  late ScrollController _scrollController;
  Map<String, dynamic>? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadAddresses();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreVendors();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomNav = Provider.of<BottomNavProvider>(context, listen: true);
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;

    if (_currentVendorType != vendorType) {
      _currentVendorType = vendorType;
      // Adresler yüklendikten sonra vendor'ları yükle
      if (_selectedAddress != null) {
        _loadVendors(isRefresh: true);
      }
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await _apiService.getAddresses();
      if (mounted) {
        Map<String, dynamic>? selectedAddress;
        if (addresses.isNotEmpty) {
          try {
            selectedAddress = addresses.firstWhere(
              (addr) => addr['isDefault'] == true,
            );
          } catch (_) {
            selectedAddress = addresses.first;
          }
        }

        setState(() {
          _selectedAddress = selectedAddress;
        });

        // Adresler yüklendikten sonra vendor'ları yükle
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _currentVendorType != null) {
            _loadVendors(isRefresh: true);
          }
        });
      }
    } catch (e) {
      // Hata olsa bile vendor'ları yüklemeyi dene (konum olmadan)
      if (mounted && _currentVendorType != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadVendors(isRefresh: true);
          }
        });
      }
    }
  }

  Future<void> _loadVendors({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _vendors.clear();
      });
    }

    // Get location from selected address
    double? userLatitude;
    double? userLongitude;
    if (_selectedAddress != null) {
      userLatitude = _selectedAddress!['latitude'] != null
          ? double.tryParse(_selectedAddress!['latitude'].toString())
          : null;
      userLongitude = _selectedAddress!['longitude'] != null
          ? double.tryParse(_selectedAddress!['longitude'].toString())
          : null;
    }

    try {
      final vendors = await _apiService.getVendors(
        vendorType: _currentVendorType,
        page: _currentPage,
        pageSize: _pageSize,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _vendors = vendors;
          } else {
            _vendors.addAll(vendors);
          }

          _isFirstLoad = false;
          _isLoadingMore = false;

          if (vendors.length < _pageSize) {
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
      }
    }
  }

  Future<void> _loadMoreVendors() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadVendors(isRefresh: false);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SharedHeader(
            title: localizations.popularVendors,
            subtitle: _vendors.isNotEmpty
                ? localizations.vendorsCount(_vendors.length)
                : null,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            icon: Icons.store,
          ),
          Expanded(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                await _loadAddresses();
                _loadVendors(isRefresh: true);
              },
              child: _isFirstLoad
                  ? const Center(child: CircularProgressIndicator())
                  : _vendors.isEmpty
                  ? EmptyStateWidget(
                      message: localizations.noVendorsInArea,
                      subMessage: localizations.noVendorsInAreaSub,
                      iconData: Icons.store_outlined,
                      isCompact: true,
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      itemCount: _vendors.length + (_isLoadingMore ? 1 : 0),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppTheme.spacingMedium),
                      itemBuilder: (context, index) {
                        if (index == _vendors.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildVendorCard(_vendors[index]);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailScreen(vendor: vendor),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.cardDecoration(color: Theme.of(context).cardColor),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  vendor.imageUrl != null
                      ? OptimizedCachedImage.vendorLogo(
                          imageUrl: vendor.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        )
                      : Container(
                          color: AppTheme.textSecondary.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.store,
                            size: 50,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                  if (vendor.rating != null && vendor.rating! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: AppTheme.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              vendor.rating!.toStringAsFixed(1),
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
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
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
                        const Icon(
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
                  if (vendor.distanceInKm != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.navigation,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${vendor.distanceInKm!.toStringAsFixed(1)} km',
                          style: AppTheme.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

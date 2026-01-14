import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/empty_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/vendors/presentation/providers/vendor_list_provider.dart';
import 'package:mobile/features/home/presentation/providers/home_provider.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  int? _currentVendorType;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Initial load check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initData();
      }
    });
  }

  void _initData() {
    final homeProvider = context.read<HomeProvider>();
    if (homeProvider.addresses.isEmpty) {
      homeProvider.loadAddresses().then((_) {
        if (mounted) _loadVendors(isRefresh: true);
      });
    } else {
      _loadVendors(isRefresh: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final vendorListProvider = context.read<VendorListProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !vendorListProvider.isLoadingMore &&
        vendorListProvider.hasMoreData) {
      _loadMoreVendors();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomNav = context.watch<BottomNavProvider>();
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;

    if (_currentVendorType != vendorType) {
      _currentVendorType = vendorType;
      // Load vendors if addresses are already ready
      final homeProvider = context.read<HomeProvider>();
      if (homeProvider.addresses.isNotEmpty) {
        _loadVendors(isRefresh: true);
      }
    }
  }

  Future<void> _loadVendors({bool isRefresh = false}) async {
    if (_currentVendorType == null) return;

    final homeProvider = context.read<HomeProvider>();
    final vendorListProvider = context.read<VendorListProvider>();

    await vendorListProvider.loadVendors(
      vendorType: _currentVendorType!,
      selectedAddress: homeProvider.selectedAddress,
      isRefresh: isRefresh,
    );
  }

  Future<void> _loadMoreVendors() async {
    if (_currentVendorType == null) return;

    final homeProvider = context.read<HomeProvider>();
    final vendorListProvider = context.read<VendorListProvider>();

    await vendorListProvider.loadVendors(
      vendorType: _currentVendorType!,
      selectedAddress: homeProvider.selectedAddress,
      isRefresh: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<VendorListProvider>(
      builder: (context, vendorListProvider, _) {
        final vendors = vendorListProvider.vendors;
        final isFirstLoad = vendorListProvider.isFirstLoad;
        final isLoadingMore = vendorListProvider.isLoadingMore;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              SharedHeader(
                title: localizations.popularVendors,
                subtitle: vendors.isNotEmpty
                    ? localizations.vendorsCount(vendors.length)
                    : null,
                showBackButton: true,
                onBack: () => Navigator.of(context).pop(),
                icon: Icons.store,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: Theme.of(context).colorScheme.primary,
                  onRefresh: () async {
                    // Update addresses via HomeProvider
                    await context.read<HomeProvider>().loadAddresses();
                    _loadVendors(isRefresh: true);
                  },
                  child: isFirstLoad
                      ? const Center(child: CircularProgressIndicator())
                      : vendors.isEmpty
                      ? EmptyStateWidget(
                          message: localizations.noVendorsInArea,
                          subMessage: localizations.noVendorsInAreaSub,
                          iconData: Icons.store_outlined,
                          isCompact: true,
                        )
                      : ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          itemCount: vendors.length + (isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppTheme.spacingMedium),
                          itemBuilder: (context, index) {
                            if (index == vendors.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            return _buildVendorCard(vendors[index]);
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
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

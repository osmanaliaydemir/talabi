import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/skeleton_loader.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';

import 'package:mobile/features/home/presentation/providers/home_provider.dart';
import 'package:mobile/features/categories/presentation/providers/category_products_provider.dart';

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryName,
    this.categoryId,
    this.imageUrl,
  });

  final String categoryName;
  final String? categoryId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CategoryProductsProvider(),
      child: _CategoryProductsContent(
        categoryName: categoryName,
        categoryId: categoryId,
        imageUrl: imageUrl,
      ),
    );
  }
}

class _CategoryProductsContent extends StatefulWidget {
  const _CategoryProductsContent({
    required this.categoryName,
    this.categoryId,
    this.imageUrl,
  });

  final String categoryName;
  final String? categoryId;
  final String? imageUrl;

  @override
  State<_CategoryProductsContent> createState() =>
      _CategoryProductsContentState();
}

class _CategoryProductsContentState extends State<_CategoryProductsContent> {
  // Track params to detect changes
  int? _loadedVendorType;
  Map<String, dynamic>? _loadedAddress;

  @override
  void initState() {
    super.initState();
    _checkLoad();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLoad();
  }

  void _checkLoad() {
    final bottomNav = context.watch<BottomNavProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final productProvider = context.read<CategoryProductsProvider>();

    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;
    final address = homeProvider.selectedAddress;

    // Only load if params changed or not loaded yet
    if (_loadedVendorType != vendorType || _loadedAddress != address) {
      if (address != null ||
          (homeProvider.addresses.isEmpty &&
              !homeProvider.isAddressesLoading &&
              homeProvider.addresses.isEmpty)) {
        // If no address, we might try to load without it or trigger address load
        if (homeProvider.addresses.isEmpty &&
            !homeProvider.isAddressesLoading) {
          // Try to load addresses if not loaded yet
          // Avoid loop if fails
          homeProvider.loadAddresses();
          // Don't mark as loaded yet
          return;
        }

        _loadedVendorType = vendorType;
        _loadedAddress = address;

        // Use addPostFrameCallback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            productProvider.loadProducts(
              categoryName: widget.categoryName,
              categoryId: widget.categoryId,
              vendorType: vendorType,
              selectedAddress: address,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.categoryName,
                style: AppTheme.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                      ? OptimizedCachedImage.banner(
                          imageUrl: widget.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.category,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const CartScreen(showBackButton: true),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        if (cart.itemCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.white, width: 1.5),
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${cart.itemCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          Consumer<CategoryProductsProvider>(
            builder: (context, provider, _) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localizations.products,
                            style: AppTheme.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (provider.totalCount != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                localizations.productsCount(
                                  provider.totalCount!,
                                ),
                                style: AppTheme.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Consumer<CategoryProductsProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMedium,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: AppTheme.spacingSmall,
                          mainAxisSpacing: AppTheme.spacingSmall,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ProductSkeletonItem(),
                      childCount: 6,
                    ),
                  ),
                );
              } else if (provider.error != null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '${localizations.error}: ${provider.error}',
                      style: AppTheme.poppins(color: AppTheme.error),
                    ),
                  ),
                );
              } else if (provider.products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          localizations.noProductsYet,
                          style: AppTheme.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = provider.products;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.spacingSmall,
                    mainAxisSpacing: AppTheme.spacingSmall,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = products[index];
                    final isFavorite = provider.isFavorite(product.id);
                    return ProductCard(
                      product: product,
                      width: null,
                      heroTagPrefix: 'category_product_',
                      isFavorite: isFavorite,
                      rating: '4.7', // Placeholder
                      ratingCount: '2.3k', // Placeholder
                      onFavoriteTap: () =>
                          provider.toggleFavorite(product).catchError((e) {
                            if (context.mounted) {
                              ToastMessage.show(
                                context,
                                message: localizations.favoriteOperationFailed(
                                  e.toString(),
                                ),
                                isSuccess: false,
                              );
                            }
                          }),
                    );
                  }, childCount: products.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

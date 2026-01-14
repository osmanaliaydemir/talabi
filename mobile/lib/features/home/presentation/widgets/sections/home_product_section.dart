import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/widgets/empty_state_widget.dart';
import 'package:mobile/widgets/skeleton_loader.dart';

class HomeProductSection extends StatelessWidget {
  const HomeProductSection({
    super.key,
    required this.products,
    required this.favoriteStatus,
    required this.onFavoriteToggle,
    required this.onViewAll,
    this.hasVendors = true,
    this.onProductsLoaded,
    this.isLoading = false,
  });

  final List<Product> products;
  final Map<String, bool> favoriteStatus;
  final Function(Product) onFavoriteToggle;
  final VoidCallback onViewAll;
  final bool hasVendors;
  final Function(bool hasProducts)? onProductsLoaded;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show skeleton if loading
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingSmall,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.picksForYou,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSmall,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                return const ProductSkeletonItem();
              },
            ),
          ),
        ],
      );
    }

    // Notify parent about product state (if needed, but provider already knows)
    if (onProductsLoaded != null) {
      // Defer to next frame to avoid build phase errors if setState is called
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onProductsLoaded!(products.isNotEmpty);
      });
    }

    // If no vendors, don't show product empty state
    if (!hasVendors) {
      return const SizedBox.shrink();
    }

    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingLarge,
        ),
        child: EmptyStateWidget(
          message: localizations.noProductsInArea,
          subMessage: localizations.noProductsInAreaSub,
          iconData: Icons.shopping_bag_outlined,
          isCompact: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingSmall),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.picksForYou,
                style: AppTheme.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  localizations.viewAll,
                  style: AppTheme.poppins(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
            ),
            itemExtent: 216.0, // 200 width + 16 margin
            cacheExtent: 200.0,
            addRepaintBoundaries: true,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                width: 200,
                heroTagPrefix: 'home_picks_',
                isFavorite: favoriteStatus[product.id] ?? false,
                rating: '4.7',
                ratingCount: '2.3k',
                onFavoriteTap: () => onFavoriteToggle(product),
              );
            },
          ),
        ),
      ],
    );
  }
}

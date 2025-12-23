import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';

class HomeProductSection extends StatelessWidget {
  const HomeProductSection({
    super.key,
    required this.productsFuture,
    required this.favoriteStatus,
    required this.onFavoriteToggle,
    required this.onViewAll,
  });

  final Future<List<Product>> productsFuture;
  final Map<String, bool> favoriteStatus;
  final Function(Product) onFavoriteToggle;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              const SizedBox(height: AppTheme.spacingSmall),
              SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data!;
        if (products.isEmpty) {
          return const SizedBox.shrink();
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
                  // RepaintBoundary is now redundant if itemExtent is used (mostly),
                  // but good to keep for complex cards.
                  // However, itemExtent implies fixed size logic.
                  // Removing explicit RepaintBoundary wrapper here because
                  // itemExtent optimizations often cover layout.
                  // But repaint isolation is still valid.
                  // I'll keep the wrapper logic but simplified?
                  // Actually, ref above removed RepaintBoundary in HomeVendorSection.
                  // I should be consistent.
                  // The RepaintBoundary was added in previous step.
                  // Let's keep it if performance plan says so.
                  // Ideally, RepaintBoundary is inside the item or checks dirty rects.
                  // I will remove the explicit wrapper closure to keep code clean if I can.
                  // Wait, ListView sends constraints.
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
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/vendors/presentation/screens/vendor_detail_screen.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/empty_state_widget.dart';

class HomeVendorSection extends StatelessWidget {
  const HomeVendorSection({
    super.key,
    required this.vendorsFuture,
    required this.onViewAll,
  });

  final Future<List<Vendor>> vendorsFuture;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<List<Vendor>>(
      future: vendorsFuture,
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

        final vendors = snapshot.data!;
        if (vendors.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingLarge,
            ),
            child: EmptyStateWidget(
              message: localizations.noVendorsInArea,
              subMessage: localizations.noVendorsInAreaSub,
              iconData: Icons.store_outlined,
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
                    localizations.popularVendors,
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
                itemExtent: 296.0, // 280 width + 16 margin
                cacheExtent: 200.0,
                addRepaintBoundaries: true,
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  return _buildVendorCardHorizontal(context, vendors[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVendorCardHorizontal(BuildContext context, Vendor vendor) {
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
        width: 280,
        margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSmall),
        child: Container(
          decoration: AppTheme.cardDecoration(
            color: Theme.of(context).cardColor,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 120,
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
                            color: AppTheme.textSecondary.withValues(
                              alpha: 0.1,
                            ),
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
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
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
      ),
    );
  }
}

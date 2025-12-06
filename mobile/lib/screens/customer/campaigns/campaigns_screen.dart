import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:mobile/widgets/common/bouncing_circle.dart';
import 'package:mobile/screens/customer/campaigns/campaign_detail_screen.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';
import 'package:provider/provider.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PromotionalBanner>> _bannersFuture;

  int? _campaignCount;

  MainCategory? _lastCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBanners();
  }

  void _loadBanners() {
    final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
    final vendorType = bottomNav.selectedCategory == MainCategory.restaurant
        ? 1
        : 2;
    final locale = AppLocalizations.of(context)?.localeName ?? 'tr';
    _bannersFuture = _apiService
        .getBanners(language: locale, vendorType: vendorType)
        .then((banners) {
          if (mounted) {
            setState(() {
              _campaignCount = banners.length;
            });
          }
          return banners;
        });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<BottomNavProvider>(
      builder: (context, bottomNav, _) {
        // Kategori değiştiğinde verileri yeniden yükle
        final currentCategory = bottomNav.selectedCategory;
        if (_lastCategory != null && _lastCategory != currentCategory) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadBanners();
              _lastCategory = currentCategory;
            }
          });
        } else if (_lastCategory == null) {
          _lastCategory = currentCategory;
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              SharedHeader(
                title: localizations.campaigns,
                subtitle: _campaignCount != null
                    ? localizations.campaignsCount(_campaignCount!)
                    : null,
                showBackButton: true,
                onBack: () => Navigator.of(context).pop(),
                icon: Icons.local_offer_outlined,
              ),
              Expanded(
                child: FutureBuilder<List<PromotionalBanner>>(
                  future: _bannersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '${localizations.error}: ${snapshot.error}',
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text(localizations.noResultsFound));
                    }

                    final banners = snapshot.data!;
                    return ListView.separated(
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      itemCount: banners.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: AppTheme.spacingMedium),
                      itemBuilder: (context, index) {
                        return _buildBannerCard(
                          banners[index],
                          index,
                          colorScheme: colorScheme,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBannerCard(
    PromotionalBanner banner,
    int index, {
    required ColorScheme colorScheme,
  }) {
    // Use dynamic theme color for banners
    final gradientColors = [
      colorScheme.primary,
      colorScheme.primary.withOpacity(0.8),
    ];

    // Her banner için farklı icon
    final List<IconData> bannerIcons = [
      Icons.local_offer,
      Icons.star,
      Icons.shopping_bag,
      Icons.discount,
      Icons.card_giftcard,
      Icons.celebration,
      Icons.percent,
      Icons.flash_on,
      Icons.trending_up,
      Icons.favorite,
    ];
    final iconIndex = index % bannerIcons.length;
    final bannerIcon = bannerIcons[iconIndex];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CampaignDetailScreen(banner: banner),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banner.title,
                    style: AppTheme.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    banner.subtitle,
                    style: AppTheme.poppins(
                      fontSize: 13,
                      color: AppTheme.textOnPrimary.withOpacity(0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.buttonText != null) ...[
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Handle button action
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CampaignDetailScreen(banner: banner),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardColor,
                        foregroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        minimumSize: Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                      child: Text(
                        banner.buttonText!,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12),
            // Icon container
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    right: -18,
                    bottom: -35,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        BouncingCircle(color: Colors.white.withOpacity(0.2)),
                        if (banner.imageUrl != null)
                          ClipOval(
                            child: CachedNetworkImageWidget(
                              imageUrl: banner.imageUrl!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              maxWidth: 200,
                              maxHeight: 200,
                              errorWidget: Icon(
                                bannerIcon,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          Icon(bannerIcon, size: 50, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

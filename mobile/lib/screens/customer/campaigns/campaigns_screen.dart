import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:mobile/widgets/common/bouncing_circle.dart';
import 'package:mobile/screens/customer/campaigns/campaign_detail_screen.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PromotionalBanner>> _bannersFuture;

  int? _campaignCount;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = AppLocalizations.of(context)?.localeName ?? 'tr';
    _bannersFuture = _apiService.getBanners(language: locale).then((banners) {
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
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('${localizations.error}: ${snapshot.error}'),
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
                    return _buildBannerCard(banners[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(PromotionalBanner banner, int index) {
    // Use header background color for all banners
    final gradientColors = [const Color(0xFFCE181B), const Color(0xFFCE181B)];

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
                        foregroundColor: AppTheme.primaryOrange,
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
                          color: AppTheme.primaryOrange,
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

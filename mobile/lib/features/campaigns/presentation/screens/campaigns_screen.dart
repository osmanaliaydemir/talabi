import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/bouncing_circle.dart';
import 'package:mobile/features/campaigns/presentation/screens/campaign_detail_screen.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Campaign>> _campaignsFuture;

  int? _campaignCount;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  void _loadCampaigns() {
    _campaignsFuture = _fetchCampaignsWithContext();
  }

  Future<List<Campaign>> _fetchCampaignsWithContext() async {
    int? vendorType;
    String? cityId;
    String? districtId;

    if (mounted) {
      final bottomNav = Provider.of<BottomNavProvider>(context, listen: false);
      vendorType = bottomNav.selectedCategory == MainCategory.restaurant
          ? 1
          : 2;
    }

    try {
      final addresses = await _apiService.getAddresses();
      if (addresses.isNotEmpty) {
        final defaultAddr =
            addresses.firstWhere(
                  (a) => a['isDefault'] == true,
                  orElse: () => addresses.first,
                )
                as Map<String, dynamic>;

        if (defaultAddr['cityId'] != null) {
          cityId = defaultAddr['cityId'].toString();
        }
        if (defaultAddr['districtId'] != null) {
          districtId = defaultAddr['districtId'].toString();
        }
      }
    } catch (_) {
      // Ignore address errors
    }

    final campaigns = await _apiService.getCampaigns(
      vendorType: vendorType,
      cityId: cityId,
      districtId: districtId,
    );

    if (mounted) {
      setState(() {
        _campaignCount = campaigns.length;
      });
    }

    return campaigns;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
            child: FutureBuilder<List<Campaign>>(
              future: _campaignsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('${localizations.error}: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(localizations.noResultsFound));
                }

                final campaigns = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  itemCount: campaigns.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppTheme.spacingMedium),
                  itemBuilder: (context, index) {
                    return _buildCampaignCard(
                      campaigns[index],
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
  }

  Widget _buildCampaignCard(
    Campaign campaign,
    int index, {
    required ColorScheme colorScheme,
  }) {
    // Use dynamic theme color for banners
    final gradientColors = [
      colorScheme.primary,
      colorScheme.primary.withValues(alpha: 0.8),
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
            builder: (context) => CampaignDetailScreen(campaign: campaign),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                    campaign.title,
                    style: AppTheme.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textOnPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    campaign.description,
                    style: AppTheme.poppins(
                      fontSize: 13,
                      color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (campaign.actionUrl != null &&
                      campaign.actionUrl!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CampaignDetailScreen(campaign: campaign),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardColor,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                      ),
                      child: Text(
                        'Detaylar', // Localized "Details"
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
            const SizedBox(width: 12),
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
                        BouncingCircle(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        if (campaign.imageUrl.isNotEmpty)
                          ClipOval(
                            child: CachedNetworkImageWidget(
                              imageUrl: campaign.imageUrl,
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

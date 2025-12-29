import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/campaigns/presentation/screens/campaign_detail_screen.dart';
import 'package:mobile/widgets/bouncing_circle.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';

class HomeBannerSection extends StatefulWidget {
  const HomeBannerSection({super.key, required this.banners});

  final List<Campaign> banners;

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection> {
  late PageController _bannerPageController;
  int _currentBannerIndex = 1;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(
      initialPage: widget.banners.length >= 3 ? 1 : 0,
      viewportFraction: 0.90,
    );

    if (widget.banners.isNotEmpty) {
      _startBannerTimer();
    }
  }

  @override
  void didUpdateWidget(HomeBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners != widget.banners) {
      // Banners changed, reset controller and timer
      _bannerTimer?.cancel();
      if (widget.banners.isNotEmpty) {
        // Reset index safely
        final startIndex = widget.banners.length >= 3 ? 1 : 0;
        _currentBannerIndex = startIndex;

        // Jump to page after frame to ensure controller is ready for dimensions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _bannerPageController.hasClients) {
            _bannerPageController.jumpToPage(startIndex);
            _startBannerTimer();
          }
        });
      }
    }
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (widget.banners.length > 1) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
        if (mounted &&
            widget.banners.isNotEmpty &&
            _bannerPageController.hasClients) {
          final currentPage =
              _bannerPageController.page?.round() ?? _currentBannerIndex;
          final nextIndex = (currentPage + 1) % widget.banners.length;
          _bannerPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: widget.banners.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
              _startBannerTimer(); // Reset timer on manual swipe
            },
            itemBuilder: (context, index) {
              final currentBanner = widget.banners[index];
              final gradientColors = [colorScheme.primary, colorScheme.primary];

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
                      builder: (context) =>
                          CampaignDetailScreen(campaign: currentBanner),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXSmall,
                    vertical: AppTheme.spacingXSmall,
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                currentBanner.title,
                                style: AppTheme.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textOnPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Flexible(
                              child: Text(
                                currentBanner.description,
                                style: AppTheme.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textOnPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (currentBanner.actionUrl != null &&
                                currentBanner.actionUrl!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CampaignDetailScreen(
                                            campaign: currentBanner,
                                          ),
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
                                  if (currentBanner.imageUrl.isNotEmpty)
                                    ClipOval(
                                      child: CachedNetworkImageWidget(
                                        imageUrl: currentBanner.imageUrl,
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
                                    Icon(
                                      bannerIcon,
                                      size: 50,
                                      color: Colors.white,
                                    ),
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
            },
          ),
        ),
        if (widget.banners.length > 1)
          Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingSmall,
              left: AppTheme.spacingMedium,
              right: AppTheme.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.banners.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index
                        ? colorScheme.primary
                        : AppTheme.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

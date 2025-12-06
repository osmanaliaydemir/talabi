import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/widgets/common/bouncing_circle.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';

class CampaignDetailScreen extends StatelessWidget {
  final PromotionalBanner banner;

  const CampaignDetailScreen({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                banner.title,
                style: AppTheme.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -60,
                    child: BouncingCircle(
                      color: Colors.white.withOpacity(0.2),
                      size: 200,
                    ),
                  ),
                  if (banner.imageUrl != null)
                    Center(
                      child: ClipOval(
                        child: CachedNetworkImageWidget(
                          imageUrl: banner.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          maxWidth: 300,
                          maxHeight: 300,
                          errorWidget: Icon(
                            Icons.local_offer,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.local_offer,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: AppTheme.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    banner.subtitle,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  if (banner.buttonText != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle button action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: AppTheme.textOnPrimary,
                          padding: EdgeInsets.symmetric(
                            vertical: AppTheme.spacingMedium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          banner.buttonText!,
                          style: AppTheme.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

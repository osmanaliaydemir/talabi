import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/promotional_banner.dart';
import 'package:mobile/widgets/common/bouncing_circle.dart';

class CampaignDetailScreen extends StatelessWidget {
  final PromotionalBanner banner;

  const CampaignDetailScreen({super.key, required this.banner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFCE181B),
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
                          const Color(0xFFCE181B),
                          const Color(0xFFCE181B),
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
                        child: Image.network(
                          banner.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.local_offer,
                              size: 80,
                              color: Colors.white,
                            );
                          },
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
                          backgroundColor: AppTheme.primaryOrange,
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

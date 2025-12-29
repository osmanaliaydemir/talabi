import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/home/presentation/widgets/sections/home_banner_section.dart';
import 'package:mobile/features/campaigns/presentation/screens/campaigns_screen.dart';

class HomeCampaignSection extends StatelessWidget {
  const HomeCampaignSection({super.key, required this.banners});

  final List<Campaign> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.campaigns,
                style: AppTheme.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CampaignsScreen(),
                    ),
                  );
                },
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
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingSmall,
            right: AppTheme.spacingSmall,
            bottom: AppTheme.spacingMedium,
          ),
          child: HomeBannerSection(banners: banners),
        ),
      ],
    );
  }
}

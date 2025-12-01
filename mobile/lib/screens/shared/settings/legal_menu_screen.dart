import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/screens/shared/settings/legal_content_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/connectivity_banner.dart';
import 'package:mobile/widgets/common/persistent_bottom_nav_bar.dart';

class LegalMenuScreen extends StatelessWidget {
  const LegalMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final legalDocuments = [
      {
        'type': 'terms-of-use',
        'title': l10n.termsOfUse,
        'icon': Icons.description,
      },
      {
        'type': 'privacy-policy',
        'title': l10n.privacyPolicy,
        'icon': Icons.privacy_tip,
      },
      {
        'type': 'refund-policy',
        'title': l10n.refundPolicy,
        'icon': Icons.assignment_return,
      },
      {
        'type': 'distance-sales-agreement',
        'title': l10n.distanceSalesAgreement,
        'icon': Icons.shopping_bag,
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      bottomNavigationBar: const PersistentBottomNavBar(),
      body: Column(
        children: [
          // Header
          _buildHeader(context, l10n),
          // Content
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: EdgeInsets.only(top: AppTheme.spacingMedium),
                  itemCount: legalDocuments.length,
                  itemBuilder: (context, index) {
                    final doc = legalDocuments[index];
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      decoration: AppTheme.cardDecoration(),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(AppTheme.spacingSmall),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryOrange.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSmall,
                            ),
                          ),
                          child: Icon(
                            doc['icon'] as IconData,
                            color: AppTheme.primaryOrange,
                            size: AppTheme.iconSizeMedium,
                          ),
                        ),
                        title: Text(
                          doc['title'] as String,
                          style: AppTheme.poppins(
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppTheme.textSecondary,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LegalContentScreen(
                                documentType: doc['type'] as String,
                                title: doc['title'] as String,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ConnectivityBanner(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightOrange,
            AppTheme.primaryOrange,
            AppTheme.darkOrange,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textOnPrimary,
                    size: 18,
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacingSmall),
              // Icon
              Container(
                padding: EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.gavel,
                  color: AppTheme.textOnPrimary,
                  size: AppTheme.iconSizeSmall,
                ),
              ),
              SizedBox(width: AppTheme.spacingSmall),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.legalDocuments,
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sözleşmeler ve Politikalar',
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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

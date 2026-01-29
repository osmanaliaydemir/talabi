import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(context, localizations),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Container(
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(context, localizations.displaySettings),
                    SwitchListTile(
                      activeThumbColor: Theme.of(context).primaryColor,
                      title: Text(
                        localizations.highContrast,
                        style: AppTheme.poppins(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        localizations.highContrastDescription,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      value: themeProvider.isHighContrast,
                      onChanged: (value) {
                        themeProvider.toggleHighContrast(value);
                        ToastMessage.show(
                          context,
                          message: localizations.settingsSaved,
                          isSuccess: true,
                        );
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                      ),
                    ),
                    const Divider(height: 32, color: AppTheme.borderColor),
                    _buildSectionHeader(context, localizations.textSize),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.textSizeDescription,
                            style: AppTheme.poppins(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),
                          Row(
                            children: [
                              Text('A', style: AppTheme.poppins(fontSize: 14)),
                              Expanded(
                                child: Slider(
                                  activeColor: Theme.of(context).primaryColor,
                                  inactiveColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.3),
                                  value: themeProvider.textScaleFactor,
                                  min: 0.8,
                                  max: 1.5,
                                  divisions: 7,
                                  label: themeProvider.textScaleFactor
                                      .toStringAsFixed(1),
                                  onChanged: (value) {
                                    themeProvider.setTextScaleFactor(value);
                                    ToastMessage.show(
                                      context,
                                      message: localizations.settingsSaved,
                                      isSuccess: true,
                                      duration: const Duration(seconds: 1),
                                    );
                                  },
                                ),
                              ),
                              Text('A', style: AppTheme.poppins(fontSize: 24)),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          Center(
                            child: Text(
                              localizations.textSizePreview,
                              style: AppTheme.poppins(
                                fontSize: 16 * themeProvider.textScaleFactor,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingMedium,
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textOnPrimary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              // Icon
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: AppTheme.textOnPrimary,
                  size: AppTheme.iconSizeSmall,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.accessibilityTitle,
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.accessibilityDescription,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingSmall,
      ),
      child: Text(
        title,
        style: AppTheme.poppins(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

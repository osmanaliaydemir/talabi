import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:provider/provider.dart';

class CurrencySettingsScreen extends StatelessWidget {
  const CurrencySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(context, appLocalizations),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: AppTheme.cardDecoration(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.turkishLira ?? 'Turkish Lira',
                      style: AppTheme.poppins(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '₺ TRY',
                      style: AppTheme.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    value: 'TRY',
                    groupValue: localization.currency,
                    onChanged: (value) {
                      if (value != null) {
                        localization.setCurrency(value);
                      }
                    },
                  ),
                  Divider(color: AppTheme.borderColor),
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.tether ?? 'Tether',
                      style: AppTheme.poppins(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'USDT',
                      style: AppTheme.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    value: 'USDT',
                    groupValue: localization.currency,
                    onChanged: (value) {
                      if (value != null) {
                        localization.setCurrency(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? appLocalizations,
  ) {
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
                  Icons.currency_exchange,
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
                      appLocalizations?.selectCurrency ?? 'Select Currency',
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Para birimi seçimi',
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

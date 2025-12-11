import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final appLocalizations = AppLocalizations.of(context);
    final currentCurrency = localization.currency;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(context, appLocalizations),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: AppTheme.cardDecoration(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ignore: deprecated_member_use
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
                    // ignore: deprecated_member_use
                    groupValue: currentCurrency,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          localization.setCurrency(value);
                        });
                        if (appLocalizations != null) {
                          ToastMessage.show(
                            context,
                            message: appLocalizations.settingsSaved,
                            isSuccess: true,
                          );
                        }
                      }
                    },
                  ),
                  const Divider(color: AppTheme.borderColor),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.tether ?? 'USD',
                      style: AppTheme.poppins(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '\$ USD',
                      style: AppTheme.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    value: 'USD',
                    // ignore: deprecated_member_use
                    groupValue: currentCurrency,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          localization.setCurrency(value);
                        });
                        if (appLocalizations != null) {
                          ToastMessage.show(
                            context,
                            message: appLocalizations.settingsSaved,
                            isSuccess: true,
                          );
                        }
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
      decoration: const BoxDecoration(
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
                  Icons.currency_exchange,
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
                      appLocalizations?.selectCurrency ?? 'Select Currency',
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appLocalizations?.selectCurrencyDescription ??
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

import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/notification_settings.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/toast_message.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  NotificationSettings? _settings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsData = await _apiService.getNotificationSettings();
      setState(() {
        _settings = NotificationSettings.fromJson(settingsData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ToastMessage.show(
          context,
          message:
              localizations?.settingsLoadError(e.toString()) ??
              'Ayarlar yüklenemedi: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _updateSettings() async {
    if (_settings == null) return;

    try {
      await _apiService.updateNotificationSettings(_settings!.toJson());
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.settingsSaved,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ToastMessage.show(
          context,
          message: localizations?.errorWithMessage(e.toString()) ?? 'Hata: $e',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _settings == null
                ? Center(
                    child: Text(
                      AppLocalizations.of(context)?.settingsLoadError('') ??
                          'Ayarlar yüklenemedi',
                      style: AppTheme.poppins(color: AppTheme.textSecondary),
                    ),
                  )
                : Container(
                    margin: EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: AppTheme.cardDecoration(),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        SwitchListTile(
                          activeColor: AppTheme.primaryOrange,
                          title: Text(
                            AppLocalizations.of(context)!.orderUpdates,
                            style: AppTheme.poppins(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!.orderUpdatesDescription,
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          value: _settings!.orderUpdates,
                          onChanged: (value) {
                            setState(() {
                              _settings!.orderUpdates = value;
                            });
                            _updateSettings();
                          },
                        ),
                        Divider(color: AppTheme.borderColor),
                        SwitchListTile(
                          activeColor: AppTheme.primaryOrange,
                          title: Text(
                            AppLocalizations.of(context)!.promotions,
                            style: AppTheme.poppins(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(context)!.promotionsDescription,
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          value: _settings!.promotions,
                          onChanged: (value) {
                            setState(() {
                              _settings!.promotions = value;
                            });
                            _updateSettings();
                          },
                        ),
                        Divider(color: AppTheme.borderColor),
                        SwitchListTile(
                          activeColor: AppTheme.primaryOrange,
                          title: Text(
                            AppLocalizations.of(context)!.newProducts,
                            style: AppTheme.poppins(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            AppLocalizations.of(
                              context,
                            )!.newProductsDescription,
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          value: _settings!.newProducts,
                          onChanged: (value) {
                            setState(() {
                              _settings!.newProducts = value;
                            });
                            _updateSettings();
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

  Widget _buildHeader(BuildContext context) {
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
                  Icons.notifications,
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
                      AppLocalizations.of(context)!.notificationSettings,
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.notificationSettingsDescription,
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

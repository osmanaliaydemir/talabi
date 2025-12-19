import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/notifications/data/models/notification_settings.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';

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
                ? const Center(
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
                    margin: const EdgeInsets.all(AppTheme.spacingMedium),
                    decoration: AppTheme.cardDecoration(),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        SwitchListTile(
                          activeThumbColor: AppTheme.primaryOrange,
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
                        const Divider(color: AppTheme.borderColor),
                        SwitchListTile(
                          activeThumbColor: AppTheme.primaryOrange,
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
                        const Divider(color: AppTheme.borderColor),
                        SwitchListTile(
                          activeThumbColor: AppTheme.primaryOrange,
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
    return SharedHeader(
      title: AppLocalizations.of(context)!.notificationSettings,
      subtitle: AppLocalizations.of(context)!.notificationSettingsDescription,
      icon: Icons.notifications,
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
    );
  }
}

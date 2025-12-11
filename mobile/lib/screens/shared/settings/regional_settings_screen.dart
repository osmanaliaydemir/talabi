import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';

class RegionalSettingsScreen extends StatefulWidget {
  const RegionalSettingsScreen({super.key});

  @override
  State<RegionalSettingsScreen> createState() => _RegionalSettingsScreenState();
}

class _RegionalSettingsScreenState extends State<RegionalSettingsScreen> {
  late String _selectedDateFormat;
  late String _selectedTimeFormat;
  final TextEditingController _timeZoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final localization = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    _selectedDateFormat = localization.dateFormat ?? 'dd/MM/yyyy';
    _selectedTimeFormat = localization.timeFormat ?? '24h';
    _timeZoneController.text = localization.timeZone ?? '';
  }

  @override
  void dispose() {
    _timeZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationProvider>(context);
    final appLocalizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          _buildHeader(context, appLocalizations, localization),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: AppTheme.cardDecoration(),
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                children: [
                  // Date Format
                  Text(
                    appLocalizations?.dateFormat ?? 'Date Format',
                    style: AppTheme.poppins(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  ...[
                    'dd/MM/yyyy',
                    'MM/dd/yyyy',
                    'yyyy-MM-dd',
                    'dd.MM.yyyy',
                  ].map((format) {
                    // ignore: deprecated_member_use
                    return RadioListTile<String>(
                      activeColor: AppTheme.primaryOrange,
                      title: Text(
                        format,
                        style: AppTheme.poppins(color: AppTheme.textPrimary),
                      ),
                      value: format,
                      // ignore: deprecated_member_use
                      groupValue: _selectedDateFormat,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          _selectedDateFormat = value!;
                        });
                      },
                    );
                  }),

                  const Divider(height: 32, color: AppTheme.borderColor),

                  // Time Format
                  Text(
                    appLocalizations?.timeFormat ?? 'Time Format',
                    style: AppTheme.poppins(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.hour24 ?? '24 Hour',
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                    ),
                    value: '24h',
                    // ignore: deprecated_member_use
                    groupValue: _selectedTimeFormat,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.hour12 ?? '12 Hour',
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                    ),
                    value: '12h',
                    // ignore: deprecated_member_use
                    groupValue: _selectedTimeFormat,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),

                  const Divider(height: 32, color: AppTheme.borderColor),

                  // Time Zone
                  Text(
                    appLocalizations?.timeZone ?? 'Time Zone',
                    style: AppTheme.poppins(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Container(
                    decoration: AppTheme.inputBoxDecoration(),
                    child: TextField(
                      controller: _timeZoneController,
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            appLocalizations?.timeZoneHint ??
                            'e.g., Europe/Istanbul, America/New_York',
                        hintStyle: AppTheme.poppins(color: AppTheme.textHint),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        localization
                          ..setDateFormat(_selectedDateFormat)
                          ..setTimeFormat(_selectedTimeFormat)
                          ..setTimeZone(
                            _timeZoneController.text.isEmpty
                                ? null
                                : _timeZoneController.text,
                          );

                        ToastMessage.show(
                          context,
                          message:
                              appLocalizations?.settingsSaved ??
                              'Ayarlar kaydedildi',
                          isSuccess: true,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: AppTheme.textOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingMedium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ),
                      child: Text(
                        appLocalizations?.save ?? 'Save',
                        style: AppTheme.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textOnPrimary,
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

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? appLocalizations,
    LocalizationProvider localization,
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
                  Icons.public,
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
                      appLocalizations?.regionalSettings ?? 'Regional Settings',
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appLocalizations?.regionalSettingsDescription ??
                          'Tarih ve saat ayarları',
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

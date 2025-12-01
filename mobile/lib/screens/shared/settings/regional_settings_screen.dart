import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/localization_provider.dart';
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
              margin: EdgeInsets.all(AppTheme.spacingMedium),
              decoration: AppTheme.cardDecoration(),
              child: ListView(
                padding: EdgeInsets.all(AppTheme.spacingMedium),
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
                  SizedBox(height: AppTheme.spacingSmall),
                  ...[
                    'dd/MM/yyyy',
                    'MM/dd/yyyy',
                    'yyyy-MM-dd',
                    'dd.MM.yyyy',
                  ].map((format) {
                    return RadioListTile<String>(
                      activeColor: AppTheme.primaryOrange,
                      title: Text(
                        format,
                        style: AppTheme.poppins(color: AppTheme.textPrimary),
                      ),
                      value: format,
                      groupValue: _selectedDateFormat,
                      onChanged: (value) {
                        setState(() {
                          _selectedDateFormat = value!;
                        });
                      },
                    );
                  }),

                  Divider(height: 32, color: AppTheme.borderColor),

                  // Time Format
                  Text(
                    appLocalizations?.timeFormat ?? 'Time Format',
                    style: AppTheme.poppins(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.hour24 ?? '24 Hour',
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                    ),
                    value: '24h',
                    groupValue: _selectedTimeFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    activeColor: AppTheme.primaryOrange,
                    title: Text(
                      appLocalizations?.hour12 ?? '12 Hour',
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                    ),
                    value: '12h',
                    groupValue: _selectedTimeFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),

                  Divider(height: 32, color: AppTheme.borderColor),

                  // Time Zone
                  Text(
                    appLocalizations?.timeZone ?? 'Time Zone',
                    style: AppTheme.poppins(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingSmall),
                  Container(
                    decoration: AppTheme.inputBoxDecoration(),
                    child: TextField(
                      controller: _timeZoneController,
                      style: AppTheme.poppins(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g., Europe/Istanbul, America/New_York',
                        hintStyle: AppTheme.poppins(color: AppTheme.textHint),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingMedium,
                          vertical: AppTheme.spacingMedium,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingLarge),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        localization.setDateFormat(_selectedDateFormat);
                        localization.setTimeFormat(_selectedTimeFormat);
                        localization.setTimeZone(
                          _timeZoneController.text.isEmpty
                              ? null
                              : _timeZoneController.text,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              appLocalizations?.save ?? 'Kaydedildi',
                              style: AppTheme.poppins(
                                color: AppTheme.textOnPrimary,
                              ),
                            ),
                            backgroundColor: AppTheme.success,
                          ),
                        );
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
                  Icons.public,
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
                      appLocalizations?.regionalSettings ?? 'Regional Settings',
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
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

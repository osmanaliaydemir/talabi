import 'package:flutter/material.dart';
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
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          _buildHeader(context, appLocalizations, localization),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Date Format
                  Text(
                    appLocalizations?.dateFormat ?? 'Date Format',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[
                    'dd/MM/yyyy',
                    'MM/dd/yyyy',
                    'yyyy-MM-dd',
                    'dd.MM.yyyy',
                  ].map((format) {
                    return RadioListTile<String>(
                      title: Text(format),
                      value: format,
                      groupValue: _selectedDateFormat,
                      onChanged: (value) {
                        setState(() {
                          _selectedDateFormat = value!;
                        });
                      },
                    );
                  }),

                  const Divider(height: 32),

                  // Time Format
                  Text(
                    appLocalizations?.timeFormat ?? 'Time Format',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text(appLocalizations?.hour24 ?? '24 Hour'),
                    value: '24h',
                    groupValue: _selectedTimeFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(appLocalizations?.hour12 ?? '12 Hour'),
                    value: '12h',
                    groupValue: _selectedTimeFormat,
                    onChanged: (value) {
                      setState(() {
                        _selectedTimeFormat = value!;
                      });
                    },
                  ),

                  const Divider(height: 32),

                  // Time Zone
                  Text(
                    appLocalizations?.timeZone ?? 'Time Zone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _timeZoneController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Europe/Istanbul, America/New_York',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        appLocalizations?.save ?? 'Save',
                        style: const TextStyle(
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
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade800,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      appLocalizations?.regionalSettings ?? 'Regional Settings',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tarih ve saat ayarları',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
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

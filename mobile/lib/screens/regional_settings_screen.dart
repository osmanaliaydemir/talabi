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
      appBar: AppBar(
        title: Text(appLocalizations?.regionalSettings ?? 'Regional Settings'),
        actions: [
          TextButton(
            onPressed: () {
              localization.setDateFormat(_selectedDateFormat);
              localization.setTimeFormat(_selectedTimeFormat);
              localization.setTimeZone(
                _timeZoneController.text.isEmpty
                    ? null
                    : _timeZoneController.text,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appLocalizations?.save ?? 'Save')),
              );
            },
            child: Text(appLocalizations?.save ?? 'Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date Format
          Text(
            appLocalizations?.dateFormat ?? 'Date Format',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd', 'dd.MM.yyyy'].map((
            format,
          ) {
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
            style: Theme.of(context).textTheme.titleMedium,
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
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _timeZoneController,
            decoration: InputDecoration(
              hintText: 'e.g., Europe/Istanbul, America/New_York',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

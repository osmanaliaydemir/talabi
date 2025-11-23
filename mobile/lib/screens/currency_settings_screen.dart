import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: Text(appLocalizations?.selectCurrency ?? 'Select Currency'),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text(appLocalizations?.turkishLira ?? 'Turkish Lira'),
            subtitle: const Text('₺ TRY'),
            value: 'TRY',
            groupValue: localization.currency,
            onChanged: (value) {
              if (value != null) {
                localization.setCurrency(value);
              }
            },
          ),
          RadioListTile<String>(
            title: Text(appLocalizations?.tether ?? 'Tether'),
            subtitle: const Text('USDT'),
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
    );
  }
}

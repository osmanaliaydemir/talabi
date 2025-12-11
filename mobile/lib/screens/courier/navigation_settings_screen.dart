import 'package:flutter/material.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/courier/widgets/header.dart';
import 'package:mobile/screens/courier/widgets/bottom_nav.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourierNavigationSettingsScreen extends StatefulWidget {
  const CourierNavigationSettingsScreen({super.key});

  @override
  State<CourierNavigationSettingsScreen> createState() =>
      _CourierNavigationSettingsScreenState();
}

class _CourierNavigationSettingsScreenState
    extends State<CourierNavigationSettingsScreen> {
  String _selectedApp = 'google_maps';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    LoggerService().debug('CourierNavigationSettingsScreen: initState');
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('courier_navigation_app') ?? 'google_maps';
      LoggerService().debug(
        'CourierNavigationSettingsScreen: Loaded navigation app preference: $value',
      );
      if (mounted) {
        setState(() {
          _selectedApp = value;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierNavigationSettingsScreen: ERROR loading navigation preference',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreference(String value) async {
    LoggerService().debug(
      'CourierNavigationSettingsScreen: Saving navigation app: $value',
    );
    setState(() {
      _selectedApp = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('courier_navigation_app', value);
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.navigationAppUpdated ??
                'Navigasyon uygulaması güncellendi',
          ),
        ),
      );
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierNavigationSettingsScreen: ERROR saving navigation preference',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.navigationPreferenceNotSaved(e.toString()) ??
                'Navigasyon tercihi kaydedilemedi: $e',
          ),
        ),
      );
    }
  }

  String _getAppName(BuildContext context, String key) {
    switch (key) {
      case 'google_maps':
        return 'Google Maps';
      case 'waze':
        return 'Waze';
      case 'yandex_maps':
        return 'Yandex Maps';
      default:
        return 'Harita';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.navigationApp ?? 'Navigasyon Uygulaması',
        leadingIcon: Icons.map_outlined,
        showBackButton: true,
        onBack: () {
          LoggerService().debug('CourierNavigationSettingsScreen: Back tapped');
          Navigator.of(context).pop();
        },
        showRefresh: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  localizations?.selectDefaultNavigationApp ??
                      'Teslimat adresine giderken kullanmak istediğin varsayılan navigasyon uygulamasını seç.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: RadioGroup<String>(
                    groupValue: _selectedApp,
                    onChanged: (value) {
                      if (value == null) return;
                      _savePreference(value);
                    },
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'google_maps',
                          title: Text(_getAppName(context, 'google_maps')),
                          secondary: const Icon(Icons.map),
                        ),
                        const Divider(height: 0),
                        RadioListTile<String>(
                          value: 'waze',
                          title: Text(_getAppName(context, 'waze')),
                          secondary: const Icon(Icons.directions_car),
                        ),
                        const Divider(height: 0),
                        RadioListTile<String>(
                          value: 'yandex_maps',
                          title: Text(_getAppName(context, 'yandex_maps')),
                          secondary: const Icon(Icons.navigation),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(localizations?.note ?? 'Not'),
                  subtitle: Text(
                    localizations
                            ?.ifAppNotInstalledSystemWillOfferAlternative ??
                        'Seçtiğin uygulama cihazında yüklü değilse sistem sana uygun bir seçenek sunar.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizations?.preferenceOnlyForCourierAccount ??
                      'Bu tercih sadece kurye hesabın için geçerlidir.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 3),
    );
  }
}

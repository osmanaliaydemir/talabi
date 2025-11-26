import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/courier/courier_header.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';
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
    print('CourierNavigationSettingsScreen: initState');
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('courier_navigation_app') ?? 'google_maps';
      print(
        'CourierNavigationSettingsScreen: Loaded navigation app preference: $value',
      );
      if (mounted) {
        setState(() {
          _selectedApp = value;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print(
        'CourierNavigationSettingsScreen: ERROR loading navigation preference - $e',
      );
      print(stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreference(String value) async {
    print('CourierNavigationSettingsScreen: Saving navigation app: $value');
    setState(() {
      _selectedApp = value;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('courier_navigation_app', value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigasyon uygulaması güncellendi')),
      );
    } catch (e, stackTrace) {
      print(
        'CourierNavigationSettingsScreen: ERROR saving navigation preference - $e',
      );
      print(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Navigasyon tercihi kaydedilemedi: $e')),
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
        title: 'Navigasyon Uygulaması',
        leadingIcon: Icons.map_outlined,
        showBackButton: true,
        onBack: () {
          print('CourierNavigationSettingsScreen: Back tapped');
          Navigator.of(context).pop();
        },
        showRefresh: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Teslimat adresine giderken kullanmak istediğin varsayılan navigasyon uygulamasını seç.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: 'google_maps',
                        groupValue: _selectedApp,
                        onChanged: (value) {
                          if (value == null) return;
                          _savePreference(value);
                        },
                        title: Text(_getAppName(context, 'google_maps')),
                        secondary: const Icon(Icons.map),
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        value: 'waze',
                        groupValue: _selectedApp,
                        onChanged: (value) {
                          if (value == null) return;
                          _savePreference(value);
                        },
                        title: Text(_getAppName(context, 'waze')),
                        secondary: const Icon(Icons.directions_car),
                      ),
                      const Divider(height: 0),
                      RadioListTile<String>(
                        value: 'yandex_maps',
                        groupValue: _selectedApp,
                        onChanged: (value) {
                          if (value == null) return;
                          _savePreference(value);
                        },
                        title: Text(_getAppName(context, 'yandex_maps')),
                        secondary: const Icon(Icons.navigation),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Not'),
                  subtitle: Text(
                    'Seçtiğin uygulama cihazında yüklü değilse sistem sana uygun bir seçenek sunar.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
                if (localizations != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Bu tercih sadece kurye hesabın için geçerlidir.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ],
            ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 2),
    );
  }
}

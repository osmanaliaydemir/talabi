import 'package:flutter/material.dart';
import 'package:mobile/models/notification_settings.dart';
import 'package:mobile/services/api_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayarlar yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _updateSettings() async {
    if (_settings == null) return;

    try {
      await _apiService.updateNotificationSettings(_settings!.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar kaydedildi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? const Center(child: Text('Ayarlar yüklenemedi'))
              : ListView(
                  children: [
                    SwitchListTile(
                      title: const Text('Sipariş Güncellemeleri'),
                      subtitle: const Text(
                          'Sipariş durumu değişikliklerinde bildirim al'),
                      value: _settings!.orderUpdates,
                      onChanged: (value) {
                        setState(() {
                          _settings!.orderUpdates = value;
                        });
                        _updateSettings();
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Kampanyalar'),
                      subtitle: const Text('Özel teklifler ve kampanyalar'),
                      value: _settings!.promotions,
                      onChanged: (value) {
                        setState(() {
                          _settings!.promotions = value;
                        });
                        _updateSettings();
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Yeni Ürünler'),
                      subtitle: const Text('Yeni ürün eklendiğinde bildirim al'),
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
    );
  }
}

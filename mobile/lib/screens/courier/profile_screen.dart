import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/shared/settings/language_settings_screen.dart';
import 'package:mobile/screens/shared/settings/legal_menu_screen.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/screens/courier/widgets/header.dart';
import 'package:mobile/screens/courier/widgets/bottom_nav.dart';
import 'package:provider/provider.dart';

class CourierProfileScreen extends StatefulWidget {
  const CourierProfileScreen({super.key});

  @override
  State<CourierProfileScreen> createState() => _CourierProfileScreenState();
}

class _CourierProfileScreenState extends State<CourierProfileScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  Courier? _courier;

  @override
  void initState() {
    super.initState();
    LoggerService().debug('CourierProfileScreen: initState called');
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    LoggerService().debug('CourierProfileScreen: Loading profile...');
    setState(() => _isLoading = true);
    try {
      final courier = await _courierService.getProfile();
      LoggerService().debug(
        'CourierProfileScreen: Profile loaded - Name: ${courier.name}, Status: ${courier.status}',
      );
      if (!mounted) return;
      setState(() {
        _courier = courier;
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierProfileScreen: ERROR loading profile',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Failed to')
                ? e.toString()
                : (localizations?.failedToLoadProfile as String? ??
                      'Error loading profile: $e'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    LoggerService().debug(
      'CourierProfileScreen: Updating status to $newStatus',
    );
    try {
      await _courierService.updateStatus(newStatus);
      LoggerService().debug(
        'CourierProfileScreen: Status updated successfully to $newStatus',
      );
      await _loadProfile(); // Reload to confirm
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.statusUpdated ?? 'Status updated to $newStatus',
          ),
        ),
      );
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierProfileScreen: ERROR updating status',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Failed to')
                ? e.toString()
                : (localizations?.failedToUpdateStatus ??
                      'Error updating status: $e'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CourierHeader(
          title: localizations?.profile ?? 'Profil & Ayarlar',
          subtitle: authProvider.fullName ?? authProvider.email ?? 'Kurye',
          leadingIcon: Icons.person_outline,
          showBackButton: false,
          onRefresh: _loadProfile,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
        bottomNavigationBar: const CourierBottomNav(currentIndex: 3),
      );
    }

    if (_courier == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CourierHeader(
          title: localizations?.profile ?? 'Profil & Ayarlar',
          subtitle: authProvider.fullName ?? authProvider.email ?? 'Kurye',
          leadingIcon: Icons.person_outline,
          showBackButton: false,
          onRefresh: _loadProfile,
        ),
        body: Center(
          child: Text(
            (localizations?.failedToLoadProfile as String?) ??
                'Failed to load profile',
          ),
        ),
        bottomNavigationBar: const CourierBottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.profile ?? 'Profil & Ayarlar',
        subtitle: authProvider.fullName ?? authProvider.email ?? 'Kurye',
        leadingIcon: Icons.person_outline,
        showBackButton: false,
        onRefresh: _loadProfile,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _buildProfileDetails(context, authProvider),
        ),
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 3),
    );
  }

  String _getLocalizedString(String key, String fallback) {
    try {
      final localizations = AppLocalizations.of(context);
      if (localizations == null) return fallback;

      // Use reflection to get the property dynamically
      final value = (localizations as dynamic)[key];
      return value?.toString() ?? fallback;
    } catch (e) {
      return fallback;
    }
  }

  Widget _buildProfileDetails(BuildContext context, AuthProvider authProvider) {
    final courier = _courier!;
    final localizations = AppLocalizations.of(context);
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    final currentLanguage = _getLanguageDisplayName(
      localizationProvider.locale.languageCode,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 16),
              Text(
                courier.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                courier.vehicleType ??
                    (localizations?.noVehicleInfo ?? 'Araç bilgisi yok'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          localizations?.currentStatus ?? 'Anlık Durum',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      courier.status,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: courier.status == 'Available'
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                    Switch(
                      value: courier.status == 'Available',
                      onChanged: (value) {
                        if (courier.status == 'Busy' ||
                            courier.status == 'Assigned') {
                          final localizations = AppLocalizations.of(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                localizations
                                        ?.cannotChangeStatusWithActiveOrders ??
                                    'Aktif sipariş varken durum değiştirilemez.',
                              ),
                            ),
                          );
                          return;
                        }
                        _updateStatus(value ? 'Available' : 'Offline');
                      },
                    ),
                  ],
                ),
                if (courier.status == 'Busy' || courier.status == 'Assigned')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      localizations?.cannotGoOfflineUntilOrdersCompleted ??
                          'Aktif sipariş tamamlanana kadar offline olamazsın.',
                      style: const TextStyle(color: AppTheme.primaryOrange),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          localizations?.performance ?? 'Performans',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                localizations?.points ?? 'Puan',
                courier.averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                localizations?.totalEarnings ?? 'Toplam Kazanç',
                '₺${courier.totalEarnings.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          localizations?.settings ?? 'Ayarlar',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(localizations?.editProfile ?? 'Profili Düzenle'),
          subtitle: Text(
            localizations?.editCourierProfileDescription ??
                'Ad, telefon, araç bilgisi ve çalışma saatlerini düzenle',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            LoggerService().debug('CourierProfileScreen: Edit profile tapped');
            final result = await Navigator.of(
              context,
            ).pushNamed('/courier/profile/edit');
            if (result == true && mounted) {
              await _loadProfile();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.radio_button_checked),
          title: Text(localizations?.availabilityStatus ?? 'Müsaitlik Durumu'),
          subtitle: Text(
            localizations?.checkNewOrderConditions ??
                'Yeni sipariş alabilme şartlarını buradan kontrol et',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'CourierProfileScreen: Availability tile tapped',
            );
            Navigator.of(context).pushNamed('/courier/availability');
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(localizations?.selectLanguage ?? 'Dil Seçimi'),
          subtitle: Text(currentLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'CourierProfileScreen: Language settings tapped',
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LanguageSettingsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(
            _getLocalizedString('locationManagement', 'Konum Yönetimi'),
          ),
          subtitle: Text(
            _getLocalizedString(
              'locationManagementDescription',
              'Mevcut konumunu görüntüle ve güncelle',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'CourierProfileScreen: Location management tapped',
            );
            Navigator.of(context).pushNamed('/courier/location-management');
          },
        ),
        ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(localizations?.navigationApp ?? 'Navigasyon Uygulaması'),
          subtitle: Text(
            localizations?.selectPreferredNavigationApp ??
                'Tercih ettiğin navigasyon uygulamasını seç',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'CourierProfileScreen: Navigation app tile tapped',
            );
            Navigator.of(context).pushNamed('/courier/navigation-settings');
          },
        ),
        ListTile(
          leading: const Icon(Icons.gavel),
          title: Text(localizations?.legalDocuments ?? 'Yasal Belgeler'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'CourierProfileScreen: Legal documents tapped',
            );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LegalMenuScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(
            localizations?.logout ?? 'Çıkış Yap',
            style: const TextStyle(color: Colors.red),
          ),
          onTap: () async {
            LoggerService().debug('CourierProfileScreen: Logout tapped');
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(localizations?.logout ?? 'Çıkış Yap'),
                content: Text(
                  localizations?.logoutConfirm ??
                      'Çıkış yapmak istediğine emin misin?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(localizations?.cancel ?? 'İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      localizations?.logout ?? 'Çıkış Yap',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              final role = await authProvider.logout();
              if (!context.mounted) return;
              // Role'e göre ilgili login sayfasına yönlendir
              if (role?.toLowerCase() == 'courier') {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/courier/login', (route) => false);
              } else if (role?.toLowerCase() == 'vendor') {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/vendor/login', (route) => false);
              } else {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            }
          },
        ),
      ],
    );
  }

  String _getLanguageDisplayName(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English (US)';
      case 'ar':
        return 'العربية';
      default:
        return 'English (US)';
    }
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

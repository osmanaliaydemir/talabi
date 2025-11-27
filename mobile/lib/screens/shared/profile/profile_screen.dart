import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/notification_settings.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/screens/shared/settings/accessibility_settings_screen.dart';
import 'package:mobile/screens/shared/profile/addresses_screen.dart';
import 'package:mobile/screens/shared/profile/change_password_screen.dart';
import 'package:mobile/screens/shared/profile/edit_profile_screen.dart';
import 'package:mobile/screens/customer/favorites_screen.dart';
import 'package:mobile/screens/shared/settings/language_settings_screen.dart';
import 'package:mobile/screens/customer/order_history_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  NotificationSettings? _notificationSettings;
  bool _pushNotificationsEnabled = true;
  bool _promotionalNotificationsEnabled = false;
  bool _newProductsNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadNotificationSettings();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil yüklenemedi: $e')));
      }
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final settingsData = await _apiService.getNotificationSettings();
      setState(() {
        _notificationSettings = NotificationSettings.fromJson(settingsData);
        _pushNotificationsEnabled = _notificationSettings?.orderUpdates ?? true;
        _promotionalNotificationsEnabled =
            _notificationSettings?.promotions ?? false;
        _newProductsNotificationsEnabled =
            _notificationSettings?.newProducts ?? false;
      });
    } catch (e) {
      // Hata durumunda varsayılan değerler kullanılacak
    }
  }

  Future<void> _updateNotificationSetting(String type, bool value) async {
    if (_notificationSettings == null) return;

    setState(() {
      if (type == 'push') {
        _pushNotificationsEnabled = value;
        _notificationSettings!.orderUpdates = value;
      } else if (type == 'promotional') {
        _promotionalNotificationsEnabled = value;
        _notificationSettings!.promotions = value;
      } else if (type == 'newProducts') {
        _newProductsNotificationsEnabled = value;
        _notificationSettings!.newProducts = value;
      }
    });

    try {
      await _apiService.updateNotificationSettings(
        _notificationSettings!.toJson(),
      );
    } catch (e) {
      // Hata durumunda geri al
      setState(() {
        if (type == 'push') {
          _pushNotificationsEnabled = !value;
          _notificationSettings!.orderUpdates = !value;
        } else if (type == 'promotional') {
          _promotionalNotificationsEnabled = !value;
          _notificationSettings!.promotions = !value;
        } else if (type == 'newProducts') {
          _newProductsNotificationsEnabled = !value;
          _notificationSettings!.newProducts = !value;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ayarlar güncellenemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Header with Geometric Background
                _buildHeader(context, localizations, colorScheme),
                // Main Content Card
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildContentCard(
                      context,
                      localizations,
                      colorScheme,
                      auth,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Profile Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              // Title and User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.myProfile,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _profile?['fullName'] ?? localizations.user,
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

  Widget _buildContentCard(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
    AuthProvider auth,
  ) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final currentLanguage = _getLanguageDisplayName(
      localizationProvider.locale.languageCode,
    );

    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Account Section
          _buildSectionHeader(localizations.editProfile, 'My Account'),
          _buildMenuItem(
            icon: Icons.person,
            title: localizations.editProfile,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(profile: _profile!),
                ),
              );
              if (result == true) {
                _loadProfile();
              }
            },
          ),
          _buildMenuItem(
            icon: Icons.shopping_bag,
            title: localizations.orderHistory,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.location_on,
            title: localizations.myAddresses,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressesScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: localizations.favoriteProducts,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.lock,
            title: localizations.changePassword,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Notifications Section
          _buildSectionHeader(
            localizations.notificationSettings,
            'Notifications',
          ),
          _buildNotificationMenuItem(
            icon: Icons.notifications,
            title: 'Push Notifications',
            value: _pushNotificationsEnabled,
            onChanged: (value) => _updateNotificationSetting('push', value),
          ),
          _buildNotificationMenuItem(
            icon: Icons.campaign,
            title: 'Promotional Notifications',
            value: _promotionalNotificationsEnabled,
            onChanged: (value) =>
                _updateNotificationSetting('promotional', value),
          ),
          _buildNotificationMenuItem(
            icon: Icons.new_releases,
            title: 'New Products',
            value: _newProductsNotificationsEnabled,
            onChanged: (value) =>
                _updateNotificationSetting('newProducts', value),
          ),
          const Divider(height: 1),
          // More Section
          _buildSectionHeader(localizations.logout, 'More'),
          _buildMenuItem(
            icon: Icons.language,
            title: localizations.selectLanguage,
            subtitle: currentLanguage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.accessibility_new,
            title: 'Accessibility & Display',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccessibilitySettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              _showHelpCenter(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: localizations.logout,
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              _showLogoutDialog(context, auth);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sectionTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        sectionTitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.black87, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            )
          : null,
      trailing: titleColor == Colors.red
          ? null
          : Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildNotificationMenuItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 15),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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

  void _showHelpCenter(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How can we help you?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.help_outline,
              title: 'FAQ',
              subtitle: 'Frequently asked questions',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.email_outlined,
              title: 'Contact Support',
              subtitle: 'support@talabi.com',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+90 (555) 123 45 67',
            ),
            const SizedBox(height: 12),
            _buildHelpItem(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Available 24/7',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () {
        // Handle help item tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final role = await auth.logout();

              // Navigate to login screen and clear navigation stack
              if (mounted) {
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
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

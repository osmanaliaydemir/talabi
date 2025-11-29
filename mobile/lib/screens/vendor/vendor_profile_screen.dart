import 'package:flutter/material.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/shared/settings/language_settings_screen.dart';
import 'package:mobile/screens/vendor/vendor_edit_profile_screen.dart';
import 'package:mobile/screens/vendor/vendor_settings_screen.dart';
import 'package:mobile/widgets/vendor/vendor_header.dart';
import 'package:mobile/widgets/vendor/vendor_bottom_nav.dart';
import 'package:provider/provider.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getVendorProfile();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: VendorHeader(
          title: localizations?.profile ?? 'Profil',
          subtitle: authProvider.fullName ?? authProvider.email ?? 'Satıcı',
          leadingIcon: Icons.person_outline,
          showBackButton: false,
          onRefresh: _loadProfile,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
        bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: VendorHeader(
          title: localizations?.profile ?? 'Profil',
          subtitle: authProvider.fullName ?? authProvider.email ?? 'Satıcı',
          leadingIcon: Icons.person_outline,
          showBackButton: false,
          onRefresh: _loadProfile,
        ),
        body: Center(
          child: Text(
            localizations?.failedToLoadProfile ?? 'Profil yüklenemedi',
          ),
        ),
        bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VendorHeader(
        title: localizations?.profile ?? 'Profil',
        subtitle: authProvider.fullName ?? authProvider.email ?? 'Satıcı',
        leadingIcon: Icons.person_outline,
        showBackButton: false,
        onRefresh: _loadProfile,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _buildProfileDetails(context, authProvider, localizations),
        ),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
    );
  }

  Widget _buildProfileDetails(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations? localizations,
  ) {
    final profile = _profile!;
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
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: profile['imageUrl'] != null
                    ? NetworkImage(profile['imageUrl'] as String)
                          as ImageProvider
                    : null,
                child: profile['imageUrl'] == null
                    ? const Icon(Icons.store, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                profile['name'] ?? 'İşletme Adı',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (profile['city'] != null)
                Text(
                  profile['city'] as String,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'İşletme Bilgileri',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile['address'] != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Adres',
                    profile['address'] as String,
                  ),
                if (profile['phoneNumber'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone,
                    'Telefon',
                    profile['phoneNumber'] as String,
                  ),
                ],
                if (profile['description'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.description,
                    'Açıklama',
                    profile['description'] as String,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Ayarlar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(localizations?.editProfile ?? 'Profili Düzenle'),
          subtitle: Text(
            localizations?.editProfileDescription ??
                'İşletme adı, adres ve iletişim bilgilerini düzenle',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            print('VendorProfileScreen: Edit profile tapped');
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VendorEditProfileScreen(),
              ),
            );
            if (result == true && mounted) {
              await _loadProfile();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('İşletme Ayarları'),
          subtitle: const Text(
            'Minimum sipariş, teslimat ücreti ve diğer ayarlar',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            print('VendorProfileScreen: Settings tapped');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VendorSettingsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(localizations?.selectLanguage ?? 'Dil Seçimi'),
          subtitle: Text(currentLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            print('VendorProfileScreen: Language settings tapped');
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LanguageSettingsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          onTap: () async {
            print('VendorProfileScreen: Logout tapped');
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Çıkış Yap'),
                content: const Text('Çıkış yapmak istediğine emin misin?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('İptal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Çıkış Yap',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true && mounted) {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final role = await authProvider.logout();
              if (!mounted) return;
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';

import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/edit_profile_screen.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/settings_screen.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profileLoadFailed(e.toString()),
            ),
          ),
        );
      }
    }
  }

  String _getLanguageDisplayName(BuildContext context, String languageCode) {
    final localizations = AppLocalizations.of(context)!;
    switch (languageCode) {
      case 'tr':
        return localizations.languageNameTr;
      case 'en':
        return localizations.languageNameEn;
      case 'ar':
        return localizations.languageNameAr;
      default:
        return localizations.languageNameEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            VendorHeader(
              title: localizations.vendorProfileTitle,
              subtitle:
                  authProvider.fullName ??
                  authProvider.email ??
                  localizations.vendorFallbackSubtitle,
              leadingIcon: Icons.person_outline,
              showBackButton: false,
              onRefresh: _loadProfile,
            ),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const VendorBottomNav(currentIndex: 4),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            VendorHeader(
              title: localizations.vendorProfileTitle,
              subtitle:
                  authProvider.fullName ??
                  authProvider.email ??
                  localizations.vendorFallbackSubtitle,
              leadingIcon: Icons.person_outline,
              showBackButton: false,
              onRefresh: _loadProfile,
            ),
            Expanded(
              child: Center(child: Text(localizations.profileLoadFailed(''))),
            ),
          ],
        ),
        bottomNavigationBar: const VendorBottomNav(currentIndex: 4),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          VendorHeader(
            title: localizations.vendorProfileTitle,
            subtitle:
                authProvider.fullName ??
                authProvider.email ??
                localizations.vendorFallbackSubtitle,
            leadingIcon: Icons.person_outline,
            showBackButton: false,
            onRefresh: _loadProfile,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: _buildProfileDetails(
                  context,
                  authProvider,
                  localizations,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 4),
    );
  }

  Widget _buildProfileDetails(
    BuildContext context,
    AuthProvider authProvider,
    AppLocalizations localizations,
  ) {
    final profile = _profile!;
    final localizationProvider = Provider.of<LocalizationProvider>(
      context,
      listen: false,
    );
    final currentLanguage = _getLanguageDisplayName(
      context,
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
                profile['name'] ?? localizations.businessNameFallback,
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
        Text(
          localizations.businessInfo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    localizations.addressLabel,
                    profile['address'] as String,
                  ),
                if (profile['phoneNumber'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.phone,
                    localizations.phoneLabel,
                    profile['phoneNumber'] as String,
                  ),
                ],
                if (profile['description'] != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.description,
                    localizations.description,
                    profile['description'] as String,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          localizations.generalSettings,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(localizations.editProfile),
          subtitle: Text(localizations.editProfileDescription),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            LoggerService().debug('VendorProfileScreen: Edit profile tapped');
            final result = await Navigator.of(context).push(
              NoSlidePageRoute(
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
          title: Text(localizations.businessSettingsTitle),
          subtitle: Text(localizations.businessSettingsSubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug('VendorProfileScreen: Settings tapped');
            Navigator.of(context).push(
              NoSlidePageRoute(
                builder: (context) => const VendorSettingsScreen(),
              ),
            );
          },
        ),
        /* Delivery Zones Disabled
        ListTile(
          leading: const Icon(Icons.map_outlined),
          title: Text(localizations.deliveryZones),
          subtitle: Text(localizations.deliveryZonesDescription),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug('VendorProfileScreen: Delivery Zones tapped');
            Navigator.of(context).push(
              NoSlidePageRoute(
                builder: (context) => const DeliveryZonesScreen(),
              ),
            );
          },
        ),
        */
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(localizations.selectLanguage),
          subtitle: Text(currentLanguage),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            LoggerService().debug(
              'VendorProfileScreen: Language settings tapped',
            );
            Navigator.of(context).push(
              NoSlidePageRoute(
                builder: (context) => const LanguageSettingsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(
            localizations.logout,
            style: const TextStyle(color: Colors.red),
          ),
          onTap: () {
            LoggerService().debug('VendorProfileScreen: Logout tapped');
            _showLogoutDialog(context, authProvider, localizations);
          },
        ),
        const SizedBox(height: 32),
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

  void _showLogoutDialog(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations localizations,
  ) {
    // Parent context'i kaydet (dialog context'i değil)
    final parentContext = context;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.vendorPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: AppTheme.vendorPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.logoutConfirmTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizations.logoutConfirmMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        localizations.cancel,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Dialog'u kapat
                        Navigator.of(dialogContext).pop();

                        // Navigator'ı logout öncesi kaydet (context dispose edilmeden önce)
                        NavigatorState? navigator;
                        try {
                          navigator = Navigator.of(parentContext);
                        } catch (e, stackTrace) {
                          LoggerService().error(
                            'Error getting navigator',
                            e,
                            stackTrace,
                          );
                          return; // Navigator bulunamazsa işlemi durdur
                        }

                        // Logout öncesi role bilgisini al
                        final role = auth.role;

                        // ÖNCE login sayfasına yönlendir (keşfet sayfasına gitmesin)
                        try {
                          // Role'e göre ilgili login sayfasına yönlendir
                          if (role?.toLowerCase() == 'courier') {
                            navigator.pushNamedAndRemoveUntil(
                              '/courier/login',
                              (route) => false,
                            );
                          } else if (role?.toLowerCase() == 'vendor') {
                            navigator.pushNamedAndRemoveUntil(
                              '/vendor/login',
                              (route) => false,
                            );
                          } else {
                            navigator.pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          }
                        } catch (e, stackTrace) {
                          // Navigator artık geçerli değilse hata yok sayılır
                          LoggerService().error(
                            'Error navigating to login',
                            e,
                            stackTrace,
                          );
                        }

                        // SONRA logout işlemini yap (yönlendirme yapıldıktan sonra)
                        // Bu sayede auth state değişikliği login sayfasında olur, keşfet sayfasına gitmez
                        await auth.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vendorPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        localizations.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

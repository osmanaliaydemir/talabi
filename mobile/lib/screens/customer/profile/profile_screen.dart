import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

import 'package:mobile/screens/shared/settings/accessibility_settings_screen.dart';
import 'package:mobile/screens/customer/profile/addresses_screen.dart';
import 'package:mobile/screens/customer/profile/change_password_screen.dart';
import 'package:mobile/screens/customer/profile/edit_profile_screen.dart';
import 'package:mobile/screens/shared/settings/language_settings_screen.dart';
import 'package:mobile/screens/shared/settings/notification_settings_screen.dart';
import 'package:mobile/screens/customer/order/order_history_screen.dart';
import 'package:mobile/screens/shared/settings/legal_menu_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getProfile();
      if (!mounted) return; // Prevent setState after dispose
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // Prevent setState after dispose
      setState(() {
        _isLoading = false;
      });
      final l10n = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: '${l10n.profileLoadFailed}: $e',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Column(
              children: [
                // Header
                SharedHeader(fullName: _profile?['fullName']),
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

  Widget _buildContentCard(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
    AuthProvider auth,
  ) {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacingMedium),
      decoration: AppTheme.cardDecoration(withShadow: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // My Account Section
          _buildSectionHeader(
            localizations.editProfile,
            localizations.myAccount,
          ),
          _buildMenuItem(
            icon: Icons.person,
            title: localizations.editProfile,
            subtitle: localizations.updatePersonalInfo,
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
            subtitle: localizations.orderHistoryDescription,
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
            subtitle: localizations.myAddressesDescription,
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
            icon: Icons.lock,
            title: localizations.changePassword,
            subtitle: localizations.changePasswordSubtitle,
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
          // Settings Section
          _buildSectionHeader(localizations.settings, localizations.settings),
          _buildMenuItem(
            icon: Icons.notifications,
            title: localizations.notificationSettings,
            subtitle: localizations.notificationSettingsDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: localizations.selectLanguage,
            subtitle: localizations.selectLanguageDescription,
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
            title: localizations.accessibilityAndDisplay,
            subtitle: localizations.accessibilityDescription,
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
            icon: Icons.gavel,
            title: localizations.legalDocuments,
            subtitle: localizations.legalDocumentsDescription,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LegalMenuScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: localizations.helpCenter,
            subtitle: localizations.helpCenterDescription,
            onTap: () {
              _showHelpCenter(context, localizations);
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: localizations.logout,
            subtitle: localizations.logoutDescription,
            titleColor: AppTheme.error,
            iconColor: AppTheme.error,
            onTap: () {
              _showLogoutDialog(context, auth, localizations);
            },
          ),
          SizedBox(height: AppTheme.spacingMedium),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sectionTitle) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingMedium,
        AppTheme.spacingSmall,
      ),
      child: Text(
        sectionTitle,
        style: AppTheme.poppins(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
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
      leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary),
      title: Text(
        title,
        style: AppTheme.poppins(
          color: titleColor ?? AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTheme.poppins(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            )
          : null,
      trailing: titleColor == AppTheme.error
          ? null
          : Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingXSmall,
      ),
    );
  }

  void _showHelpCenter(BuildContext context, AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.helpCenter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.howCanWeHelpYou,
              style: AppTheme.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(height: AppTheme.spacingMedium),
            _buildHelpItem(
              icon: Icons.help_outline,
              title: localizations.faq,
              subtitle: localizations.frequentlyAskedQuestions,
              colorScheme: colorScheme,
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.email_outlined,
              title: localizations.contactSupport,
              subtitle: 'support@talabi.com',
              colorScheme: colorScheme,
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.phone_outlined,
              title: localizations.callUs,
              subtitle: '+90 (555) 123 45 67',
              colorScheme: colorScheme,
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.chat_bubble_outline,
              title: localizations.liveChat,
              subtitle: localizations.available24x7,
              colorScheme: colorScheme,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () {
        // Handle help item tap
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: AppTheme.iconSizeMedium,
            ),
            SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textHint),
          ],
        ),
      ),
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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.logout,
                        color: Colors.red.shade700,
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
                        } catch (e) {
                          print('Error getting navigator: $e');
                          return; // Navigator bulunamazsa işlemi durdur
                        }

                        // Reset bottom navigation index
                        if (mounted) {
                          try {
                            Provider.of<BottomNavProvider>(
                              parentContext,
                              listen: false,
                            ).reset();
                          } catch (e) {
                            // Provider context'i artık geçerli değilse hata yok sayılır
                            print('Error resetting bottom nav: $e');
                          }
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
                        } catch (e) {
                          // Navigator artık geçerli değilse hata yok sayılır
                          print('Error navigating to login: $e');
                        }

                        // SONRA logout işlemini yap (yönlendirme yapıldıktan sonra)
                        // Bu sayede auth state değişikliği login sayfasında olur, keşfet sayfasına gitmez
                        await auth.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
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

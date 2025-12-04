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
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.email_outlined,
              title: localizations.contactSupport,
              subtitle: 'support@talabi.com',
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.phone_outlined,
              title: localizations.callUs,
              subtitle: '+90 (555) 123 45 67',
            ),
            SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.chat_bubble_outline,
              title: localizations.liveChat,
              subtitle: localizations.available24x7,
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
              color: AppTheme.primaryOrange,
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.logoutConfirmTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localizations.logoutConfirmMessage,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          localizations.cancel,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();

                          // Reset bottom navigation index
                          if (mounted) {
                            Provider.of<BottomNavProvider>(
                              context,
                              listen: false,
                            ).reset();
                          }

                          final role = await auth.logout();

                          // Navigate to login screen and clear navigation stack
                          if (mounted) {
                            // Role'e göre ilgili login sayfasına yönlendir
                            if (role?.toLowerCase() == 'courier') {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/courier/login',
                                (route) => false,
                              );
                            } else if (role?.toLowerCase() == 'vendor') {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/vendor/login',
                                (route) => false,
                              );
                            } else {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations.logout,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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

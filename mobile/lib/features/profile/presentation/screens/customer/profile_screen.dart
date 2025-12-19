import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/settings/presentation/screens/accessibility_settings_screen.dart';
import 'package:mobile/features/profile/presentation/screens/customer/addresses_screen.dart';
import 'package:mobile/features/profile/presentation/screens/customer/change_password_screen.dart';
import 'package:mobile/features/profile/presentation/screens/customer/edit_profile_screen.dart';
import 'package:mobile/features/settings/presentation/screens/language_settings_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_history_screen.dart';
import 'package:mobile/features/settings/presentation/screens/legal_menu_screen.dart';
import 'package:mobile/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
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
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
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
            icon: Icons.favorite,
            title: localizations.myFavoriteProducts,
            subtitle: localizations.myFavoriteProductsDescription,
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
          const SizedBox(height: AppTheme.spacingMedium),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String sectionTitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
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
          : const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
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
            const SizedBox(height: AppTheme.spacingMedium),
            _buildHelpItem(
              icon: Icons.help_outline,
              title: localizations.faq,
              subtitle: localizations.frequentlyAskedQuestions,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.email_outlined,
              title: localizations.contactSupport,
              subtitle: 'support@talabi.com',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            _buildHelpItem(
              icon: Icons.phone_outlined,
              title: localizations.callUs,
              subtitle: '+90 (555) 123 45 67',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: AppTheme.spacingSmall),
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
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSmall),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: AppTheme.iconSizeMedium,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
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
                  const SizedBox(height: 2),
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
            const Icon(Icons.chevron_right, color: AppTheme.textHint),
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
        return CustomConfirmationDialog(
          title: localizations.logoutConfirmTitle,
          message: localizations.logoutConfirmMessage,
          confirmText: localizations.logout,
          cancelText: localizations.cancel,
          icon: Icons.logout,
          iconColor: Colors.red.shade700,
          confirmButtonColor: Colors.red.shade700,
          onConfirm: () async {
            // Dialog'u kapat
            Navigator.of(dialogContext).pop();

            // Navigator'ı logout öncesi kaydet (context dispose edilmeden önce)
            NavigatorState? navigator;
            try {
              navigator = Navigator.of(parentContext);
            } catch (e) {
              LoggerService().error(
                'Error getting navigator: $e',
                e,
              );
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
                LoggerService().error(
                  'Error resetting bottom nav: $e',
                  e,
                );
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
              LoggerService().error(
                'Error navigating to login: $e',
                e,
              );
            }

            // SONRA logout işlemini yap (yönlendirme yapıldıktan sonra)
            // Bu sayede auth state değişikliği login sayfasında olur, keşfet sayfasına gitmez
            await auth.logout();
          },
          onCancel: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }
}

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
import 'package:mobile/features/reviews/presentation/screens/customer/user_reviews_screen.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final profile = await _apiService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SharedHeader(
            title: localizations.profile,
            fullName: authProvider.fullName,
            showBackButton: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
              ),
              children: [
                const SizedBox(height: AppTheme.spacingMedium),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: localizations.editProfile,
                  subtitle: localizations.editProfile,
                  onTap: () {
                    if (_profile != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfileScreen(profile: _profile!),
                        ),
                      ).then((updated) {
                        if (updated == true) _fetchProfile();
                      });
                    }
                  },
                  trailing: _isLoadingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
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
                  icon: Icons.shopping_bag,
                  title: localizations.orderHistory,
                  subtitle: localizations.orderHistory,
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
                  icon: Icons.favorite_outline,
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
                  icon: Icons.star_border,
                  title: localizations.myReviews,
                  subtitle: localizations.myReviewsDescription,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserReviewsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.lock_outline,
                  title: localizations.changePassword,
                  subtitle: localizations.changePassword,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications_none,
                  title: localizations.notifications,
                  subtitle: localizations.notifications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.language,
                  title: localizations.language,
                  subtitle: localizations.language,
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
                  icon: Icons.accessibility,
                  title: localizations.myProfile,
                  subtitle: localizations.myProfile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AccessibilitySettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: localizations.myProfile,
                  subtitle: localizations.myProfile,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LegalMenuScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                _buildLogoutButton(context, localizations),
                const SizedBox(height: AppTheme.spacingLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(AppTheme.spacingSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(icon, color: AppTheme.primaryOrange, size: 24),
        ),
        title: Text(
          title,
          style: AppTheme.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.poppins(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing:
            trailing ??
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 20,
            ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _showLogoutConfirmation(context, localizations),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
        ),
        child: Text(
          localizations.logout,
          style: AppTheme.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: localizations.logout,
        message: localizations.logoutConfirmation,
        confirmText: localizations.logout,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthProvider>().logout();
      context.read<BottomNavProvider>().reset();
    }
  }
}

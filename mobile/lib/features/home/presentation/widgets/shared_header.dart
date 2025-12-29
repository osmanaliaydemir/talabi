import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/search/presentation/screens/search_screen.dart';
import 'package:mobile/features/notifications/presentation/screens/customer/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/cart/presentation/screens/cart_screen.dart';

class SharedHeader extends StatelessWidget {
  const SharedHeader({
    super.key,
    this.title,
    this.subtitle,
    this.fullName,
    this.icon,
    this.showBackButton = false,
    this.onBack,
    this.action,
    this.showSearch = true,
    this.showNotifications = true,
    this.showCart = false,
    this.onCartTap,
    this.isCompact = false,
  });

  final String? title;
  final String? subtitle;
  final String? fullName;
  final IconData? icon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? action;
  final bool showSearch;
  final bool showNotifications;
  final bool showCart;
  final VoidCallback? onCartTap;
  final bool isCompact;
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isCompact ? 6 : 8,
          ),
          child: Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppTheme.textOnPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.textOnPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
              ],
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title ?? localizations.myProfile,
                      style: AppTheme.poppins(
                        color: AppTheme.textOnPrimary,
                        fontSize: isCompact ? 19 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCompact || (subtitle != null || fullName != null))
                      const SizedBox(height: 2),
                    if (subtitle != null || fullName != null)
                      Text(
                        subtitle ?? fullName ?? localizations.user,
                        style: AppTheme.poppins(
                          color: AppTheme.textOnPrimary.withValues(alpha: 0.9),
                          fontSize: isCompact ? 12 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              if (action != null)
                action!
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Icon
                    if (showSearch) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: isCompact ? 36 : 40,
                          height: isCompact ? 36 : 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: isCompact ? 20 : 22,
                          ),
                        ),
                      ),
                      if (showNotifications) const SizedBox(width: 8),
                    ],
                    // Notification Icon
                    if (showNotifications) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: isCompact ? 36 : 40,
                              height: isCompact ? 36 : 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: isCompact ? 20 : 22,
                              ),
                            ),
                            Consumer<NotificationProvider>(
                              builder: (context, notificationProvider, child) {
                                if (notificationProvider.unreadCount > 0) {
                                  return Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${notificationProvider.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Cart Icon
                    if (showCart) ...[
                      if (showSearch || showNotifications)
                        const SizedBox(width: 8),
                      GestureDetector(
                        onTap:
                            onCartTap ??
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CartScreen(showBackButton: true),
                                ),
                              );
                            },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: isCompact ? 36 : 40,
                              height: isCompact ? 36 : 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: isCompact ? 20 : 22,
                              ),
                            ),
                            Consumer<CartProvider>(
                              builder: (context, cartProvider, child) {
                                if (cartProvider.itemCount > 0) {
                                  return Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${cartProvider.itemCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

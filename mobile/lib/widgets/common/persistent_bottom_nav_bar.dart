import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';

class PersistentBottomNavBar extends StatelessWidget {
  const PersistentBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bottomNav = Provider.of<BottomNavProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    final List<String> screenNames = [
      localizations.discover,
      localizations.myFavorites,
      localizations.myCart,
      localizations.myOrders,
      localizations.myAccount,
    ];

    return SizedBox(
      height: 60,
      child: NavigationBar(
        selectedIndex: bottomNav.currentIndex,
        height: 60,
        onDestinationSelected: (index) {
          final fromIndex = bottomNav.currentIndex;
          final toLabel = screenNames[index];
          TapLogger.logBottomNavChange(fromIndex, index, toLabel);
          bottomNav.setIndex(index);

          // Navigate back to MainNavigationScreen if we're on a sub-page
          final navigator = Navigator.of(context);
          // Pop all routes until we reach the main navigation screen
          while (navigator.canPop()) {
            navigator.pop();
          }
        },
        labelTextStyle: MaterialStateProperty.all(
          AppTheme.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: AppTheme.textPrimary,
          ),
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined, size: 22),
            selectedIcon: const Icon(Icons.explore, size: 22),
            label: localizations.discover,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_outline, size: 22),
            selectedIcon: const Icon(Icons.favorite, size: 22),
            label: localizations.myFavorites,
          ),
          NavigationDestination(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 22),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXSmall / 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: AppTheme.poppins(
                          color: AppTheme.textOnPrimary,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: Stack(
              children: [
                const Icon(Icons.shopping_cart, size: 22),
                if (cart.itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingXSmall / 2),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${cart.itemCount}',
                        style: AppTheme.poppins(
                          color: AppTheme.textOnPrimary,
                          fontSize: 6,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: localizations.myCart,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined, size: 22),
            selectedIcon: const Icon(Icons.receipt_long, size: 22),
            label: localizations.myOrders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline, size: 22),
            selectedIcon: const Icon(Icons.person, size: 22),
            label: localizations.myAccount,
          ),
        ],
      ),
    );
  }
}

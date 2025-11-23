import 'package:flutter/material.dart';
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

    return NavigationBar(
      selectedIndex: bottomNav.currentIndex,
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
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.explore_outlined),
          selectedIcon: const Icon(Icons.explore),
          label: localizations.discover,
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_outline),
          selectedIcon: const Icon(Icons.favorite),
          label: localizations.myFavorites,
        ),
        NavigationDestination(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart_outlined),
              if (cart.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          selectedIcon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (cart.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: localizations.myCart,
        ),
        NavigationDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long),
          label: localizations.myOrders,
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person),
          label: localizations.myAccount,
        ),
      ],
    );
  }
}

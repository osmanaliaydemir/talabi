import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/presentation/screens/vendor_dashboard_screen.dart';
import 'package:mobile/services/logger_service.dart';

class VendorBottomNav extends StatelessWidget {
  const VendorBottomNav({super.key, required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        LoggerService().debug('VendorBottomNav: tapped index $index');
        if (index == currentIndex) {
          return;
        }

        switch (index) {
          case 0:
            Navigator.of(context).pushReplacement(
              NoSlidePageRoute(builder: (_) => const VendorDashboardScreen()),
            );
            break;
          case 1:
            Navigator.of(context).pushNamed('/vendor/orders');
            break;
          case 2:
            Navigator.of(context).pushNamed('/vendor/products');
            break;
          case 3:
            Navigator.of(context).pushNamed('/vendor/profile');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: localizations?.roleVendor ?? 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag_outlined),
          label: localizations?.orders ?? 'Siparişler',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.inventory_2_outlined),
          label: localizations?.products ?? 'Ürünler',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: localizations?.profile ?? 'Profil',
        ),
      ],
    );
  }
}

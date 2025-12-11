import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/screens/courier/dashboard_screen.dart';

class CourierBottomNav extends StatelessWidget {
  final int currentIndex;

  const CourierBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        LoggerService().debug('CourierBottomNav: tapped index $index');
        if (index == currentIndex) {
          return;
        }

        switch (index) {
          case 0:
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CourierDashboardScreen()),
            );
            break;
          case 1:
            Navigator.of(context).pushNamed('/courier/active-deliveries');
            break;
          case 2:
            Navigator.of(context).pushNamed('/courier/earnings');
            break;
          case 3:
            Navigator.of(context).pushNamed('/courier/profile');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: localizations?.roleCourier ?? 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_shipping_outlined),
          label: localizations?.deliveries ?? 'Teslimatlar',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.ssid_chart_outlined),
          label: localizations?.earnings ?? 'Kazanç',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          label: localizations?.profile ?? 'Profil',
        ),
      ],
    );
  }
}

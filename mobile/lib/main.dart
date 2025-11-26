import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/screens/shared/onboarding/language_selection_screen.dart';
import 'package:mobile/screens/shared/auth/login_screen.dart';
import 'package:mobile/screens/shared/onboarding/main_navigation_screen.dart';
import 'package:mobile/screens/shared/onboarding/onboarding_screen.dart';
import 'package:mobile/screens/courier/order_detail_screen.dart';
import 'package:mobile/screens/courier/order_map_screen.dart';
import 'package:mobile/screens/courier/courier_profile_screen.dart';
import 'package:mobile/screens/courier/delivery_proof_screen.dart';
import 'package:mobile/screens/courier/courier_dashboard_screen.dart';
import 'package:mobile/screens/courier/courier_active_deliveries_screen.dart';
import 'package:mobile/screens/courier/courier_availability_screen.dart';
import 'package:mobile/screens/courier/courier_edit_profile_screen.dart';
import 'package:mobile/screens/courier/courier_delivery_history_screen.dart';
import 'package:mobile/screens/courier/earnings_screen.dart';
import 'package:mobile/screens/courier/courier_notifications_screen.dart';
import 'package:mobile/screens/courier/courier_navigation_settings_screen.dart';
import 'package:mobile/screens/vendor/vendor_dashboard_screen.dart';
import 'package:mobile/screens/vendor/vendor_orders_screen.dart';
import 'package:mobile/screens/vendor/vendor_products_screen.dart';
import 'package:mobile/screens/vendor/vendor_profile_screen.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache service
  await CacheService.init();

  // Initialize connectivity and sync services
  final connectivityService = ConnectivityService();
  final syncService = SyncService(connectivityService);

  // Initialize API service with connectivity
  final apiService = ApiService();
  apiService.setConnectivityService(connectivityService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(
          create: (context) => ConnectivityProvider(connectivityService),
        ),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => CartProvider(
            syncService: syncService,
            connectivityProvider: context.read<ConnectivityProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _rebuildKey = 0;

  Future<bool> _checkLanguageSelection() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('language_selection_completed') ?? false;
  }

  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  void _onLanguageSelected() {
    setState(() {
      _rebuildKey++;
    });
  }

  Widget _buildHome() {
    return FutureBuilder<bool>(
      key: ValueKey(_rebuildKey),
      future: _checkLanguageSelection(),
      builder: (context, languageSnapshot) {
        if (languageSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show language selection if not completed
        if (languageSnapshot.data == false) {
          return LanguageSelectionScreen(
            onLanguageSelected: _onLanguageSelected,
          );
        }

        // Check onboarding status
        return FutureBuilder<bool>(
          future: _checkOnboardingStatus(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Show onboarding if not completed
            if (onboardingSnapshot.data == false) {
              return const OnboardingScreen();
            }

            // Otherwise show normal app flow
            return Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final role = auth.role?.toLowerCase();
                final isCourier = role == 'courier';
                final isVendor = role == 'vendor';

                if (auth.isAuthenticated) {
                  if (isCourier) {
                    return const CourierDashboardScreen();
                  } else if (isVendor) {
                    return const VendorDashboardScreen();
                  } else {
                    return const MainNavigationScreen();
                  }
                } else {
                  return FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final autoLoginRole = auth.role?.toLowerCase();
                      final autoLoginCourier = autoLoginRole == 'courier';
                      final autoLoginVendor = autoLoginRole == 'vendor';

                      if (auth.isAuthenticated) {
                        if (autoLoginCourier) {
                          return const CourierDashboardScreen();
                        } else if (autoLoginVendor) {
                          return const VendorDashboardScreen();
                        } else {
                          return const MainNavigationScreen();
                        }
                      }

                      return const LoginScreen();
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationProvider, ThemeProvider>(
      builder: (context, localization, themeProvider, _) {
        return MaterialApp(
          title: 'Talabi',
          debugShowCheckedModeBanner: false,
          locale: localization.locale,
          navigatorObservers: [NavigationLogger()],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr'), Locale('en'), Locale('ar')],
          theme: themeProvider.isHighContrast
              ? themeProvider.highContrastTheme
              : themeProvider.lightTheme,
          darkTheme: themeProvider.isHighContrast
              ? themeProvider.highContrastTheme
              : themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routes: {'/login': (context) => const LoginScreen()},
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/courier/order-detail':
                final orderId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(orderId: orderId),
                );
              case '/courier/order-map':
                final order = settings.arguments as CourierOrder;
                return MaterialPageRoute(
                  builder: (context) => OrderMapScreen(order: order),
                );
              case '/courier/profile':
                return MaterialPageRoute(
                  builder: (context) => const CourierProfileScreen(),
                );
              case '/courier/profile/edit':
                return MaterialPageRoute(
                  builder: (context) => const CourierEditProfileScreen(),
                );
              case '/courier/notifications':
                return MaterialPageRoute(
                  builder: (context) => const CourierNotificationsScreen(),
                );
              case '/courier/earnings':
                return MaterialPageRoute(
                  builder: (context) => const EarningsScreen(),
                );
              case '/courier/availability':
                return MaterialPageRoute(
                  builder: (context) => const CourierAvailabilityScreen(),
                );
              case '/courier/navigation-settings':
                return MaterialPageRoute(
                  builder: (context) => const CourierNavigationSettingsScreen(),
                );
              case '/courier/active-deliveries':
                return MaterialPageRoute(
                  builder: (context) => const CourierActiveDeliveriesScreen(),
                );
              case '/courier/delivery-history':
                return MaterialPageRoute(
                  builder: (context) => const CourierDeliveryHistoryScreen(),
                );
              case '/courier/delivery-proof':
                final orderId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (context) => DeliveryProofScreen(orderId: orderId),
                );
              case '/vendor/orders':
                return MaterialPageRoute(
                  builder: (context) => const VendorOrdersScreen(),
                );
              case '/vendor/products':
                return MaterialPageRoute(
                  builder: (context) => const VendorProductsScreen(),
                );
              case '/vendor/profile':
                return MaterialPageRoute(
                  builder: (context) => const VendorProfileScreen(),
                );
              default:
                return null;
            }
          },
          home: _buildHome(),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaleFactor: themeProvider.textScaleFactor),
              child: child!,
            );
          },
        );
      },
    );
  }
}

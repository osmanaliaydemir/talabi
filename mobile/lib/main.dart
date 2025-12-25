import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile/features/coupons/presentation/providers/coupon_provider.dart';
import 'package:mobile/features/auth/presentation/screens/customer/login_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:mobile/routers/app_router.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:mobile/config/injection.dart';
import 'package:mobile/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const MyApp());
}

/// The root widget of the application.
class MyApp extends StatelessWidget {
  /// Creates the root widget.
  const MyApp({super.key});

  static FirebaseAnalytics? analytics;
  static FirebaseAnalyticsObserver? observer;

  static void _initializeFirebaseAnalytics() {
    try {
      if (Firebase.apps.isNotEmpty) {
        analytics = FirebaseAnalytics.instance;
        observer = FirebaseAnalyticsObserver(analytics: analytics!);
      }
    } catch (e, stackTrace) {
      LoggerService().warning(
        'Firebase Analytics not available',
        e,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _initializeFirebaseAnalytics();

    return MultiProvider(
      providers: [
        // Critical providers (initialize immediately)
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocalizationProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) =>
              ConnectivityProvider(getIt<ConnectivityService>()),
        ),
        // Lazy providers (initialize on first use - using lazy factory pattern)
        ChangeNotifierProvider(
          create: (context) => CartProvider(
            syncService: getIt<SyncService>(),
            connectivityProvider: context.read<ConnectivityProvider>(),
          ),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (context) => BottomNavProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(
          create: (context) => VendorProvider(),
          lazy: true,
        ),
        ChangeNotifierProvider(create: (context) => CouponProvider()),
      ],
      child: Consumer3<LocalizationProvider, ThemeProvider, BottomNavProvider>(
        builder: (context, localization, themeProvider, bottomNav, _) {
          // Initialize Logger Service after providers are available
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final authProvider = context.read<AuthProvider>();
            // LoggerService already has ConnectivityService via DI
            await LoggerService().init(authProvider: authProvider);
          });

          // BottomNavProvider'dan kategori değişikliğini ThemeProvider'a bildir
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (themeProvider.currentCategory != bottomNav.selectedCategory) {
              themeProvider.setCategory(bottomNav.selectedCategory);
            }
          });

          return MaterialApp(
            title: 'Talabi',
            debugShowCheckedModeBanner: false,
            locale: localization.locale,
            navigatorKey: NavigationService.navigatorKey,
            scaffoldMessengerKey: NavigationService.scaffoldMessengerKey,
            navigatorObservers: [
              if (kDebugMode) NavigationLogger(), // Only in debug mode
              if (observer != null) observer!,
            ],
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
            themeMode: ThemeMode.light,
            routes: {'/login': (context) => const LoginScreen()},
            onGenerateRoute: AppRouter.generateRoute,
            home: const SplashScreen(),
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(themeProvider.textScaleFactor),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

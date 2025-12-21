import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/screens/customer/login_screen.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate mocks
@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<LoggerService>()])
import 'auth_customer_e2e_test.mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;

  late AuthProvider authProvider;
  late CartProvider cartProvider;
  late BottomNavProvider bottomNavProvider;
  late ThemeProvider themeProvider;
  late NotificationProvider notificationProvider;
  late LocalizationProvider localizationProvider;

  setUp(() async {
    await GetIt.instance.reset();

    // Mock SharedPreferences for test environment
    SharedPreferences.setMockInitialValues({});

    mockApiService = MockApiService();
    mockLoggerService = MockLoggerService();

    if (!GetIt.instance.isRegistered<ApiService>()) {
      GetIt.instance.registerSingleton<ApiService>(mockApiService);
    }
    if (!GetIt.instance.isRegistered<LoggerService>()) {
      GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);
    }

    authProvider = AuthProvider(apiService: mockApiService);
    cartProvider = CartProvider(apiService: mockApiService);
    bottomNavProvider = BottomNavProvider();
    themeProvider = ThemeProvider();
    notificationProvider = NotificationProvider();
    localizationProvider = LocalizationProvider();

    ToastMessage.isTestMode = true;
    AnalyticsService.isTestMode = true;
  });

  Widget createApp({Widget? home}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<ConnectivityProvider>(
          create: (_) => ConnectivityProvider(FakeConnectivityService()),
        ),
        ChangeNotifierProvider<LocalizationProvider>.value(
          value: localizationProvider,
        ),
      ],
      child: MaterialApp(
        title: 'Customer Auth E2E Test',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        locale: const Locale('tr'),
        home: home ?? const LoginScreen(),
      ),
    );
  }

  group('Customer E2E Authentication Flow', () {
    testWidgets('should register, login, and logout customer successfully', (
      WidgetTester tester,
    ) async {
      // Mock register response
      when(mockApiService.register(any, any, any)).thenAnswer(
        (_) async => {
          'token': 'test_customer_token_123',
          'refreshToken': 'test_refresh_token',
          'userId': 'customer_user_123',
          'email': '[email protected]',
          'fullName': 'Test Customer',
          'role': 'Customer',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Mock login response
      when(mockApiService.login(any, any)).thenAnswer(
        (_) async => {
          'token': 'test_customer_token_123',
          'refreshToken': 'test_refresh_token',
          'userId': 'customer_user_123',
          'email': '[email protected]',
          'fullName': 'Test Customer',
          'role': 'Customer',
          'isActive': true,
          'isProfileComplete': true,
        },
      );

      // Build app to initialize widget binding
      await tester.pumpWidget(createApp());
      await tester.pumpAndSettle();

      // STEP 1: Register
      expect(authProvider.isAuthenticated, false);

      await authProvider.register(
        '[email protected]',
        'Test123!@#',
        'Test Customer',
      );
      await tester.pumpAndSettle();

      // Verify registration success
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.email, '[email protected]');
      expect(authProvider.fullName, 'Test Customer');
      expect(authProvider.role, 'Customer');
      expect(authProvider.userId, 'customer_user_123');

      // STEP 2: Logout
      await authProvider.logout();
      await tester.pumpAndSettle();

      // Verify logout success
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.email, null);

      // STEP 3: Login
      await authProvider.login('[email protected]', 'Test123!@#');
      await tester.pumpAndSettle();

      // Verify login Success
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.email, '[email protected]');
      expect(authProvider.role, 'Customer');

      // STEP 4: Final Logout
      await authProvider.logout();
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, false);

      // Verify API calls were made
      verify(
        mockApiService.register(
          '[email protected]',
          'Test123!@#',
          'Test Customer',
        ),
      ).called(1);
      verify(mockApiService.login('[email protected]', 'Test123!@#')).called(1);
    });
  });
}

class FakeConnectivityService implements ConnectivityService {
  @override
  Stream<bool> get connectivityStream => Stream.value(true);
  @override
  bool get isOnline => true;
  @override
  Future<bool> checkConnectivity() async => true;
  @override
  void dispose() {}
}

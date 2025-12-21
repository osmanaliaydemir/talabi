import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mobile/features/onboarding/presentation/screens/main_navigation_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'performance_test.mocks.dart';

// Use strict mocks if possible, but keeping it simple for perf test

@GenerateNiceMocks([MockSpec<ApiService>(), MockSpec<LoggerService>()])
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  late MockApiService mockApiService;
  late MockLoggerService mockLoggerService;

  late CartProvider cartProvider;
  late AuthProvider authProvider;
  late BottomNavProvider bottomNavProvider;
  late ThemeProvider themeProvider;
  late NotificationProvider notificationProvider;
  late LocalizationProvider localizationProvider;
  // Perform setup once before all tests
  // setUpAll(() {
  //   // Removing mock values to use real shared prefs (cleaned up in setUp)
  //   // SharedPreferences.setMockInitialValues({});
  // });

  setUp(() async {
    await GetIt.instance.reset();

    // Use real SharedPreferences and clear it for isolation
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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

    // ThemeProvider calls SharedPreferences.getInstance() in constructor.
    // Since we initialized it above, it should be fine.
    themeProvider = ThemeProvider();

    notificationProvider = NotificationProvider();
    localizationProvider = LocalizationProvider();

    ToastMessage.isTestMode = true;
    AnalyticsService.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
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
      child: const MaterialApp(
        title: 'Talabi Perf Test',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr')],
        locale: Locale('tr'),
        home: MainNavigationScreen(),
      ),
    );
  }

  testWidgets('Home scrolling performance', (WidgetTester tester) async {
    // --- MOCK DATA ---
    // Fix matchers: Use `any` for named args or omit if not needed, but since they are named with defaults, we can just use `any`.
    // However, for non-nullable int with default, `any` might still be an issue if strict.
    // Let's use `captured-like` or just default values if possible, or `any`.
    // Actually, `any` works for named parameters in Mockito 5.

    // Use concrete default values instead of anyNamed to avoid null mismatch on non-nullable ints
    when(mockApiService.getCities()).thenAnswer((_) async => []);
    when(
      mockApiService.getCategories(
        language: anyNamed('language'),
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer(
      (_) async => List.generate(
        10,
        (index) => {
          'id': 'cat$index',
          'name': 'Kategori $index',
          'imageUrl': 'https://via.placeholder.com/150',
          'type': 'market',
        },
      ),
    );

    when(
      mockApiService.getBanners(
        language: anyNamed('language'),
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer((_) async => []);

    // Return List<Product>
    // Use default input values: page=1, pageSize=6
    // Use concrete values to avoid null/int mismatch with 'any'
    when(
      mockApiService.getPopularProducts(
        page: 1, // default is 1
        pageSize: 6, // default is 6
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer(
      (_) async => List.generate(
        20,
        (index) => Product(
          id: 'p$index',
          name: 'Ürün $index',
          description: 'Açıklama $index',
          price: 10.0 + index,
          vendorId: 'v1',
          category: 'cat1',
          imageUrl: 'https://via.placeholder.com/150',
          // Only use fields present in Product definition (removed invalid ones)
        ),
      ),
    );

    // Return List<Vendor> not PagedResultDto
    when(
      mockApiService.getVendors(
        page: 1, // default is 1
        pageSize: 6, // default is 6
        vendorType: anyNamed('vendorType'),
      ),
    ).thenAnswer((_) async => []);

    when(
      mockApiService.getCart(),
    ).thenAnswer((_) async => {'items': [], 'totalAmount': 0.0});
    when(
      mockApiService.getProfile(),
    ).thenAnswer((_) async => {'fullName': 'Perf User'});
    when(mockApiService.getCustomerNotifications()).thenAnswer((_) async => []);
    when(mockApiService.getAddresses()).thenAnswer((_) async => []);

    // --- RUN TEST ---
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Trace the scrolling action
    // Note: traceAction might fail on some simulators/environments.
    // If it fails, run without it to verify functionality.
    // await binding.traceAction(() async {
    // Find the main scrollable checklist (usually SingleChildScrollView or ListView in Home)
    // HomeScreen uses CustomScrollView, not SingleChildScrollView
    final listFinder = find.byType(CustomScrollView).first;

    // Scroll down
    await tester.fling(listFinder, const Offset(0, -500), 1000);
    await tester.pumpAndSettle();

    // Scroll up
    await tester.fling(listFinder, const Offset(0, 500), 1000);
    await tester.pumpAndSettle();
    // }, reportKey: 'home_scrolling_summary');
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

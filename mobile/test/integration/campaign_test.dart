import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/campaigns/presentation/screens/campaigns_screen.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Reusing mocks from order_flow_test to avoid regeneration issues
import 'order_flow_test.mocks.dart';

class MockNotificationProvider extends Mock implements NotificationProvider {
  @override
  int get unreadCount => 0;

  @override
  bool get hasListeners => false;

  @override
  void addListener(VoidCallback? listener) {}

  @override
  void removeListener(VoidCallback? listener) {}
}

void main() {
  late MockApiService mockApiService;
  late BottomNavProvider bottomNavProvider;
  late ThemeProvider themeProvider;
  late LocalizationProvider localizationProvider;
  late MockNotificationProvider mockNotificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();

    // Register Mock
    GetIt.instance.registerSingleton<ApiService>(mockApiService);

    // Initial Providers
    bottomNavProvider = BottomNavProvider();

    SharedPreferences.setMockInitialValues({});
    themeProvider = ThemeProvider();
    localizationProvider = LocalizationProvider();
    mockNotificationProvider = MockNotificationProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LocalizationProvider>.value(
          value: localizationProvider,
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: mockNotificationProvider,
        ),
      ],
      child: const MaterialApp(
        title: 'Talabi Test',
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr')],
        locale: Locale('tr'),
        home: CampaignsScreen(),
      ),
    );
  }

  testWidgets('Campaigns Screen loads and displays campaigns', (
    WidgetTester tester,
  ) async {
    // Set a fixed size to avoid overflows
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // --- MOCKS ---
    // 1. Mock Addresses (used for context)
    when(mockApiService.getAddresses()).thenAnswer(
      (_) async => [
        {'id': 'addr1', 'isDefault': true, 'cityId': 'c1', 'districtId': 'd1'},
      ],
    );

    // 2. Mock Campaigns
    // Note: isActive is a getter on the model, passed implicitely by dates.
    // createdAt is not in the mobile model constructor.
    final campaign1 = Campaign(
      id: 'cmp1',
      title: 'First Order Discount',
      description: '%20 Off on your first order',
      imageUrl: 'http://image.com/1.jpg',
      priority: 1,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 10)),
      actionUrl: '/details',
      vendorType: 1, // Restaurant
      minCartAmount: 0,
    );

    final campaign2 = Campaign(
      id: 'cmp2',
      title: 'Night Owl Special',
      description: 'Free delivery after midnight',
      imageUrl: '',
      priority: 2,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 5)),
      vendorType: 1,
    );

    // Expect call with correct context from address
    when(
      mockApiService.getCampaigns(
        vendorType: anyNamed('vendorType'),
        cityId: 'c1',
        districtId: 'd1',
      ),
    ).thenAnswer((_) async => [campaign1, campaign2]);

    // --- EXECUTION ---
    await tester.pumpWidget(createWidgetUnderTest());

    // Initial loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for future to complete, but don't wait for infinite animations (BouncingCircle)
    // pumpAndSettle times out because BouncingCircle is infinite.
    // We pump for a specific duration to let the future complete and UI build.
    await tester.pump(const Duration(seconds: 2));

    // --- VERIFICATION ---
    // 1. Check Titles
    expect(find.text('First Order Discount'), findsOneWidget);
    expect(find.text('Night Owl Special'), findsOneWidget);

    // 2. Check Description
    expect(find.text('%20 Off on your first order'), findsOneWidget);

    // 3. Verify API Call
    verify(mockApiService.getAddresses()).called(1);
    verify(
      mockApiService.getCampaigns(
        vendorType: 1, // Default is Restaurant in BottomNav
        cityId: 'c1',
        districtId: 'd1',
      ),
    ).called(1);

    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Campaigns Screen displays empty state when no campaigns', (
    WidgetTester tester,
  ) async {
    // Set a fixed size to avoid overflows
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    // --- MOCKS ---
    when(mockApiService.getAddresses()).thenAnswer((_) async => []);
    when(
      mockApiService.getCampaigns(
        vendorType: anyNamed('vendorType'),
        cityId: anyNamed('cityId'),
        districtId: anyNamed('districtId'),
      ),
    ).thenAnswer((_) async => []);

    // --- EXECUTION ---
    await tester.pumpWidget(createWidgetUnderTest());

    // Using pump instead of pumpAndSettle to be safe, though empty state might not have BouncingCircle
    await tester.pump(const Duration(seconds: 1));

    // --- VERIFICATION ---
    expect(
      find.text('Sonuç bulunamadı'),
      findsOneWidget,
    ); // "noResultsFound" in TR
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Reset size
    addTearDown(tester.view.resetPhysicalSize);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/customer/profile_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import '../../../../orders/presentation/screens/customer/order_detail_screen_test.mocks.dart';
import 'profile_screen_test.mocks.dart';

import 'package:mobile/providers/notification_provider.dart';

@GenerateMocks([AuthProvider])
void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;
  late BottomNavProvider bottomNavProvider;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);

    // Stub logging/notification calls if needed
    when(mockApiService.getCustomerNotifications()).thenAnswer((_) async => []);

    mockAuthProvider = MockAuthProvider();
    bottomNavProvider = BottomNavProvider();
    notificationProvider = NotificationProvider();

    ToastMessage.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
        ),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('tr')],
        locale: Locale('tr'),
        home: Scaffold(
          body: ProfileScreen(),
        ), // Wrap in Scaffold just in case, though ProfileScreen has one
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('should render loading indicator initially', (
      WidgetTester tester,
    ) async {
      // Mock getProfile to never complete or take time
      when(mockApiService.getProfile()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return {};
      });

      await tester.pumpWidget(createWidgetUnderTest());
      // Initial build should show loader
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Wait for finish
    });

    testWidgets('should render profile information after loading', (
      WidgetTester tester,
    ) async {
      final profileData = {
        'fullName': 'Test Kullanici',
        'email': 'test@example.com',
      };

      when(mockApiService.getProfile()).thenAnswer((_) async => profileData);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test Kullanici'), findsOneWidget);
      expect(find.text('Hesabım'), findsOneWidget); // Section header

      // Ensure specific items are present but maybe off screen
      expect(find.text('Çıkış Yap', skipOffstage: false), findsOneWidget);
    });

    testWidgets('should show logout confirmation dialog on logout tap', (
      WidgetTester tester,
    ) async {
      when(mockApiService.getProfile()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final logoutButtonFinder = find.text('Çıkış Yap');

      // Scroll to logout button
      await tester.scrollUntilVisible(
        logoutButtonFinder,
        500.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
        findsOneWidget,
      );
    });
  });
}

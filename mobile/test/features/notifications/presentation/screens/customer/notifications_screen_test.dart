import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/notifications/presentation/screens/customer/notifications_screen.dart';
import 'package:mobile/features/notifications/data/models/customer_notification.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';

import '../../../../orders/presentation/screens/customer/order_detail_screen_test.mocks.dart';
import 'notifications_screen_test.mocks.dart';

@GenerateMocks([ThemeProvider])
void main() {
  late MockApiService mockApiService;
  late MockThemeProvider mockThemeProvider;
  late BottomNavProvider bottomNavProvider;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);

    mockThemeProvider = MockThemeProvider();
    bottomNavProvider = BottomNavProvider();
    notificationProvider = NotificationProvider();

    // Setup ThemeProvider stubs
    when(mockThemeProvider.currentCategory).thenReturn(MainCategory.market);
    when(mockThemeProvider.themeMode).thenReturn(ThemeMode.light);

    ToastMessage.isTestMode = true;
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
        ChangeNotifierProvider<BottomNavProvider>.value(
          value: bottomNavProvider,
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
        home: NotificationsScreen(), // NotificationsScreen has its own Scaffold
      ),
    );
  }

  group('NotificationsScreen Widget Tests', () {
    testWidgets('should render loading indicator initially', (
      WidgetTester tester,
    ) async {
      // Mock delayed response
      when(mockApiService.getCustomerNotifications()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return [];
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // process post frame callback
      // Initial build should show loader
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle(); // Wait for finish
    });

    testWidgets('should render empty state when no notifications', (
      WidgetTester tester,
    ) async {
      when(
        mockApiService.getCustomerNotifications(),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Henüz bildiriminiz yok.'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
    });

    testWidgets('should render notifications list', (
      WidgetTester tester,
    ) async {
      final notifications = [
        CustomerNotification(
          id: '1',
          title: 'Siparişiniz Yola Çıktı',
          message: 'Siparişiniz kuryeye teslim edildi.',
          type: 'order',
          isRead: false,
          createdAt: DateTime.now(),
        ),
        CustomerNotification(
          id: '2',
          title: 'Kampanya',
          message: 'Yarın tüm ürünlerde %10 indirim!',
          type: 'promo',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      when(
        mockApiService.getCustomerNotifications(),
      ).thenAnswer((_) async => notifications);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Siparişiniz Yola Çıktı'), findsOneWidget);
      expect(find.text('Kampanya'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should mark notification as read on tap', (
      WidgetTester tester,
    ) async {
      final notifications = [
        CustomerNotification(
          id: '1',
          title: 'Unread Notification',
          message: 'Tap to mark as read',
          type: 'system',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      when(
        mockApiService.getCustomerNotifications(),
      ).thenAnswer((_) async => notifications);
      when(
        mockApiService.markNotificationAsRead(any, any),
      ).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unread Notification'));
      await tester.pumpAndSettle();

      verify(mockApiService.markNotificationAsRead('customer', '1')).called(1);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/profile/presentation/screens/customer/add_edit_address_screen.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'add_edit_address_screen_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;
  late NotificationProvider notificationProvider;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    GetIt.instance.registerSingleton<ApiService>(mockApiService);
    notificationProvider = NotificationProvider();

    // Mock location data
    when(mockApiService.getCountries()).thenAnswer(
      (_) async => [
        {'id': '1', 'name': 'Türkiye'},
      ],
    );
    when(mockApiService.getLocationCities(any)).thenAnswer(
      (_) async => [
        {'id': '1', 'name': 'İstanbul'},
        {'id': '2', 'name': 'Ankara'},
      ],
    );
    when(mockApiService.getLocationDistricts(any)).thenAnswer(
      (_) async => [
        {'id': '1', 'name': 'Kadıköy'},
        {'id': '2', 'name': 'Beşiktaş'},
      ],
    );
    when(mockApiService.getLocationLocalities(any)).thenAnswer(
      (_) async => [
        {'id': '1', 'name': 'Moda'},
        {'id': '2', 'name': 'Fenerbahçe'},
      ],
    );
  });

  Widget createWidgetUnderTest({Address? address}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationProvider>.value(
          value: notificationProvider,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('tr')],
        locale: const Locale('tr'),
        home: AddEditAddressScreen(address: address),
      ),
    );
  }

  group('AddEditAddressScreen Widget Tests', () {
    testWidgets('should render add address form correctly', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Adres Ekle'), findsAtLeastNWidgets(1));
      expect(
        find.byType(TextFormField),
        findsAtLeastNWidgets(3),
      ); // title, fullAddress, postalCode
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsAtLeastNWidgets(3),
      ); // city, district, locality
    });

    testWidgets('should populate fields when editing existing address', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final testAddress = Address(
        id: 'a1',
        title: 'Ev',
        fullAddress: 'Test Sokak No:1',
        cityId: '1',
        cityName: 'İstanbul',
        districtId: '1',
        districtName: 'Kadıköy',
        localityId: '1',
        localityName: 'Moda',
        postalCode: '34710',
        latitude: 40.9876,
        longitude: 29.0123,
        isDefault: false,
      );

      await tester.pumpWidget(createWidgetUnderTest(address: testAddress));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Adresi Düzenle'), findsAtLeastNWidgets(1));

      // Verify title field contains the address title
      final titleFields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(titleFields.first.controller?.text, equals('Ev'));
    });
  });
}

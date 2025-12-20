import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/providers/connectivity_provider.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/settings/data/models/currency.dart';

import 'package:mobile/services/logger_service.dart';
import 'package:get_it/get_it.dart';

import 'cart_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<SyncService>(),
  MockSpec<ConnectivityProvider>(),
  MockSpec<LoggerService>(),
])
void main() {
  late CartProvider cartProvider;
  late MockApiService mockApiService;
  late MockSyncService mockSyncService;
  late MockConnectivityProvider mockConnectivityProvider;
  late MockLoggerService mockLoggerService;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockSyncService = MockSyncService();
    mockConnectivityProvider = MockConnectivityProvider();
    mockLoggerService = MockLoggerService();

    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    cartProvider = CartProvider(
      apiService: mockApiService,
      syncService: mockSyncService,
      connectivityProvider: mockConnectivityProvider,
    );
  });

  final testProduct = Product(
    id: '1',
    vendorId: 'vendor1',
    name: 'Test Product',
    price: 100.0,
    currency: Currency.try_,
    vendorName: 'Test Vendor',
  );

  group('CartProvider Tests', () {
    test('Initial state: items should be empty', () {
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test(
      'addItem should add product to cart and reload from API when online',
      () async {
        // Arrange
        when(mockConnectivityProvider.isOnline).thenReturn(true);
        when(mockApiService.addToCart(any, any)).thenAnswer((_) async => {});

        when(mockApiService.getCart()).thenAnswer(
          (_) async => {
            'items': [
              {
                'productId': '1',
                'productName': 'Test Product',
                'productPrice': 100.0,
                'quantity': 1,
                'vendorId': 'vendor1',
                'vendorName': 'Test Vendor',
                'id': 'backend_id_1',
                'currencyCode': 'TRY',
              },
            ],
          },
        );

        // Act
        await cartProvider.addItem(testProduct, null);

        // Assert
        expect(cartProvider.itemCount, 1);
        expect(cartProvider.items['1']?.product.id, '1');
        expect(cartProvider.items['1']?.quantity, 1);
        expect(cartProvider.totalAmount, 100.0);
        verify(mockApiService.addToCart('1', 1)).called(1);
        verify(mockApiService.getCart()).called(1);
      },
    );

    test(
      'addItem should add product optimistically and queue action when offline',
      () async {
        // Arrange
        when(mockConnectivityProvider.isOnline).thenReturn(false);

        // Act
        await cartProvider.addItem(testProduct, null);

        // Assert
        expect(cartProvider.itemCount, 1);
        expect(cartProvider.items['1']?.quantity, 1);
        expect(cartProvider.totalAmount, 100.0);
        verify(mockSyncService.addToQueue(any)).called(1);
        verifyNever(mockApiService.addToCart(any, any));
      },
    );

    test('clear should empty the cart', () async {
      // Arrange
      when(mockConnectivityProvider.isOnline).thenReturn(true);
      when(mockApiService.addToCart(any, any)).thenAnswer((_) async => {});
      when(mockApiService.getCart()).thenAnswer(
        (_) async => {
          'items': [
            {
              'productId': '1',
              'productName': 'Test Product',
              'productPrice': 100.0,
              'quantity': 1,
              'vendorId': 'vendor1',
              'vendorName': 'Test Vendor',
              'id': 'backend_id_1',
              'currencyCode': 'TRY',
            },
          ],
        },
      );
      await cartProvider.addItem(testProduct, null);
      expect(cartProvider.itemCount, 1);

      when(mockApiService.clearCart()).thenAnswer((_) async => {});

      // Act
      await cartProvider.clear();

      // Assert
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.totalAmount, 0.0);
      verify(mockApiService.clearCart()).called(1);
    });

    test(
      'increaseQuantity should update quantity locally and call API when online',
      () async {
        // Arrange
        when(mockConnectivityProvider.isOnline).thenReturn(true);
        when(mockApiService.getCart()).thenAnswer(
          (_) async => {
            'items': [
              {
                'productId': '1',
                'productName': 'Test Product',
                'productPrice': 100.0,
                'quantity': 1,
                'vendorId': 'vendor1',
                'vendorName': 'Test Vendor',
                'id': 'backend_id_1',
                'currencyCode': 'TRY',
              },
            ],
          },
        );
        await cartProvider.loadCart();

        when(
          mockApiService.updateCartItem(any, any),
        ).thenAnswer((_) async => {});

        // Act
        await cartProvider.increaseQuantity('1');

        // Assert
        expect(cartProvider.items['1']?.quantity, 2);
        expect(cartProvider.totalAmount, 200.0);
        verify(mockApiService.updateCartItem('backend_id_1', 2)).called(1);
      },
    );
  });
}

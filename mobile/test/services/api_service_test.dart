import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/services/api_request_scheduler.dart';
import 'package:dio/dio.dart';

import 'api_service_test.mocks.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile/services/logger_service.dart';
import 'package:get_it/get_it.dart';

import 'package:mobile/core/network/network_client.dart';
import 'package:mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mobile/features/products/data/datasources/product_remote_data_source.dart';
import 'package:mobile/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:mobile/features/vendors/data/datasources/vendor_remote_data_source.dart';

@GenerateNiceMocks([
  MockSpec<ConnectivityService>(),
  MockSpec<CacheService>(),
  MockSpec<ApiRequestScheduler>(),
  MockSpec<LoggerService>(),
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiService apiService;
  late MockConnectivityService mockConnectivityService;
  late MockCacheService mockCacheService;
  late MockApiRequestScheduler mockScheduler;
  late MockLoggerService mockLoggerService;
  late DioAdapter dioAdapter;

  setUp(() async {
    await GetIt.instance.reset();
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    mockConnectivityService = MockConnectivityService();
    mockCacheService = MockCacheService();
    mockScheduler = MockApiRequestScheduler();
    mockLoggerService = MockLoggerService();

    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    // Default behaviors
    when(mockConnectivityService.isOnline).thenReturn(true);
    when(
      mockScheduler.acquire(highPriority: anyNamed('highPriority')),
    ).thenAnswer((_) async => RequestPermit(() {}));

    // Initialize NetworkClient
    final networkClient = NetworkClient(mockConnectivityService, mockScheduler);

    // Initialize AuthRemoteDataSource
    final authRemoteDataSource = AuthRemoteDataSource(networkClient);
    final productRemoteDataSource = ProductRemoteDataSource(networkClient);
    final orderRemoteDataSource = OrderRemoteDataSource(networkClient);
    final vendorRemoteDataSource = VendorRemoteDataSource(networkClient);

    // Initialize ApiService
    apiService = ApiService.init(
      networkClient,
      authRemoteDataSource,
      productRemoteDataSource,
      orderRemoteDataSource,
      vendorRemoteDataSource,
      mockCacheService,
    );

    // Setup Dio Adapter
    dioAdapter = DioAdapter(dio: apiService.dio);
  });

  test('should check connectivity before request', () async {
    // Arrange
    when(mockConnectivityService.isOnline).thenReturn(false);
    when(
      mockConnectivityService.checkConnectivity(),
    ).thenAnswer((_) async => false);

    dioAdapter.onGet('/test', (server) => server.reply(200, {'data': 'ok'}));

    // Act & Assert
    try {
      await apiService.dio.get('/test');
      fail('Should throw exception');
    } catch (e) {
      expect(e, isA<DioException>());
    }
  });

  test('should return data when online', () async {
    // Arrange
    const route = '/test';

    dioAdapter.onGet(route, (server) => server.reply(200, {'data': 'success'}));

    // Act
    final response = await apiService.dio.get(route);

    // Assert
    expect(response.statusCode, 200);
    expect(response.data['data'], 'success');
  });
}

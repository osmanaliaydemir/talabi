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

@GenerateNiceMocks([
  MockSpec<ConnectivityService>(),
  MockSpec<CacheService>(),
  MockSpec<ApiRequestScheduler>(),
])
void main() {
  late ApiService apiService;
  late MockConnectivityService mockConnectivityService;
  late MockCacheService mockCacheService;
  late MockApiRequestScheduler mockScheduler;
  late DioAdapter dioAdapter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockConnectivityService = MockConnectivityService();
    mockCacheService = MockCacheService();
    mockScheduler = MockApiRequestScheduler();

    // Default behaviors
    when(mockConnectivityService.isOnline).thenReturn(true);
    when(
      mockScheduler.acquire(highPriority: anyNamed('highPriority')),
    ).thenAnswer((_) async => RequestPermit(() {}));

    // Initialize ApiService
    apiService = ApiService.init(
      mockConnectivityService,
      mockCacheService,
      mockScheduler,
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

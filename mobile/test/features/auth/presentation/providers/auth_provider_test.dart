import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/secure_storage_service.dart';

import 'package:mobile/services/logger_service.dart';
import 'package:get_it/get_it.dart';

import 'auth_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<SecureStorageService>(),
  MockSpec<LoggerService>(),
])
void main() {
  late AuthProvider authProvider;
  late MockApiService mockApiService;
  late MockSecureStorageService mockSecureStorage;
  late MockLoggerService mockLoggerService;

  setUp(() async {
    await GetIt.instance.reset();
    mockApiService = MockApiService();
    mockSecureStorage = MockSecureStorageService();
    mockLoggerService = MockLoggerService();

    GetIt.instance.registerSingleton<LoggerService>(mockLoggerService);

    authProvider = AuthProvider(
      apiService: mockApiService,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthProvider Tests', () {
    test('Initial state: not authenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, isNull);
    });

    test('login should set auth data and save to secure storage', () async {
      // Arrange
      final loginResponse = {
        'token': 'test_token',
        'refreshToken': 'test_refresh_token',
        'userId': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'Customer',
        'isActive': true,
      };

      when(
        mockApiService.login(any, any),
      ).thenAnswer((_) async => loginResponse);

      // Act
      await authProvider.login('test@example.com', 'password123');

      // Assert
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'test_token');
      expect(authProvider.userId, 'user_123');
      expect(authProvider.role, 'Customer');

      verify(mockSecureStorage.setToken('test_token')).called(1);
      verify(mockSecureStorage.setUserId('user_123')).called(1);
      verify(mockSecureStorage.setRole('Customer')).called(1);
    });

    test('logout should clear auth data and secure storage', () async {
      // Arrange
      final loginResponse = {
        'token': 'test_token',
        'userId': 'user_123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'Customer',
      };
      when(
        mockApiService.login(any, any),
      ).thenAnswer((_) async => loginResponse);
      await authProvider.login('test@example.com', 'password');

      when(mockSecureStorage.clearAll()).thenAnswer((_) async => {});

      // Act
      await authProvider.logout();

      // Assert
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, isNull);
      verify(mockSecureStorage.clearAll()).called(1);
      verify(mockApiService.notifyLogout()).called(1);
    });

    test('tryAutoLogin should restore data from secure storage', () async {
      // Arrange
      when(
        mockSecureStorage.getToken(),
      ).thenAnswer((_) async => 'cached_token');
      when(
        mockSecureStorage.getRefreshToken(),
      ).thenAnswer((_) async => 'cached_refresh');
      when(mockSecureStorage.getUserId()).thenAnswer((_) async => 'user_123');
      when(
        mockSecureStorage.getEmail(),
      ).thenAnswer((_) async => 'test@example.com');
      when(
        mockSecureStorage.getFullName(),
      ).thenAnswer((_) async => 'Cached User');
      when(mockSecureStorage.getRole()).thenAnswer((_) async => 'Vendor');

      // Act
      await authProvider.tryAutoLogin();

      // Assert
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'cached_token');
      expect(authProvider.role, 'Vendor');
      verify(mockApiService.resetLogout()).called(1);
    });
  });
}

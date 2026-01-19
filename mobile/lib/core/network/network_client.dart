import 'dart:async';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/models/api_response.dart';
import 'package:mobile/services/api_request_scheduler.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _requestPermitKey = '_apiRequestPermit';

@lazySingleton
class NetworkClient {
  NetworkClient(this._connectivityService, this._requestScheduler)
    : baseUrl = AppConfig.apiBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _setupInterceptors();
  }

  /// API base URL (environment-aware).
  final String baseUrl;

  final ConnectivityService _connectivityService;
  final ApiRequestScheduler _requestScheduler;
  late final Dio _dio;

  // Auth State
  bool _isRefreshing = false;
  bool _isLoggingOut = false;
  Completer<Map<String, String>>? _refreshCompleter;
  bool _isRedirectingToLogin = false;

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Check connectivity
          if (!_connectivityService.isOnline) {
            final isOnline = await _connectivityService.checkConnectivity();
            if (!isOnline) {
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'No internet connection',
                  type: DioExceptionType.connectionError,
                ),
              );
            }
          }

          // Add Accept-Language header
          final prefs = await SharedPreferences.getInstance();
          final languageCode = prefs.getString('language') ?? 'tr';
          options.headers['Accept-Language'] = languageCode;

          // Acquire permit
          final permit = await _requestScheduler.acquire(
            highPriority: _isHighPriorityRequest(options),
          );
          options.extra[_requestPermitKey] = permit;

          // Add Token
          final token = await SecureStorageService.instance.getToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Logout race condition check
          if (_isLoggingOut &&
              !options.path.contains('login') &&
              !options.path.contains('register') &&
              !options.path.contains('resend-verification-code') &&
              !options.path.contains('verify-email') &&
              !options.path.contains('logs')) {
            return handler.reject(
              DioException(
                requestOptions: options,
                error: 'Logout in progress',
                type: DioExceptionType.cancel,
              ),
            );
          }

          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _releasePermit(response.requestOptions);
          // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
          return handler.next(response);
        },
        onError: (error, handler) async {
          _releasePermit(error.requestOptions);

          // Handle 401 Unauthorized - Refresh Token Logic
          // We check this BEFORE logging to avoid noisy logs on successful refresh
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('login') &&
              !error.requestOptions.path.contains('refresh-token') &&
              !_isLoggingOut) {
            try {
              final token = await SecureStorageService.instance.getToken();
              final refreshToken = await SecureStorageService.instance
                  .getRefreshToken();

              if (token != null && refreshToken != null) {
                late Map<String, String> newTokens;

                if (_isRefreshing && _refreshCompleter != null) {
                  newTokens = await _refreshCompleter!.future;
                } else {
                  _isRefreshing = true;
                  _refreshCompleter = Completer<Map<String, String>>();

                  try {
                    newTokens = await _performTokenRefresh(token, refreshToken);

                    await SecureStorageService.instance.setToken(
                      newTokens['token']!,
                    );
                    await SecureStorageService.instance.setRefreshToken(
                      newTokens['refreshToken']!,
                    );

                    _refreshCompleter!.complete(newTokens);
                    // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
                  } catch (e) {
                    _handleAuthFailure();
                    _refreshCompleter!.completeError(e);
                    rethrow;
                  } finally {
                    _isRefreshing = false;
                    _refreshCompleter = null;
                  }
                }

                // Retry original request
                final options = error.requestOptions;
                options.headers['Authorization'] =
                    'Bearer ${newTokens['token']!}';

                final retryResponse = await _dio.fetch(options);
                return handler.resolve(retryResponse);
              } else {
                _handleAuthFailure();
              }
            } catch (e) {
              // Refresh failed, fall through to log the error
            }
          }

          final errorMessage =
              '❌ [HTTP ERROR] ${error.requestOptions.method} ${error.requestOptions.uri} | Status: ${error.response?.statusCode}';
          LoggerService().error(errorMessage, error, error.stackTrace);

          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, String>> _performTokenRefresh(
    String token,
    String refreshToken,
  ) async {
    final permit = await _requestScheduler.acquire(highPriority: true);
    try {
      // Create separate Dio to avoid loops
      final tempDio = Dio(BaseOptions(baseUrl: baseUrl));
      final response = await tempDio.post(
        ApiEndpoints.refreshToken,
        data: {'token': token, 'refreshToken': refreshToken},
      );

      // Refresh endpoint is expected to return ApiResponse<Map<String,dynamic>>,
      // but in some cases (model binding / edge errors) it may return ProblemDetails.
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final looksLikeApiResponse = raw.containsKey('success');
        final looksLikeProblemDetails =
            raw.containsKey('title') && raw.containsKey('status');

        if (looksLikeProblemDetails) {
          final title = raw['title']?.toString();
          final detail = raw['detail']?.toString();
          throw Exception(
            detail?.isNotEmpty == true
                ? detail
                : (title ?? 'Token refresh failed'),
          );
        }

        if (looksLikeApiResponse) {
          final apiResponse = ApiResponse.fromJson(
            raw,
            (json) => json as Map<String, dynamic>,
          );

          if (!apiResponse.success || apiResponse.data == null) {
            throw Exception(apiResponse.message ?? 'Token refresh failed');
          }

          final data = apiResponse.data!;
          return {
            'token': data['token'] as String,
            'refreshToken': data['refreshToken'] as String,
          };
        }
      }

      throw Exception('Token refresh failed');
    } finally {
      permit.release();
    }
  }

  void _handleAuthFailure() {
    if (!_isRedirectingToLogin) {
      // Stop additional non-auth requests quickly
      _isLoggingOut = true;

      // Clear tokens and user data (best-effort; do not block UI navigation)
      unawaited(SecureStorageService.instance.clearAll());

      _isRedirectingToLogin = true;
      // Debug logları kaldırıldı - sadece warning ve error logları gösteriliyor
      NavigationService.navigateToRemoveUntil('/login', (route) => false);
      Future.delayed(const Duration(seconds: 2), () {
        _isRedirectingToLogin = false;
      });
    }
  }

  void _releasePermit(RequestOptions options) {
    final permit = options.extra[_requestPermitKey];
    if (permit is RequestPermit) {
      permit.release();
    }
  }

  bool _isHighPriorityRequest(RequestOptions options) {
    return options.path.contains('login') ||
        options.path.contains('register') ||
        options.path.contains('notifications/token') ||
        options.path.contains('orders') ||
        options.path.contains('refresh-token') ||
        options.path.contains('logs');
  }

  void notifyLogout() {
    _isLoggingOut = true;
  }

  void resetLogout() {
    _isLoggingOut = false;
  }

  // --- Public Generic Methods ---

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

      // Handle ApiResponse transformation if needed
      if (fromJson != null) {
        // Assuming your API returns standard ApiResponse wrapper
        // If the API returns direct data for some endpoints, this might need adjustment
        if (response.data is Map<String, dynamic>) {
          final apiResponse = ApiResponse.fromJson(
            response.data,
            (json) => fromJson(json),
          );
          if (!apiResponse.success) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: {
                'message': apiResponse.message,
                'errorCode': apiResponse.errorCode,
                'errors': apiResponse.errors,
              },
              type: DioExceptionType.badResponse,
            );
          }
          if (apiResponse.data == null) {
            throw DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: {
                'message': 'Response data is null',
                'errorCode': apiResponse.errorCode,
                'errors': apiResponse.errors,
              },
            );
          }
          return apiResponse.data!;
        }
      }

      return response.data as T;
    } catch (e) {
      rethrow;
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      if (fromJson != null && response.data is Map<String, dynamic>) {
        final apiResponse = ApiResponse.fromJson(
          response.data,
          (json) => fromJson(json),
        );
        if (!apiResponse.success) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: {
              'message': apiResponse.message,
              'errorCode': apiResponse.errorCode,
              'errors': apiResponse.errors,
            },
            type: DioExceptionType.badResponse,
          );
        }
        if (apiResponse.data == null) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: {
              'message': 'Response data is null',
              'errorCode': apiResponse.errorCode,
              'errors': apiResponse.errors,
            },
            type: DioExceptionType.badResponse,
          );
        }
        return apiResponse.data!;
      }

      return response.data as T;
    } catch (e) {
      rethrow;
    }
  }

  // Add put/patch/delete as needed similarly...
  // For now, exposed Dio handles edge cases.
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/app_localizations_en.dart';
import 'package:mobile/utils/error_handler.dart';

Response<dynamic> _response({
  required RequestOptions requestOptions,
  required int statusCode,
  required dynamic data,
  String? contentType,
}) {
  return Response<dynamic>(
    requestOptions: requestOptions,
    statusCode: statusCode,
    data: data,
    headers: Headers.fromMap(
      contentType != null
          ? {
              'content-type': [contentType],
            }
          : <String, List<String>>{},
    ),
  );
}

DioException _dioException({Response<dynamic>? response, Object? error}) {
  final ro = RequestOptions(path: '/test');
  return DioException(
    requestOptions: ro,
    response: response,
    error: error,
    type: DioExceptionType.badResponse,
  );
}

void main() {
  final loc = AppLocalizationsEn();

  group('ErrorHandler.parseApiError', () {
    test(
      'maps INVALID_TOKEN to localized sessionExpired (ApiResponse envelope)',
      () {
        final ro = RequestOptions(path: '/auth/refresh-token');
        final resp = _response(
          requestOptions: ro,
          statusCode: 400,
          data: {
            'success': false,
            'message': '',
            'data': null,
            'errorCode': 'INVALID_TOKEN',
            'errors': null,
          },
          contentType: 'application/json',
        );

        final ex = _dioException(response: resp);
        final msg = ErrorHandler.parseApiError(ex, loc);
        expect(msg, loc.sessionExpired);
      },
    );

    test(
      'parses ProblemDetails (application/problem+json) and returns a human message',
      () {
        final ro = RequestOptions(path: '/orders');
        final resp = _response(
          requestOptions: ro,
          statusCode: 400,
          data: {
            'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.1',
            'title': 'One or more validation errors occurred.',
            'status': 400,
            'errors': {
              'vendorType': ['The value \'abc\' is not valid.'],
            },
          },
          contentType: 'application/problem+json; charset=utf-8',
        );

        final ex = _dioException(response: resp);
        final msg = ErrorHandler.parseApiError(ex, loc);
        expect(msg, contains('not valid'));
      },
    );

    test(
      'maps INVALID_TOKEN to localized sessionExpired (structured DioException.error)',
      () {
        final ex = _dioException(
          error: {
            'message': null,
            'errorCode': 'INVALID_TOKEN',
            'errors': null,
          },
        );

        final msg = ErrorHandler.parseApiError(ex, loc);
        expect(msg, loc.sessionExpired);
      },
    );
  });

  group('ErrorHandler.parseRegisterError', () {
    test(
      'parses ProblemDetails during registration and returns validation message',
      () {
        final ro = RequestOptions(path: '/auth/register');
        final resp = _response(
          requestOptions: ro,
          statusCode: 400,
          data: {
            'title': 'One or more validation errors occurred.',
            'status': 400,
            'errors': {
              'email': ['Email is required'],
            },
          },
          contentType: 'application/problem+json',
        );

        final ex = _dioException(response: resp);
        final msg = ErrorHandler.parseRegisterError(ex, loc);
        expect(msg, contains('Email is required'));
      },
    );
  });
}

import 'package:dio/dio.dart';
import 'package:mobile/core/models/problem_details.dart';
import 'package:mobile/l10n/app_localizations.dart';

/// Utility class for handling and parsing API errors.
///
/// This class centralizes error handling logic, eliminating code duplication
/// across registration screens and other error-prone operations.
class ErrorHandler {
  static String? _mapErrorCodeToMessage(
    String? errorCode,
    AppLocalizations localizations,
  ) {
    if (errorCode == null) return null;

    // Normalize
    final code = errorCode.trim().toUpperCase();
    if (code.isEmpty) return null;

    switch (code) {
      case 'INVALID_TOKEN':
      case 'UNAUTHORIZED':
        return localizations.sessionExpired;
      case 'CODE_EXPIRED':
        return localizations.codeExpired;
      default:
        return null;
    }
  }

  /// Parses a registration error and returns a user-friendly message.
  ///
  /// Handles various error types:
  /// - DuplicateEmail/DuplicateUserName errors
  /// - Validation errors (including password errors)
  /// - Generic API errors
  /// - Network errors
  ///
  /// Returns a localized error message suitable for display to the user.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await register();
  /// } catch (e, stackTrace) {
  ///   final errorMessage = ErrorHandler.parseRegisterError(e, localizations);
  ///   ToastMessage.show(context, message: errorMessage, isSuccess: false);
  /// }
  /// ```
  static String parseRegisterError(
    dynamic error,
    AppLocalizations localizations,
  ) {
    // Default error message
    String errorMessage = error.toString().replaceAll('Exception: ', '');

    // Handle DioException (API errors)
    if (error is DioException && error.response?.data != null) {
      final responseData = error.response!.data;

      if (responseData is Map<String, dynamic>) {
        // ProblemDetails (RFC7807) support for model binding errors.
        final contentType = error.response?.headers.value('content-type') ?? '';
        final looksLikeProblemDetails =
            responseData.containsKey('title') &&
            responseData.containsKey('status');
        if (looksLikeProblemDetails ||
            contentType.contains('application/problem+json')) {
          try {
            final pd = ProblemDetails.fromJson(responseData);
            final msg = pd.toUserMessage();
            if (msg.trim().isNotEmpty) {
              return msg;
            }
          } catch (_) {
            // Fall through to existing parsing
          }
        }

        String? specificError;

        // Check for 'errors' object
        if (responseData.containsKey('errors')) {
          final errors = responseData['errors'];

          // Case A: Errors is a List (e.g. DuplicateEmail, DuplicateUserName)
          if (errors is List) {
            final duplicateError = errors.firstWhere(
              (error) =>
                  error is Map &&
                  (error['code'] == 'DuplicateEmail' ||
                      error['code'] == 'DuplicateUserName'),
              orElse: () => null,
            );

            if (duplicateError != null) {
              // Use duplicateEmail for customer, emailAlreadyExists for vendor/courier
              specificError = localizations.duplicateEmail;
            }
          }
          // Case B: Errors is a Map (Validation errors)
          else if (errors is Map) {
            // Check for 'Password' or 'password' key first
            final passwordErrors = errors['Password'] ?? errors['password'];

            if (passwordErrors != null) {
              if (passwordErrors is List) {
                specificError = passwordErrors.join('\n');
              } else {
                specificError = passwordErrors.toString();
              }
            }

            // If no password specific error, collect all validation errors
            if (specificError == null && errors.isNotEmpty) {
              final List<String> errorMessages = [];
              errors.forEach((key, value) {
                if (value is List) {
                  errorMessages.addAll(value.map((e) => e.toString()));
                } else {
                  errorMessages.add(value.toString());
                }
              });
              if (errorMessages.isNotEmpty) {
                specificError = errorMessages.join('\n');
              }
            }
          }
        }

        // Set errorMessage from parsed error or fallback to message field
        if (specificError != null) {
          errorMessage = specificError;
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }

        // If backend sends errorCode, prefer localized mapping
        final mapped = _mapErrorCodeToMessage(
          responseData['errorCode']?.toString(),
          localizations,
        );
        if (mapped != null && mapped.trim().isNotEmpty) {
          errorMessage = mapped;
        }
      }
    }

    // Return error message or fallback to registerFailed
    return errorMessage.isNotEmpty
        ? errorMessage
        : localizations.registerFailed;
  }

  /// Parses a simple registration error (for vendor/courier screens).
  ///
  /// This is a simplified version that handles:
  /// - DuplicateEmail/DuplicateUserName errors
  /// - Generic API errors
  ///
  /// For more complex validation error handling, use [parseRegisterError].
  static String parseSimpleRegisterError(
    dynamic error,
    AppLocalizations localizations,
  ) {
    String errorMessage = error.toString().replaceAll('Exception: ', '');

    if (error is DioException && error.response?.data != null) {
      final responseData = error.response!.data;

      if (responseData is Map<String, dynamic>) {
        // ProblemDetails (RFC7807) support for model binding errors.
        final contentType = error.response?.headers.value('content-type') ?? '';
        final looksLikeProblemDetails =
            responseData.containsKey('title') &&
            responseData.containsKey('status');
        if (looksLikeProblemDetails ||
            contentType.contains('application/problem+json')) {
          try {
            final pd = ProblemDetails.fromJson(responseData);
            final msg = pd.toUserMessage();
            if (msg.trim().isNotEmpty) {
              return msg;
            }
          } catch (_) {
            // Fall through to existing parsing
          }
        }

        if (responseData.containsKey('errors') &&
            responseData['errors'] is List) {
          final errors = responseData['errors'] as List;
          final duplicateError = errors.firstWhere(
            (error) =>
                error is Map &&
                (error['code'] == 'DuplicateEmail' ||
                    error['code'] == 'DuplicateUserName'),
            orElse: () => null,
          );

          if (duplicateError != null) {
            errorMessage = localizations.emailAlreadyExists;
          } else if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          }
        } else if (responseData.containsKey('message')) {
          errorMessage = responseData['message'].toString();
        }

        final mapped = _mapErrorCodeToMessage(
          responseData['errorCode']?.toString(),
          localizations,
        );
        if (mapped != null && mapped.trim().isNotEmpty) {
          errorMessage = mapped;
        }
      }
    }

    return errorMessage.isNotEmpty
        ? errorMessage
        : localizations.registerFailed;
  }

  /// Parses a generic API error and returns a user-friendly message.
  ///
  /// Can be used for any API operation, not just registration.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await apiService.someOperation();
  /// } catch (e) {
  ///   final errorMessage = ErrorHandler.parseApiError(e, localizations);
  ///   showError(errorMessage);
  /// }
  /// ```
  static String parseApiError(
    dynamic error,
    AppLocalizations localizations, {
    String? fallbackMessage,
  }) {
    String errorMessage = error.toString().replaceAll('Exception: ', '');

    if (error is DioException) {
      // Handle network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return localizations.error;
      }

      // Handle API response errors
      if (error.response?.data != null) {
        final responseData = error.response!.data;

        if (responseData is Map<String, dynamic>) {
          // If backend sends errorCode, prefer localized mapping immediately
          final codeFromResponse = responseData['errorCode']?.toString();
          final mappedFromResponse = _mapErrorCodeToMessage(
            codeFromResponse,
            localizations,
          );
          if (mappedFromResponse != null &&
              mappedFromResponse.trim().isNotEmpty) {
            return mappedFromResponse;
          }

          // ProblemDetails (RFC7807): typically from [ApiController] model binding.
          // We also check content-type when available, but shape-based detection is enough.
          final contentType =
              error.response?.headers.value('content-type') ?? '';
          final looksLikeProblemDetails =
              responseData.containsKey('title') &&
              responseData.containsKey('status');

          if (looksLikeProblemDetails ||
              contentType.contains('application/problem+json')) {
            try {
              final pd = ProblemDetails.fromJson(responseData);
              final msg = pd.toUserMessage();
              if (msg.trim().isNotEmpty) {
                return msg;
              }
            } catch (_) {
              // Fall through to other strategies
            }
          }

          // ApiResponse envelope
          if (responseData.containsKey('message') &&
              (responseData['message']?.toString().trim().isNotEmpty ??
                  false)) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];

            // Common API shape: errors is List<string>
            if (errors is List && errors.isNotEmpty) {
              final joined = errors.map((e) => e.toString()).join('\n');
              if (joined.trim().isNotEmpty) {
                errorMessage = joined;
              }
            }
            // Legacy/other shape: errors is List<Map{message:..}>
            else if (errors is List && errors.isNotEmpty) {
              final firstError = errors.first;
              if (firstError is Map && firstError.containsKey('message')) {
                errorMessage = firstError['message'].toString();
              }
            }
            // Validation shape: errors is Map{ field: [msg] }
            else if (errors is Map) {
              final messages = <String>[];
              errors.forEach((_, value) {
                if (value is List) {
                  messages.addAll(value.map((e) => e.toString()));
                } else if (value != null) {
                  messages.add(value.toString());
                }
              });
              final joined = messages
                  .where((m) => m.trim().isNotEmpty)
                  .join('\n');
              if (joined.isNotEmpty) {
                errorMessage = joined;
              }
            }
          }

          // Use errorCode as fallback if message is empty
          if (errorMessage.trim().isEmpty &&
              responseData.containsKey('errorCode')) {
            final code = responseData['errorCode']?.toString();
            final mapped = _mapErrorCodeToMessage(code, localizations);
            if (mapped != null && mapped.trim().isNotEmpty) {
              return mapped;
            }
            if (code != null && code.trim().isNotEmpty) {
              errorMessage = code;
            }
          }
        }
      }

      // Fallback: sometimes we throw DioException with a structured `error` payload
      // even when response parsing isn't available (or callers don't pass response through).
      final err = error.error;
      if (err is Map) {
        final msg = err['message']?.toString();
        if (msg != null && msg.trim().isNotEmpty) {
          return msg;
        }
        final code = err['errorCode']?.toString();
        final mapped = _mapErrorCodeToMessage(code, localizations);
        if (mapped != null && mapped.trim().isNotEmpty) {
          return mapped;
        }
        if (code != null && code.trim().isNotEmpty) {
          return code;
        }
        final errs = err['errors'];
        if (errs is List && errs.isNotEmpty) {
          final joined = errs.map((e) => e.toString()).join('\n');
          if (joined.trim().isNotEmpty) {
            return joined;
          }
        }
      }
    }

    if (errorMessage.isNotEmpty) {
      return errorMessage;
    }

    if (fallbackMessage != null) {
      return fallbackMessage;
    }

    return localizations.error;
  }
}

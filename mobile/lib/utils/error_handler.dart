import 'package:dio/dio.dart';
import 'package:mobile/l10n/app_localizations.dart';

/// Utility class for handling and parsing API errors.
///
/// This class centralizes error handling logic, eliminating code duplication
/// across registration screens and other error-prone operations.
class ErrorHandler {
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
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'].toString();
          } else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is List && errors.isNotEmpty) {
              final firstError = errors.first;
              if (firstError is Map && firstError.containsKey('message')) {
                errorMessage = firstError['message'].toString();
              }
            }
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

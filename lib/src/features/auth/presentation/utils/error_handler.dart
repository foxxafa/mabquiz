import 'package:flutter/material.dart';
import '../../data/auth_error_mapper.dart';
import '../../data/exceptions.dart';
import 'error_messages.dart';
import '../widgets/error_dialog.dart';

/// Comprehensive error handling utility for authentication
class AuthErrorHandler {
  static String getErrorMessage(Object error) {
    final authException = AuthErrorMapper.mapException(error);
    return AuthErrorMessages.getAuthExceptionMessage(authException);
  }

  /// Handles an authentication error and shows appropriate UI feedback
  static Future<void> handleError(
    BuildContext context,
    Object error, {
    bool showDialog = true,
    bool showSnackBar = false,
    String? customTitle,
    VoidCallback? onRetry,
  }) async {
    // Map the error to an AuthException
    final authException = AuthErrorMapper.mapException(error);
    final localizedMessage = AuthErrorMessages.getAuthExceptionMessage(authException);

    if (showDialog) {
      await _showErrorDialog(
        context,
        title: customTitle ?? _getErrorTitle(authException),
        message: localizedMessage,
        onRetry: onRetry,
      );
    }

    if (showSnackBar && context.mounted) {
      _showErrorSnackBar(context, localizedMessage);
    }

    // Log error for debugging (in debug mode)
    _logError(error, authException);
  }

  /// Handles form validation errors
  static void handleValidationError(
    BuildContext context,
    String message, {
    bool showDialog = false,
    bool showSnackBar = true,
  }) {
    if (showDialog) {
      AuthErrorDialog.showValidationError(context, message);
    }

    if (showSnackBar) {
      AuthSnackBar.showError(context, message);
    }
  }

  /// Handles network errors specifically
  static Future<void> handleNetworkError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await _showErrorDialog(
      context,
      title: 'Bağlantı Sorunu',
      message: AuthErrorMessages.getMessage('network-error'),
      onRetry: onRetry,
      showRetryButton: true,
    );
  }

  /// Handles service unavailable errors
  static Future<void> handleServiceError(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    await _showErrorDialog(
      context,
      title: 'Servis Sorunu',
      message: AuthErrorMessages.getMessage('service-unavailable'),
      onRetry: onRetry,
      showRetryButton: true,
    );
  }

  /// Shows a success message
  static void showSuccess(
    BuildContext context,
    String action, {
    bool showDialog = false,
    bool showSnackBar = true,
  }) {
    final message = AuthErrorMessages.getSuccessMessage(action);

    if (showDialog) {
      _showSuccessDialog(context, message);
    }

    if (showSnackBar) {
      AuthSnackBar.showSuccess(context, message);
    }
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmation(
    BuildContext context,
    String action, {
    String? customTitle,
    String? customMessage,
  }) async {
    final title = customTitle ?? 'Onay';
    final message = customMessage ?? AuthErrorMessages.getConfirmationMessage(action);

    return await AuthErrorDialog.showConfirmation(
      context,
      title: title,
      message: message,
    );
  }

  /// Handles multiple validation errors
  static void handleValidationErrors(
    BuildContext context,
    Map<String, String?> errors, {
    bool showFirstErrorOnly = true,
  }) {
    final errorMessages = errors.values.where((error) => error != null).cast<String>();

    if (errorMessages.isEmpty) return;

    if (showFirstErrorOnly) {
      handleValidationError(context, errorMessages.first);
    } else {
      final combinedMessage = errorMessages.join('\n• ');
      handleValidationError(context, '• $combinedMessage');
    }
  }

  /// Gets appropriate error title based on exception type
  static String _getErrorTitle(AuthException exception) {
    switch (exception.code) {
      case 'network-error':
        return 'Bağlantı Sorunu';
      case 'service-unavailable':
        return 'Servis Sorunu';
      case 'invalid-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Giriş Hatası';
      case 'email-already-in-use':
        return 'Kayıt Hatası';
      case 'weak-password':
        return 'Şifre Hatası';
      case 'too-many-requests':
        return 'Çok Fazla Deneme';
      default:
        return 'Hata';
    }
  }

  /// Shows an error dialog with optional retry button
  static Future<void> _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    bool showRetryButton = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            if (showRetryButton && onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(AuthErrorMessages.getMessage('try-again')),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AuthErrorMessages.getMessage('ok')),
            ),
          ],
        );
      },
    );
  }

  /// Shows a success dialog
  static Future<void> _showSuccessDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Başarılı'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AuthErrorMessages.getMessage('ok')),
            ),
          ],
        );
      },
    );
  }

  /// Shows an error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    AuthSnackBar.showError(context, message);
  }

  /// Logs error for debugging
  static void _logError(Object originalError, AuthException mappedException) {
    // Only log in debug mode
    assert(() {
      debugPrint('🔴 Auth Error:');
      debugPrint('  Original: $originalError');
      debugPrint('  Mapped: ${mappedException.code} - ${mappedException.message}');
      debugPrint('  Localized: ${mappedException.localizedMessage}');
      return true;
    }());
  }
}

/// Extension methods for easier error handling
extension BuildContextErrorHandler on BuildContext {
  /// Handles an authentication error
  Future<void> handleAuthError(
    Object error, {
    bool showDialog = true,
    bool showSnackBar = false,
    String? customTitle,
    VoidCallback? onRetry,
  }) {
    return AuthErrorHandler.handleError(
      this,
      error,
      showDialog: showDialog,
      showSnackBar: showSnackBar,
      customTitle: customTitle,
      onRetry: onRetry,
    );
  }

  /// Handles validation errors
  void handleValidationError(
    String message, {
    bool showDialog = false,
    bool showSnackBar = true,
  }) {
    AuthErrorHandler.handleValidationError(
      this,
      message,
      showDialog: showDialog,
      showSnackBar: showSnackBar,
    );
  }

  /// Handles multiple validation errors
  void handleValidationErrors(
    Map<String, String?> errors, {
    bool showFirstErrorOnly = true,
  }) {
    AuthErrorHandler.handleValidationErrors(
      this,
      errors,
      showFirstErrorOnly: showFirstErrorOnly,
    );
  }

  /// Shows success message
  void showAuthSuccess(
    String action, {
    bool showDialog = false,
    bool showSnackBar = true,
  }) {
    AuthErrorHandler.showSuccess(
      this,
      action,
      showDialog: showDialog,
      showSnackBar: showSnackBar,
    );
  }

  /// Shows confirmation dialog
  Future<bool> showAuthConfirmation(
    String action, {
    String? customTitle,
    String? customMessage,
  }) {
    return AuthErrorHandler.showConfirmation(
      this,
      action,
      customTitle: customTitle,
      customMessage: customMessage,
    );
  }

  /// Handles network error
  Future<void> handleNetworkError({VoidCallback? onRetry}) {
    return AuthErrorHandler.handleNetworkError(this, onRetry: onRetry);
  }

  /// Handles service error
  Future<void> handleServiceError({VoidCallback? onRetry}) {
    return AuthErrorHandler.handleServiceError(this, onRetry: onRetry);
  }
}
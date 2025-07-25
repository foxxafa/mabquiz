import 'package:flutter/material.dart';
import '../../data/auth_error_mapper.dart';
import '../utils/error_messages.dart';

/// Utility class for displaying authentication-related error dialogs
class AuthErrorDialog {
  /// Shows a generic error dialog with a custom message
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'Tamam',
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
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }

  /// Shows an authentication error dialog with localized message
  static Future<void> showAuthError(
    BuildContext context,
    Object error,
  ) async {
    final authException = AuthErrorMapper.mapException(error);
    final errorMessage = AuthErrorMessages.getAuthExceptionMessage(authException);

    return show(
      context,
      title: 'Kimlik Doğrulama Hatası',
      message: errorMessage,
    );
  }

  /// Shows a network error dialog
  static Future<void> showNetworkError(BuildContext context) async {
    return show(
      context,
      title: 'Bağlantı Hatası',
      message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
    );
  }

  /// Shows a validation error dialog
  static Future<void> showValidationError(
    BuildContext context,
    String message,
  ) async {
    return show(
      context,
      title: 'Geçersiz Bilgi',
      message: message,
    );
  }

  /// Shows a confirmation dialog and returns the user's choice
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }


}

/// Extension methods for easier error dialog usage
extension BuildContextErrorDialog on BuildContext {
  /// Shows an authentication error dialog
  Future<void> showAuthError(Object error) {
    return AuthErrorDialog.showAuthError(this, error);
  }

  /// Shows a generic error dialog
  Future<void> showError({
    required String title,
    required String message,
    String buttonText = 'Tamam',
  }) {
    return AuthErrorDialog.show(
      this,
      title: title,
      message: message,
      buttonText: buttonText,
    );
  }

  /// Shows a network error dialog
  Future<void> showNetworkError() {
    return AuthErrorDialog.showNetworkError(this);
  }

  /// Shows a validation error dialog
  Future<void> showValidationError(String message) {
    return AuthErrorDialog.showValidationError(this, message);
  }

  /// Shows a confirmation dialog
  Future<bool> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'Evet',
    String cancelText = 'Hayır',
  }) {
    return AuthErrorDialog.showConfirmation(
      this,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
    );
  }
}

/// Snackbar utilities for quick error messages
class AuthSnackBar {
  /// Shows an error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Kapat',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows an info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Extension for easier snackbar usage
extension BuildContextSnackBar on BuildContext {
  /// Shows an error snackbar
  void showErrorSnackBar(String message) {
    AuthSnackBar.showError(this, message);
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message) {
    AuthSnackBar.showSuccess(this, message);
  }

  /// Shows an info snackbar
  void showInfoSnackBar(String message) {
    AuthSnackBar.showInfo(this, message);
  }
}
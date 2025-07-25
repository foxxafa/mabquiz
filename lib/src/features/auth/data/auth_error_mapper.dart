import 'package:firebase_auth/firebase_auth.dart';
import 'exceptions.dart';

/// Maps Firebase Auth exceptions to domain-specific auth exceptions
class AuthErrorMapper {
  /// Maps a FirebaseAuthException to an appropriate AuthException
  static AuthException mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return const InvalidCredentialsException();

      case 'weak-password':
        return const WeakPasswordException();

      case 'email-already-in-use':
        return const EmailAlreadyInUseException();

      case 'user-disabled':
        return const UnknownAuthException('User account has been disabled', 'user-disabled');

      case 'too-many-requests':
        return const UnknownAuthException('Too many requests. Please try again later', 'too-many-requests');

      case 'operation-not-allowed':
        return const UnknownAuthException('This operation is not allowed', 'operation-not-allowed');

      case 'invalid-email':
        return const UnknownAuthException('Invalid email address format', 'invalid-email');

      case 'network-request-failed':
        return const NetworkException();

      case 'internal-error':
        return const ServiceUnavailableException();

      default:
        return UnknownAuthException(
          e.message ?? 'An unknown authentication error occurred',
          e.code,
        );
    }
  }

  /// Maps any exception to an AuthException
  static AuthException mapException(Object exception) {
    if (exception is AuthException) {
      return exception;
    }

    if (exception is FirebaseAuthException) {
      return mapFirebaseException(exception);
    }

    // Handle network-related exceptions
    if (exception.toString().toLowerCase().contains('network') ||
        exception.toString().toLowerCase().contains('connection')) {
      return const NetworkException();
    }

    // Handle timeout exceptions
    if (exception.toString().toLowerCase().contains('timeout')) {
      return const UnknownAuthException('Request timed out. Please try again', 'timeout');
    }

    // Generic unknown exception
    return UnknownAuthException(
      exception.toString(),
      'unknown-error',
    );
  }

  /// Gets a localized Turkish error message for an AuthException
  static String getLocalizedMessage(AuthException exception) {
    switch (exception.code) {
      case 'invalid-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'Geçersiz email veya şifre. Lütfen bilgilerinizi kontrol edin.';

      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın ve güçlü bir şifre seçin.';

      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda. Farklı bir email deneyin veya giriş yapmayı deneyin.';

      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış. Destek ekibi ile iletişime geçin.';

      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen birkaç dakika bekleyip tekrar deneyin.';

      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

      case 'invalid-email':
        return 'Geçersiz email adresi formatı. Lütfen geçerli bir email adresi girin.';

      case 'network-error':
        return 'İnternet bağlantısı sorunu. Bağlantınızı kontrol edip tekrar deneyin.';

      case 'service-unavailable':
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

      case 'timeout':
        return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';

      default:
        return 'Bir hata oluştu: ${exception.message}';
    }
  }

  /// Gets a localized Turkish error message for any exception
  static String getLocalizedMessageFromException(Object exception) {
    if (exception is AuthException) {
      return getLocalizedMessage(exception);
    }

    final mappedException = mapException(exception);
    return getLocalizedMessage(mappedException);
  }
}
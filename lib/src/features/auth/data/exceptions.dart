/// Core authentication exceptions for the auth feature
abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);

  @override
  String toString() => 'AuthException: $message (code: $code)';
}

/// Exception thrown when user credentials are invalid
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Invalid email or password', 'invalid-credentials');
}

/// Exception thrown when password is too weak
class WeakPasswordException extends AuthException {
  const WeakPasswordException()
      : super('Password is too weak', 'weak-password');
}

/// Exception thrown when email is already in use
class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
      : super('Email is already in use', 'email-already-in-use');
}

/// Exception thrown when user is not found
class UserNotFoundException extends AuthException {
  const UserNotFoundException()
      : super('User not found', 'user-not-found');
}

/// Exception thrown when network error occurs
class NetworkException extends AuthException {
  const NetworkException()
      : super('Network error occurred', 'network-error');
}

/// Exception thrown when service is unavailable
class ServiceUnavailableException extends AuthException {
  const ServiceUnavailableException()
      : super('Service is currently unavailable', 'service-unavailable');
}

/// Exception thrown for unknown authentication errors
class UnknownAuthException extends AuthException {
  const UnknownAuthException(super.message, super.code);
}

/// Exception thrown when Google Sign-In is cancelled by user
class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException()
      : super('Google sign-in cancelled by user', 'google-signin-cancelled');
}

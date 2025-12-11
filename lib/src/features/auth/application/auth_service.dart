import '../data/auth_repository.dart';
import '../data/models/app_user.dart';
import '../data/exceptions.dart';
import '../presentation/utils/form_validators.dart';

/// Facade service for authentication operations
///
/// This service provides a simplified interface for authentication operations
/// and handles business logic while delegating actual authentication to the repository.
/// It follows the Facade pattern to hide complexity from the UI layer.
class AuthService {
  final AuthRepository _repository;

  const AuthService(this._repository);

  /// Stream that emits authentication state changes
  ///
  /// Returns:
  /// - AppUser when user is authenticated
  /// - null when user is not authenticated
  Stream<AppUser?> get authStateChanges => _repository.authStateChanges;

  /// Logs in a user with email and password
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Throws:
  /// - [InvalidCredentialsException] when credentials are invalid
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  /// - [AuthException] for other authentication errors
  Future<void> login(String usernameOrEmail, String password) async {
    try {
      // Validate input parameters
      if (usernameOrEmail.isEmpty) {
        throw const InvalidCredentialsException();
      }
      _validatePassword(password);

      // Delegate to repository
      await _repository.signInWithEmailAndPassword(usernameOrEmail, password);
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } catch (e) {
      // Wrap unknown exceptions
      throw UnknownAuthException(
        'Login failed: ${e.toString()}',
        'login-failed',
      );
    }
  }

  /// Registers a new user with email and password
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  ///
  /// Throws:
  /// - [EmailAlreadyInUseException] when email is already in use
  /// - [WeakPasswordException] when password is too weak
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  /// - [AuthException] for other authentication errors
  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String department,
  }) async {
    try {
      // Validate input parameters
      _validateEmail(email);
      _validatePassword(password);

      // Delegate to repository
      await _repository.createUserWithEmailAndPassword(
        email: email,
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        department: department,
      );
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } catch (e) {
      // Wrap unknown exceptions
      throw UnknownAuthException(
        'Registration failed: ${e.toString()}',
        'registration-failed',
      );
    }
  }

  /// Logs out the current user
  ///
  /// Throws:
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  /// - [AuthException] for other authentication errors
  Future<void> logout() async {
    try {
      await _repository.signOut();
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } catch (e) {
      // Wrap unknown exceptions
      throw UnknownAuthException(
        'Logout failed: ${e.toString()}',
        'logout-failed',
      );
    }
  }

  /// Logs in a user with Google
  ///
  /// Throws:
  /// - [GoogleSignInCancelledException] when user cancels
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  /// - [AuthException] for other authentication errors
  Future<void> loginWithGoogle() async {
    try {
      await _repository.signInWithGoogle();
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } catch (e) {
      // Wrap unknown exceptions
      throw UnknownAuthException(
        'Google login failed: ${e.toString()}',
        'google-login-failed',
      );
    }
  }

  /// Validates email format
  void _validateEmail(String email) {
    final emailError = AuthFormValidators.validateEmail(email);
    if (emailError != null) {
      throw const InvalidCredentialsException();
    }
  }

  /// Validates password requirements
  void _validatePassword(String password) {
    final passwordError = AuthFormValidators.validatePassword(password);
    if (passwordError != null) {
      if (password.isEmpty) {
        throw const InvalidCredentialsException();
      } else {
        throw const WeakPasswordException();
      }
    }
  }
}

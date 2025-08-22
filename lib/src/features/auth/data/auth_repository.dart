import 'models/app_user.dart';

/// Abstract repository interface for authentication operations
///
/// This interface defines the contract for authentication operations
/// and provides abstraction between the UI layer and concrete implementations
/// (Firebase, Mock, etc.)
abstract class AuthRepository {
  /// Stream that emits authentication state changes
  ///
  /// Emits:
  /// - AppUser when user is authenticated
  /// - null when user is not authenticated
  Stream<AppUser?> get authStateChanges;

  /// Signs in a user with email and password
  ///
  /// Throws:
  /// - [InvalidCredentialsException] when credentials are invalid
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  Future<void> signInWithEmailAndPassword(String email, String password);

  /// Creates a new user account with email and password
  ///
  /// Throws:
  /// - [EmailAlreadyInUseException] when email is already in use
  /// - [WeakPasswordException] when password is too weak
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String department,
  });

  /// Signs out the current user
  ///
  /// Throws:
  /// - [NetworkException] when network error occurs
  /// - [ServiceUnavailableException] when service is unavailable
  Future<void> signOut();
}

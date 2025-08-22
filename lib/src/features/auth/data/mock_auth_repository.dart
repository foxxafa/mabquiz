import 'dart:async';

import 'auth_repository.dart';
import 'exceptions.dart';
import 'models/app_user.dart';
import 'models/mock_user.dart';

/// Mock implementation of AuthRepository for testing and development
///
/// This class provides a fake authentication system that simulates
/// real authentication behavior with realistic delays and test users.
/// It's useful for development when Firebase is not available or for testing.
class MockAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  /// Configurable delay for simulating network operations
  final Duration simulatedDelay;

  /// Test users available for mock authentication
  static const Map<String, String> _testUsers = {
    'test@example.com': 'password',
    'admin@example.com': 'admin1234',
    'user@example.com': 'user1234',
  };

  MockAuthRepository({
    this.simulatedDelay = const Duration(milliseconds: 800),
  }) {
    // Initialize with no user signed in
    Future(() => _authStateController.add(null));
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    // Use custom behavior if set
    if (_customLoginBehavior != null) {
      await _customLoginBehavior!(email, password);
      _currentUser = MockUser(email: email);
      _authStateController.add(_currentUser);
      return;
    }

    // Simulate realistic network delay
    await Future.delayed(simulatedDelay);

    // Validate credentials against test users
    if (_testUsers.containsKey(email) && _testUsers[email] == password) {
      _currentUser = MockUser(email: email);
      _authStateController.add(_currentUser);
    } else {
      throw const InvalidCredentialsException();
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String department,
  }) async {
    // Use custom behavior if set
    if (_customRegistrationBehavior != null) {
      await _customRegistrationBehavior!(email, password);
      _currentUser = MockUser(email: email);
      _authStateController.add(_currentUser);
      return;
    }

    // Simulate realistic network delay with slightly longer delay for registration
    await Future.delayed(Duration(milliseconds: (simulatedDelay.inMilliseconds * 1.2).round()));

    // Validate email format
    if (!_isValidEmail(email)) {
      throw const InvalidCredentialsException();
    }

    // Validate password strength
    if (password.length < 6) {
      throw const WeakPasswordException();
    }

    // Check if email is already in use
    if (_testUsers.containsKey(email)) {
      throw const EmailAlreadyInUseException();
    }

    // Create new user and sign them in
    _currentUser = MockUser(email: email, displayName: '$firstName $lastName');
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    // Use custom behavior if set
    if (_customLogoutBehavior != null) {
      await _customLogoutBehavior!();
      _currentUser = null;
      _authStateController.add(null);
      return;
    }

    // Simulate realistic network delay (shorter for sign out)
    await Future.delayed(Duration(milliseconds: (simulatedDelay.inMilliseconds * 0.6).round()));

    _currentUser = null;
    _authStateController.add(null);
  }

  /// Validates email format using a simple regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Disposes the stream controller to prevent memory leaks
  void dispose() {
    _authStateController.close();
  }

  /// Utility method to get current user for testing
  AppUser? get currentUser => _currentUser;

  /// Utility method to simulate network errors for testing
  Future<void> simulateNetworkError() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const NetworkException();
  }

  /// Utility method to simulate service unavailable for testing
  Future<void> simulateServiceUnavailable() async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw const ServiceUnavailableException();
  }

  /// Test helper methods for integration tests

  /// Sets the current user for testing
  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  /// Sets a custom auth state stream for testing
  void setAuthStateStream(Stream<AppUser?> stream) {
    // Close existing controller and create new one with the provided stream
    _authStateController.close();
    stream.listen((user) {
      _currentUser = user;
    });
  }

  /// Sets custom login behavior for testing
  void setLoginBehavior(Future<void> Function(String email, String password) behavior) {
    _customLoginBehavior = behavior;
  }

  /// Sets custom registration behavior for testing
  void setRegistrationBehavior(Future<void> Function(String email, String password) behavior) {
    _customRegistrationBehavior = behavior;
  }

  /// Sets custom logout behavior for testing
  void setLogoutBehavior(Future<void> Function() behavior) {
    _customLogoutBehavior = behavior;
  }

  Future<void> Function(String email, String password)? _customLoginBehavior;
  Future<void> Function(String email, String password)? _customRegistrationBehavior;
  Future<void> Function()? _customLogoutBehavior;
}

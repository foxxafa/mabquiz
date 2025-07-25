import 'app_user.dart';

/// Mock user implementation for testing and development
class MockUser extends AppUser {
  MockUser({
    required String email,
    String? displayName,
  }) : super(
          uid: 'mock_${email.hashCode}',
          email: email,
          displayName: displayName ?? email.split('@')[0],
          emailVerified: true,
        );

  /// Creates a mock user with predefined test data
  factory MockUser.testUser() {
    return MockUser(
      email: 'test@example.com',
      displayName: 'Test User',
    );
  }

  /// Creates a mock user with admin privileges
  factory MockUser.adminUser() {
    return MockUser(
      email: 'admin@example.com',
      displayName: 'Admin User',
    );
  }
}
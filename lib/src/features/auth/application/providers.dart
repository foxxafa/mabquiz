import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/config_providers.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../data/railway_auth_repository.dart';
import '../data/models/app_user.dart';
import 'auth_service.dart';

/// Provider for the auth repository implementation
///
/// Uses Railway backend for production and mock for development
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authConfig = ref.watch(authConfigProvider);
  
  // Production'da Railway, development'ta Mock kullan
  if (authConfig.useProduction) {
    return RailwayAuthRepository();
  } else {
    return MockAuthRepository(
      simulatedDelay: Duration(milliseconds: authConfig.mockAuthDelay),
    );
  }
});

/// Provider for the auth service facade
///
/// Creates an AuthService instance with the appropriate repository
/// based on the current environment
final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthService(repository);
});

/// Stream provider for authentication state changes
///
/// Provides a stream that emits:
/// - AppUser when user is authenticated
/// - null when user is not authenticated
///
/// This provider automatically disposes when not in use but keeps alive
/// to maintain authentication state across the app
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Provider for current authenticated user
///
/// Returns the current user if authenticated, null otherwise
/// This is a convenience provider that extracts the user from authStateProvider
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for authentication loading state
///
/// Can be used by UI components to show loading indicators
/// during authentication operations
final authLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for authentication error state
///
/// Can be used by UI components to display authentication errors
final authErrorProvider = StateProvider<String?>((ref) => null);

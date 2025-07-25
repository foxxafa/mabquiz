# Design Document

## Overview

Bu belge, Flutter uygulaması için kimlik doğrulama (auth) özelliğinin teknik tasarımını tanımlar. Tasarım, Feature-First Clean Architecture prensiplerini takip eder ve flutter_riverpod state management ile Firebase Auth entegrasyonu sağlar. Ayrıca geliştirme sürecinde kullanılmak üzere mock implementasyon da içerir.

Tasarım, Repository Pattern ve Facade Pattern kullanarak UI katmanını Firebase implementasyon detaylarından soyutlar. Bu yaklaşım, kodun test edilebilirliğini artırır ve gelecekteki değişikliklere karşı esneklik sağlar.

## Architecture

### Feature-First Architecture

Auth özelliği `lib/src/features/auth/` dizini altında organize edilir:

```
lib/src/features/auth/
├── application/          # Servis katmanı (Facade)
│   ├── auth_service.dart
│   └── providers.dart
├── data/                 # Repository implementasyonları
│   ├── auth_repository.dart
│   ├── firebase_auth_repository.dart
│   └── mock_auth_repository.dart
├── presentation/         # UI katmanı
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   └── auth_gate.dart
│   └── widgets/
│       ├── auth_form.dart
│       └── loading_overlay.dart
```

### Clean Architecture Layers

1. **Presentation Layer**: UI bileşenleri ve state management
2. **Application Layer**: Business logic ve use cases (Facade pattern)
3. **Data Layer**: Repository pattern ile veri erişimi

### Dependency Flow

```
Presentation → Application → Data
```

- Presentation katmanı sadece Application katmanını bilir
- Application katmanı Data katmanındaki abstract repository'leri kullanır
- Data katmanı Firebase Auth SDK ile iletişim kurar

## Components and Interfaces

### Core Interfaces

#### AuthRepository (Abstract)

```dart
abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}
```

#### AuthService (Facade)

```dart
class AuthService {
  final AuthRepository _repository;

  Stream<User?> get authStateChanges => _repository.authStateChanges;

  Future<void> login(String email, String password);
  Future<void> register(String email, String password);
  Future<void> logout();
}
```

### Implementation Classes

#### FirebaseAuthRepository

Firebase Auth SDK'sını kullanarak gerçek kimlik doğrulama işlemlerini gerçekleştirir:

```dart
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Diğer metodlar...
}
```

#### MockAuthRepository

Geliştirme ve test amaçlı sahte implementasyon:

```dart
class MockAuthRepository implements AuthRepository {
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();
  User? _currentUser;

  @override
  Stream<User?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(Duration(seconds: 1)); // Gerçekçi gecikme

    if (email == "test@example.com" && password == "password") {
      _currentUser = MockUser(email: email);
      _authStateController.add(_currentUser);
    } else {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
  }

  // Diğer metodlar...
}
```

### Riverpod Providers

```dart
// Repository provider - varsayılan olarak Mock kullanır
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Geliştirme için Mock, production için Firebase
  return MockAuthRepository(); // veya FirebaseAuthRepository()
});

// Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthService(repository);
});

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});
```

### UI Components

#### AuthGate

Uygulamanın giriş kapısı, kullanıcının kimlik doğrulama durumuna göre yönlendirme yapar:

```dart
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user != null ? HomeScreen() : LoginScreen(),
      loading: () => LoadingScreen(),
      error: (error, stack) => ErrorScreen(error: error),
    );
  }
}
```

#### LoginScreen & RegisterScreen

Form validasyonu ve hata yönetimi ile kullanıcı giriş/kayıt ekranları:

```dart
class LoginScreen extends ConsumerStatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // UI build metodu...
}
```

## Data Models

### User Model

Firebase User nesnesini soyutlayan domain model:

```dart
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
  });

  factory AppUser.fromFirebaseUser(User firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      emailVerified: firebaseUser.emailVerified,
    );
  }
}
```

### Mock User Model

Test ve geliştirme için sahte kullanıcı modeli:

```dart
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
}
```

## Error Handling

### Exception Types

```dart
abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException(this.message, this.code);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password', 'invalid-credentials');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException() : super('Password is too weak', 'weak-password');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException() : super('Email is already in use', 'email-already-in-use');
}
```

### Error Mapping

Firebase Auth hatalarını domain-specific hatalara dönüştürme:

```dart
class AuthErrorMapper {
  static AuthException mapFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return InvalidCredentialsException();
      case 'weak-password':
        return WeakPasswordException();
      case 'email-already-in-use':
        return EmailAlreadyInUseException();
      default:
        return AuthException(e.message ?? 'Unknown error', e.code);
    }
  }
}
```

### UI Error Display

```dart
void _showErrorDialog(String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Hata'),
      content: Text(_getLocalizedErrorMessage(error)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Tamam'),
        ),
      ],
    ),
  );
}

String _getLocalizedErrorMessage(String error) {
  // Hata mesajlarını Türkçe'ye çevir
  switch (error) {
    case 'invalid-credentials':
      return 'Geçersiz email veya şifre';
    case 'weak-password':
      return 'Şifre çok zayıf';
    case 'email-already-in-use':
      return 'Bu email adresi zaten kullanımda';
    default:
      return 'Bir hata oluştu: $error';
  }
}
```

## Testing Strategy

### Unit Tests

1. **Repository Tests**: Mock HTTP client kullanarak Firebase Auth repository testleri
2. **Service Tests**: Mock repository kullanarak AuthService testleri
3. **Provider Tests**: Riverpod provider'ların testleri

### Widget Tests

1. **Screen Tests**: Mock provider'lar kullanarak ekran testleri
2. **Form Validation Tests**: Giriş ve kayıt form validasyon testleri
3. **Navigation Tests**: AuthGate yönlendirme testleri

### Integration Tests

1. **Auth Flow Tests**: Tam kimlik doğrulama akışı testleri
2. **State Management Tests**: Riverpod state değişikliklerinin testleri

### Test Utilities

```dart
// Test için provider override'ları
class AuthTestUtils {
  static ProviderContainer createContainer({
    AuthRepository? authRepository,
  }) {
    return ProviderContainer(
      overrides: [
        if (authRepository != null)
          authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
  }

  static MockAuthRepository createMockRepository() {
    return MockAuthRepository();
  }
}
```

## Configuration Management

### Environment-based Repository Selection

```dart
enum AuthEnvironment { development, production }

final authEnvironmentProvider = Provider<AuthEnvironment>((ref) {
  // Build configuration'dan veya environment variable'dan oku
  return kDebugMode ? AuthEnvironment.development : AuthEnvironment.production;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final environment = ref.watch(authEnvironmentProvider);

  switch (environment) {
    case AuthEnvironment.development:
      return MockAuthRepository();
    case AuthEnvironment.production:
      return FirebaseAuthRepository(FirebaseAuth.instance);
  }
});
```

### Firebase Configuration

```dart
class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Debug modda emulator kullan
    if (kDebugMode) {
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    }
  }
}
```

## Performance Considerations

### Provider Optimization

```dart
// Auth state provider'ı keepAlive ile optimize et
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  ref.keepAlive(); // Provider'ı bellekte tut

  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});
```

### Memory Management

```dart
class MockAuthRepository implements AuthRepository {
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  @override
  void dispose() {
    _authStateController.close();
  }
}
```

### Loading States

```dart
// Loading state'leri için ayrı provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Service metodlarında loading state'i yönet
Future<void> login(String email, String password) async {
  ref.read(authLoadingProvider.notifier).state = true;

  try {
    await _repository.signInWithEmailAndPassword(email, password);
  } finally {
    ref.read(authLoadingProvider.notifier).state = false;
  }
}
```

Bu tasarım, ölçeklenebilir, test edilebilir ve maintainable bir kimlik doğrulama sistemi sağlar. Feature-First architecture sayesinde auth özelliği bağımsız olarak geliştirilebilir ve diğer özelliklerle minimum coupling ile entegre edilebilir.
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/api_config.dart';
import 'auth_repository.dart';
import 'models/app_user.dart';
import 'exceptions.dart';

class RailwayAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  
  AppUser? _currentUser;
  String? _currentToken;

  RailwayAuthRepository() {
    _initializeAuth();
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token != null) {
      _currentToken = token;
      try {
        await _getCurrentUser();
      } catch (e) {
        await _clearAuth();
      }
    }
    
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> signInWithEmailAndPassword(String usernameOrEmail, String password) async {
    try {
      print('🌐 Login isteği gönderiliyor: ${ApiConfig.login}');
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'username': usernameOrEmail,  // Changed to username
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentToken = data['access_token'];
        _currentUser = AppUser.fromJson(data['user']);
        
        print('🔑 Token saved: ${_currentToken?.substring(0, 10)}...');
        print('👤 User logged in: ${_currentUser?.displayName}');
        
        await _saveAuth(_currentToken!);
        
        print('📡 Adding user to auth state stream: ${_currentUser?.displayName}');
        _authStateController.add(_currentUser);
        print('✅ Auth state updated, should trigger AuthGate');
      } else if (response.statusCode == 401) {
        throw const InvalidCredentialsException();
      } else {
        final error = jsonDecode(response.body);
        throw UnknownAuthException(error['detail'] ?? 'Login failed', 'login-failed');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e is AuthException) {
        rethrow;
      }
      if (e.toString().contains('TimeoutException')) {
        throw const NetworkException();
      }
      if (e.toString().contains('SocketException')) {
        throw const NetworkException();
      }
      throw NetworkException();
    }
  }

  @override
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String department,
  }) async {
    try {
      final url = ApiConfig.register;
      final body = {
        'email': email,
        'username': username,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'department': department,
      };
      
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        // After registration, login automatically with username  
        await signInWithEmailAndPassword(username, password);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        if (error['detail'].contains('already registered')) {
          throw const EmailAlreadyInUseException();
        }
        throw const WeakPasswordException();
      } else {
        final error = jsonDecode(response.body);
        throw UnknownAuthException(error['detail'] ?? 'Registration failed', 'registration-failed');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw const NetworkException();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_currentToken != null) {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: {
            ...ApiConfig.headers,
            'Authorization': 'Bearer $_currentToken',
          },
        );
      }
    } catch (e) {
      // Logout failure is not critical
    } finally {
      await _clearAuth();
    }
  }

  Future<void> _getCurrentUser() async {
    if (_currentToken == null) return;

    final response = await http.get(
      Uri.parse(ApiConfig.currentUser),
      headers: {
        ...ApiConfig.headers,
        'Authorization': 'Bearer $_currentToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _currentUser = AppUser.fromJson(data);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  Future<void> _saveAuth(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    _currentToken = null;
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: '724215071142-s8r5t9kes47jed4ap1lepc1v9beqmuj8.apps.googleusercontent.com',
    );

    try {
      // ignore: avoid_print
      print('🔐 Starting Google Sign-In...');

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw const UnknownAuthException('Failed to get Google ID token', 'google-token-error');
      }

      // ignore: avoid_print
      print('🎫 Got Google ID Token, sending to backend...');

      // Send token to backend for verification
      final response = await http.post(
        Uri.parse(ApiConfig.googleAuth),
        headers: ApiConfig.headers,
        body: jsonEncode({'id_token': idToken}),
      ).timeout(const Duration(seconds: 30));

      // ignore: avoid_print
      print('📡 Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentToken = data['access_token'];
        _currentUser = AppUser.fromJson(data['user']);

        await _saveAuth(_currentToken!);
        _authStateController.add(_currentUser);

        // ignore: avoid_print
        print('✅ Google Sign-In completed: ${_currentUser?.displayName}');
      } else {
        final error = jsonDecode(response.body);
        throw UnknownAuthException(
          error['detail'] ?? 'Google authentication failed',
          'google-auth-failed',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Google Sign-In error: $e');
      if (e is AuthException) {
        rethrow;
      }
      if (e.toString().contains('TimeoutException')) {
        throw const NetworkException();
      }
      throw const NetworkException();
    }
  }

  void dispose() {
    _authStateController.close();
  }

  // Helper method to get current token for API calls
  String? get currentToken => _currentToken;
  AppUser? get currentUser => _currentUser;
}
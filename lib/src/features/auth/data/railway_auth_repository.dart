import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentToken = data['access_token'];
        _currentUser = AppUser.fromJson(data['user']);
        
        await _saveAuth(_currentToken!);
        _authStateController.add(_currentUser);
      } else if (response.statusCode == 401) {
        throw const InvalidCredentialsException();
      } else {
        final error = jsonDecode(response.body);
        throw UnknownAuthException(error['detail'] ?? 'Login failed', 'login-failed');
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw const NetworkException();
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
        // After registration, login automatically
        await signInWithEmailAndPassword(email, password);
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

  void dispose() {
    _authStateController.close();
  }

  // Helper method to get current token for API calls
  String? get currentToken => _currentToken;
  AppUser? get currentUser => _currentUser;
}
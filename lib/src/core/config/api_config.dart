// lib/src/core/config/api_config.dart

class ApiConfig {
  // Heroku Production URL
  static const String baseUrl = 'https://mablearn-36f11737f8f9.herokuapp.com';
  
  // API Endpoints
  static const String health = '$baseUrl/health';
  static const String questions = '$baseUrl/questions';
  static const String subjects = '$baseUrl/subjects';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

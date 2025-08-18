// lib/src/core/config/api_config.dart

class ApiConfig {
  // Heroku Production URL
  static const String BASE_URL = 'https://mablearn-36f11737f8f9.herokuapp.com';
  
  // API Endpoints
  static const String HEALTH = '$BASE_URL/health';
  static const String QUESTIONS = '$BASE_URL/questions';
  static const String SUBJECTS = '$BASE_URL/subjects';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

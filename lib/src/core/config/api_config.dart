// lib/src/core/config/api_config.dart

class ApiConfig {
  // Environment-based URL selection
  static const bool _useRailway = bool.fromEnvironment('USE_RAILWAY', defaultValue: false);
  static const bool _isDebug = bool.fromEnvironment('dart.vm.product', defaultValue: true) == false;
  
  // API URLs
  static const String _railwayUrl = 'https://web-production-a4329.up.railway.app'; 
  static const String _devUrl = 'http://localhost:8000';
  
  // Smart URL selection
  static String get baseUrl {
    if (_isDebug) {
      return _devUrl; // Development
    } else {
      return _railwayUrl; // Railway production
    }
  }
  
  // API Endpoints
  static String get health => '$baseUrl/health';
  static String get questions => '$baseUrl/questions';
  static String get subjects => '$baseUrl/subjects';
  
  // New difficulty endpoints
  static String get difficultyMetrics => '$baseUrl/api/difficulty/metrics';
  static String get submitResponse => '$baseUrl/api/difficulty/responses/submit';
  static String get globalStats => '$baseUrl/api/difficulty/stats/global';
  static String get calculateDifficulty => '$baseUrl/api/difficulty/calculate/batch';
  
  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Environment info
  static Map<String, dynamic> get environmentInfo => {
    'isDebug': _isDebug,
    'useRailway': _useRailway,
    'baseUrl': baseUrl,
    'platform': _isDebug ? 'development' : 'railway',
  };
}

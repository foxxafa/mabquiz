// lib/src/core/services/http_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  // GET Request
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var uri = Uri.parse('${ApiConfig.BASE_URL}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(
        uri,
        headers: ApiConfig.headers,
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw HttpException('Network error: $e');
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.BASE_URL}$endpoint'),
        headers: ApiConfig.headers,
        body: json.encode(data),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw HttpException('Network error: $e');
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  
  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Default URL: 10.0.2.2 is localhost for Android Emulators.
  // For physical devices, change to your computer's IP address (e.g., http://192.168.1.100:8000)
  static const String _defaultBaseUrl = kDebugMode 
      ? 'http://192.168.1.113:8000' 
      : 'https://api.kaakiscan.com'; // Production URL placeholder

  static String _baseUrl = _defaultBaseUrl;
  static String? _token;

  static String get baseUrl => _baseUrl;
  
  static void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }

  // Load token from local storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_jwt_token');
  }

  static bool get isAuthenticated => _token != null;
  static String? get token => _token;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_jwt_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_jwt_token');
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Perform a GET request
  static Future<http.Response> get(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.get(url, headers: _headers);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion au serveur backend : $e');
    }
  }

  // Perform a POST request
  static Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion au serveur backend : $e');
    }
  }

  // Perform a PUT request
  static Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.put(
        url,
        headers: _headers,
        body: json.encode(body),
      );
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion au serveur backend : $e');
    }
  }

  // Perform a DELETE request
  static Future<http.Response> delete(String path) async {
    final url = Uri.parse('$_baseUrl$path');
    try {
      final response = await http.delete(url, headers: _headers);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion au serveur backend : $e');
    }
  }

  // Upload an image file for diagnostic scan
  static Future<http.Response> uploadImage(String path, File imageFile) async {
    final url = Uri.parse('$_baseUrl$path');
    try {
      final request = http.MultipartRequest('POST', url);
      
      // Add Auth headers
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      // Add multipart file
      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: imageFile.path.split('/').last,
      );
      
      request.files.add(multipartFile);
      
      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'image au backend : $e');
    }
  }
}

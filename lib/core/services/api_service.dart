import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'server_discovery.dart';

class ApiService {
  // URL dynamique : découverte automatique sur le réseau local.
  // En production, pointe vers le vrai serveur.
  static const String _productionUrl = 'https://api.kaakiscan.com';

  // IP de secours du PC de développement (Wi-Fi actuel).
  // Utilisée immédiatement avant que la découverte ne termine.
  static const String _fallbackDevUrl = 'http://10.13.226.15:8000';

  static String _baseUrl = kDebugMode ? _fallbackDevUrl : _productionUrl;
  static String? _token;

  static String get baseUrl => _baseUrl;

  /// Callback optionnel pour afficher l'état de la découverte dans l'UI.
  static void Function(String)? onDiscoveryStatus;

  static void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
  }

  // Initialise le service : charge le token ET découvre le serveur si besoin
  static Future<void> init({void Function(String)? onStatus}) async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_jwt_token');

    // En mode développement, découverte automatique du serveur
    if (kDebugMode) {
      if (kIsWeb) {
        // Sur le Web, on utilise le même hôte que l'application mais sur le port 8000
        final host = Uri.base.host;
        _baseUrl = 'http://$host:8000';
        onStatus?.call('Serveur Web résolu : $_baseUrl');
      } else {
        final found = await ServerDiscovery.discover(
          onStatus: onStatus ?? onDiscoveryStatus,
        );
        if (found != null) {
          _baseUrl = found;
        }
        // Si found == null (ne devrait pas arriver avec le fallback dans ServerDiscovery),
        // _baseUrl reste à _fallbackDevUrl définie ci-dessus.
        onStatus?.call('Backend connecté : $_baseUrl');
      }
    }
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

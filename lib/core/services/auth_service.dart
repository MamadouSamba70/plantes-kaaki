import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import 'api_service.dart';

class AuthService {
  UserModel? _currentUser;
  bool _initialized = false;

  AuthService() {
    _loadUserSession();
  }

  UserModel? get currentUser => _currentUser;

  Future<void> _loadUserSession() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('api_user_profile');
      if (userJson != null && ApiService.isAuthenticated) {
        _currentUser = UserModel.fromMap(json.decode(userJson));
        debugPrint('KaakiScan: Session restaurée pour ${_currentUser?.email}');
      }
    } catch (e) {
      debugPrint('Error loading user session: $e');
    } finally {
      _initialized = true;
    }
  }

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_user_profile', json.encode(user.toMap()));
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_user_profile');
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<UserModel> register(
      String fullName, String email, String password, String role) async {
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      throw Exception('Veuillez remplir tous les champs.');
    }
    if (password.length < 6) {
      throw Exception('Le mot de passe doit comporter au moins 6 caractères.');
    }

    final response = await ApiService.post('/api/register', {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'role': role,
    });

    if (response.statusCode == 200 || response.statusCode == 201) {
      return UserModel.fromMap(json.decode(response.body));
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['detail'] ?? 'Erreur lors de l\'inscription');
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<UserModel> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Veuillez remplir tous les champs.');
    }

    final response = await ApiService.post('/api/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await ApiService.saveToken(data['access_token']);
      _currentUser = UserModel.fromMap(data['user']);
      await _persistSession(_currentUser!);
      return _currentUser!;
    } else {
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (_) {}
      throw Exception(errorData['detail'] ?? 'E-mail ou mot de passe incorrect.');
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _clearSession();
  }

  // ─── Get Profile ──────────────────────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    if (_currentUser != null && _currentUser!.uid == uid) {
      return _currentUser;
    }
    return null;
  }

  // ─── Update Profile ───────────────────────────────────────────────────────
  Future<UserModel> updateProfile(String fullName, String email, {String? password}) async {
    final Map<String, dynamic> body = {
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await ApiService.put('/api/users/profile', body);

    if (response.statusCode == 200) {
      final updatedUser = UserModel.fromMap(json.decode(response.body));
      _currentUser = updatedUser;
      await _persistSession(updatedUser);
      return updatedUser;
    } else {
      Map<String, dynamic> errorData = {};
      try {
        errorData = json.decode(response.body);
      } catch (_) {}
      throw Exception(errorData['detail'] ?? 'Erreur lors de la mise à jour du profil.');
    }
  }

  // ─── SuperAdmin: List Pending Users ──────────────────────────────────────
  Future<List<UserModel>> getPendingUsers() async {
    final response = await ApiService.get('/api/users/pending');
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => UserModel.fromMap(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des utilisateurs.');
    }
  }

  // ─── SuperAdmin: List Approved Users ─────────────────────────────────────
  Future<List<UserModel>> getApprovedUsers() async {
    final response = await ApiService.get('/api/users/approved');
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => UserModel.fromMap(json)).toList();
    } else {
      throw Exception('Erreur lors de la récupération des utilisateurs.');
    }
  }

  // ─── SuperAdmin: Approve User ────────────────────────────────────────────
  Future<void> approveUser(String uid) async {
    final response = await ApiService.put('/api/users/$uid/approve', {});
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de l\'approbation.');
    }
  }

  // ─── SuperAdmin: Suspend User ────────────────────────────────────────────
  Future<void> suspendUser(String uid) async {
    final response = await ApiService.put('/api/users/$uid/suspend', {});
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la suspension.');
    }
  }

  // ─── SuperAdmin: Reject / Delete User ────────────────────────────────────
  Future<void> rejectUser(String uid) async {
    final response = await ApiService.delete('/api/users/$uid');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur lors de la suppression.');
    }
  }

  // ─── SuperAdmin: Change Role ─────────────────────────────────────────────
  Future<void> changeUserRole(String uid, String newRole) async {
    final response = await ApiService.put('/api/users/$uid/role', {'role': newRole});
    if (response.statusCode != 200) {
      throw Exception('Erreur lors du changement de rôle.');
    }
  }
}

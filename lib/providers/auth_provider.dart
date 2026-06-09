import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../core/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null && (_user!.isApproved || _user!.isSuperAdmin);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMockMode => false;

  AuthProvider() {
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Small delay to ensure AuthService has finished loading session if needed
      await Future.delayed(const Duration(milliseconds: 100));
      _user = _authService.currentUser;
      // If user exists but not approved (and not superadmin), clear session
      if (_user != null && !_user!.isApproved && !_user!.isSuperAdmin) {
        _user = null;
      }
    } catch (e) {
      debugPrint('Error checking current user session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Register (returns true, but user is NOT authenticated yet) ────────────
  Future<bool> register(
      String fullName, String email, String password, {String role = 'farmer'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // register() no longer sets _user — user must wait for approval
      await _authService.register(fullName, email, password, role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
      _user = null;
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update Profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile(String fullName, String email, {String? password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(fullName, email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ─── SuperAdmin Methods ────────────────────────────────────────────────────
  Future<List<UserModel>> getPendingUsers() async {
    return await _authService.getPendingUsers();
  }

  Future<List<UserModel>> getAllApprovedUsers() async {
    return await _authService.getApprovedUsers();
  }

  Future<void> approveUser(String uid) async {
    await _authService.approveUser(uid);
    notifyListeners();
  }

  Future<void> suspendUser(String uid) async {
    await _authService.suspendUser(uid);
    notifyListeners();
  }

  Future<void> changeUserRole(String uid, String newRole) async {
    await _authService.changeUserRole(uid, newRole);
    notifyListeners();
  }

  Future<void> rejectUser(String uid) async {
    await _authService.rejectUser(uid);
    notifyListeners();
  }
}

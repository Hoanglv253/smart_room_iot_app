import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';

class AuthRepository {
  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Stream<User?> authStateChanges() {
    return _authService.authStateChanges();
  }

  Future<User?> loginWithEmail(String email, String password) {
    return _authService.loginWithEmail(email, password);
  }

  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) {
    return _authService.registerWithEmail(email, password, name, role);
  }

  Future<String> getUserRole(String uid) {
    return _authService.getUserRole(uid);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}

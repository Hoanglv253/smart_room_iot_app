import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../repositories/auth_repository.dart';

class RegisterViewModel extends BaseViewModel {
  RegisterViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;
  bool _obscurePassword = true;
  String _selectedRole = UserRole.user;

  bool get obscurePassword => _obscurePassword;
  String get selectedRole => _selectedRole;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
  }

  Future<User?> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
  }) {
    if (password.trim() != confirmPassword.trim()) {
      setError('Mật khẩu xác nhận không khớp');
      return Future.value(null);
    }

    return runBusyTask(
      () => _authRepository.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: _selectedRole,
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/auth_repository.dart';

class LoginViewModel extends BaseViewModel {
  LoginViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;
  bool _obscurePassword = true;

  bool get obscurePassword => _obscurePassword;
  Stream<User?> get authStateChanges => _authRepository.authStateChanges();

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<User?> login({
    required String email,
    required String password,
  }) {
    return runBusyTask(
      () => _authRepository.loginWithEmail(email, password),
    );
  }
}

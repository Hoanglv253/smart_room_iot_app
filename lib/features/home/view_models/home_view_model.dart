import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../../auth/repositories/auth_repository.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<String> loadRole(String uid) async {
    return _authRepository.getUserRole(uid);
  }

  Future<void> logout() {
    return _authRepository.logout();
  }

  String fallbackRole() {
    return UserRole.user;
  }
}

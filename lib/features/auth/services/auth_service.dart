import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorMessage(e, isLogin: true));
    }
  }

  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
    String role,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name.trim());
        await AppFirestoreService.saveUserProfile(
          uid: user.uid,
          email: user.email ?? email.trim(),
          name: name.trim(),
          role: role,
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthErrorMessage(e, isLogin: false));
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      return AppFirestoreService.getUserRole(uid);
    } catch (_) {
      return UserRole.user;
    }
  }

  Future<void> logout() {
    return _auth.signOut();
  }

  String _mapAuthErrorMessage(
    FirebaseAuthException error, {
    required bool isLogin,
  }) {
    final rawMessage = (error.message ?? '').toLowerCase();

    final isBlockedIdentityToolkit =
        rawMessage.contains('signInWithPassword are blocked'.toLowerCase()) ||
        rawMessage.contains('identitytoolkit') ||
        rawMessage.contains('authenticationservice.signinwithpassword');

    if (isBlockedIdentityToolkit) {
      return 'Đăng nhập tìm thỏi không khả dụng do cấu hình Firebase. '
          'Hay bat Email/Password trong Firebase Authentication và '
          'bật Identity Toolkit API trong Google Cloud Console.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return isLogin ? 'Email hoặc mật khẩu không đúng.' : 'Thông tin đăng ký không hợp lệ.';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Ban thử quá nhiều lần. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Không có kết nối mạng. Vui lòng kiểm tra Internet.';
      case 'operation-not-allowed':
        return isLogin
            ? 'Phương thức đăng nhập Email/Password chưa được bật trên Firebase.'
            : 'Phương thức đăng nhập Email/Password chưa được bật trên Firebase.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';
      case 'weak-password':
        return 'Mật khẩu quá yếu. Vui lòng dùng mật khẩu mạnh hơn.';
      default:
        return isLogin ? 'Đăng nhập thất bại. Vui lòng thử lại.' : 'Đăng ký thất bại. Vui lòng thử lại.';
    }
  }
}

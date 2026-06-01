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
      return 'Dang nhap tam thoi khong kha dung do cau hinh Firebase. '
          'Hay bat Email/Password trong Firebase Authentication va '
          'bat Identity Toolkit API trong Google Cloud Console.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Email khong hop le.';
      case 'user-not-found':
        return 'Khong tim thay tai khoan voi email nay.';
      case 'wrong-password':
      case 'invalid-credential':
        return isLogin ? 'Email hoac mat khau khong dung.' : 'Thong tin dang ky khong hop le.';
      case 'user-disabled':
        return 'Tai khoan da bi vo hieu hoa.';
      case 'too-many-requests':
        return 'Ban thu qua nhieu lan. Vui long thu lai sau it phut.';
      case 'network-request-failed':
        return 'Khong co ket noi mang. Vui long kiem tra Internet.';
      case 'operation-not-allowed':
        return isLogin
            ? 'Phuong thuc dang nhap Email/Password chua duoc bat tren Firebase.'
            : 'Phuong thuc dang ky Email/Password chua duoc bat tren Firebase.';
      case 'email-already-in-use':
        return 'Email nay da duoc su dung.';
      case 'weak-password':
        return 'Mat khau qua yeu. Vui long dung mat khau manh hon.';
      default:
        return isLogin ? 'Dang nhap that bai. Vui long thu lai.' : 'Dang ky that bai. Vui long thu lai.';
    }
  }
}

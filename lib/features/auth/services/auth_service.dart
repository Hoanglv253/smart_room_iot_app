import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Dang nhap that bai');
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
      throw Exception(e.message ?? 'Dang ky that bai');
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
}

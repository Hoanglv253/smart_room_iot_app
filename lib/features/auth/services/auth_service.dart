import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/services/app_firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng nhập thất bại');
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
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);
        await _upsertUserProfile(
          uid: user.uid,
          email: user.email ?? email,
          name: name,
          role: role,
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng ký thất bại');
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc = await AppFirestoreService.users.doc(user.uid).get();
        if (!userDoc.exists) {
          await _upsertUserProfile(
            uid: user.uid,
            email: user.email ?? googleUser.email,
            name: user.displayName ?? googleUser.displayName ?? 'Người dùng',
            role: 'user',
          );
        }
      }

      return user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại!');
    }
  }

  Future<String> getUserRole(String uid) async {
    try {
      final doc = await AppFirestoreService.users.doc(uid).get();
      if (!doc.exists) return 'user';
      final data = doc.data();
      return (data?['role'] ?? 'user').toString();
    } catch (_) {
      return 'user';
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _upsertUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) async {
    await AppFirestoreService.users.doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Khởi tạo Database

  // ================= 1. ĐĂNG NHẬP BẰNG EMAIL =================
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng nhập thất bại');
    }
  }

  // ================= 2. ĐĂNG KÝ BẰNG EMAIL (NEW) =================
  Future<User?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      // 1. Tạo tài khoản trên Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // 2. Cập nhật tên hiển thị (displayName) cho Auth
      if (user != null) {
        await user.updateDisplayName(name);

        // 3. Lưu thông tin và QUYỀN (Role) vào Firestore Database
        // Mặc định người mới đăng ký sẽ có role là 'user'
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': name,
          'role': 'user', // Đây chính là mấu chốt phân quyền!
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng ký thất bại');
    }
  }

  // ================= 3. ĐĂNG NHẬP BẰNG GOOGLE =================
  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? user = userCredential.user;

      // KHI ĐĂNG NHẬP GOOGLE: Kiểm tra xem user này đã có trong Database chưa
      // Nếu chưa có (người mới) thì tạo cho họ 1 record với role là 'user'
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'Người dùng Google',
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return user;
    } catch (e) {
      debugPrint('Lỗi đăng nhập Google: $e');
      throw Exception('Đăng nhập Google thất bại. Vui lòng thử lại!');
    }
  }

  // ================= 4. KIỂM TRA QUYỀN (NEW) =================
  // Hàm này để lấy role của user hiện tại, dùng để ẩn/hiện nút điều khiển
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.get('role') ?? 'user';
      }
      return 'user';
    } catch (e) {
      return 'user';
    }
  }

  // ================= 5. ĐĂNG XUẤT =================
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

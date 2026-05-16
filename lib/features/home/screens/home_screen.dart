import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Cần cái này để lấy "thẻ căn cước"
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Gọi thần chú lấy thông tin User đang đăng nhập
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Room Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity, // Kéo dãn bối cảnh ra toàn màn hình
        color: Colors.blue[50], // Nền xanh nhạt cho hợp tone
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ================= AVATAR =================
            // Dùng widget CircleAvatar để bo tròn ảnh
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              // Nếu user có ảnh (photoURL != null) thì tải ảnh trên mạng về, ngược lại hiện icon mặc định
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 60, color: Colors.blue)
                  : null,
            ),

            const SizedBox(height: 24),

            // ================= TÊN =================
            Text(
              user?.displayName ??
                  'Người dùng ẩn danh', // Dấu ?? nghĩa là "nếu không có tên thì xài chữ bên phải"
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 8),

            // ================= EMAIL =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: Text(
                user?.email ?? 'Không có email',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

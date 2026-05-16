import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final AuthService authService =
        AuthService(); // Khởi tạo AuthService để gọi hàm lấy Role

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Room Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
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
        width: double.infinity,
        color: Colors.blue[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ================= AVATAR & INFO =================
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 60, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              user?.displayName ?? 'Người dùng ẩn danh',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
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

            const SizedBox(height: 48),

            // ================= KHU VỰC PHÂN QUYỀN (AUTHORIZATION) =================
            // FutureBuilder giúp đợi dữ liệu role từ Firebase tải về
            FutureBuilder<String>(
              future: user != null
                  ? authService.getUserRole(user.uid)
                  : Future.value('user'),
              builder: (context, snapshot) {
                // Đang tải dữ liệu thì xoay vòng vòng
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                // Lấy role, nếu lỗi thì mặc định là 'user'
                final role = snapshot.data ?? 'user';

                return Column(
                  children: [
                    // 1. Nút này AI CŨNG THẤY (User & Admin)
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.meeting_room, color: Colors.white),
                      label: const Text(
                        'Phòng của tôi',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // 2. Nút này CHỈ ADMIN MỚI THẤY (Logic Phân Quyền)
                    if (role == 'admin') ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Quản lý chung cư (Admin)',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

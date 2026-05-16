import 'package:flutter/material.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Room Dashboard'),
        backgroundColor: Colors.blueAccent,
        actions: [
          // Nút Đăng xuất
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // 1. Gọi hàm logout
              await AuthService().logout();

              // 2. Văng ngược lại màn hình Login và xóa lịch sử trang
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Chào mừng bạn đến với Hệ thống quản lý Smart Room!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

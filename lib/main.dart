import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import file màn hình đăng nhập của bạn

void main() {
  runApp(const SmartRoomApp());
}

class SmartRoomApp extends StatelessWidget {
  const SmartRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Room IoT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true, // Sử dụng phong cách thiết kế Material 3 hiện đại
      ),
      home: const LoginScreen(), // Đặt màn hình chính là LoginScreen
      debugShowCheckedModeBanner:
          false, // Tắt dải băng 'DEBUG' ở góc phải màn hình
    );
  }
}

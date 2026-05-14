import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import file màn hình đăng nhập của bạn
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // 1. Lệnh bắt buộc để Flutter có thể giao tiếp với hệ thống (Native) trước khi vẽ giao diện
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Khởi động Firebase và nạp file cấu hình mà em vừa tạo ban nãy
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Chạy App lên
  runApp(
    const SmartRoomApp(),
  ); // Lưu ý: Nếu App gốc của em tên khác thì giữ nguyên tên đó nhé
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

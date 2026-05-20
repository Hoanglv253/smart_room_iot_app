import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ManagerBuildingScreen extends StatelessWidget {
  const ManagerBuildingScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Khu vực quản lý tòa nhà. Sau khi admin phê duyệt, các công việc và tòa nhà đang quản lý sẽ hiển thị ở đây.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

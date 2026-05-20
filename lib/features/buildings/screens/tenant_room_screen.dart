import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TenantRoomScreen extends StatelessWidget {
  const TenantRoomScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Phòng của tôi sẽ hiển thị sau khi admin phê duyệt bạn vào tòa nhà và gán phòng.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BasicSettingsScreen extends StatelessWidget {
  const BasicSettingsScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_outlined, size: 72, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(
              user.email ?? 'Tài khoản',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Cài đặt tài khoản sẽ được bổ sung ở bước tiếp theo.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

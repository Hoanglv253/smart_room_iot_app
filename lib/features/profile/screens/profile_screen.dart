import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.roleLabel,
    required this.avatarText,
    required this.avatarColor,
    required this.avatarTextColor,
    super.key,
  });

  final User user;
  final String roleLabel;
  final String avatarText;
  final Color avatarColor;
  final Color avatarTextColor;

  String get _displayName {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email ?? roleLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: avatarColor,
              child: Text(
                avatarText,
                style: TextStyle(
                  color: avatarTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$roleLabel - $_displayName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sửa ảnh'),
            ),
          ],
        ),
      ),
    );
  }
}

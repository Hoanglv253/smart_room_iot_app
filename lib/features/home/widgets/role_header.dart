import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/screens/profile_screen.dart';

class RoleHeader extends StatelessWidget {
  const RoleHeader({
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
    final photoUrl = user.photoURL?.trim() ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              user: user,
              roleLabel: roleLabel,
              avatarText: avatarText,
              avatarColor: avatarColor,
              avatarTextColor: avatarTextColor,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: avatarColor,
              backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
              child: photoUrl.isEmpty
                  ? Text(
                      avatarText,
                      style: TextStyle(
                        color: avatarTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xin chào, $_displayName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFE0E7FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

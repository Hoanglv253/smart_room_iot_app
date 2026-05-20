import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.chats
          .where('memberIds', arrayContains: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data?.docs ?? [];
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chưa có cuộc trò chuyện. Khi bạn nhắn với admin hoặc được duyệt vào tòa nhà, chat sẽ xuất hiện ở đây.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: chats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = chats[index].data();
            final isGroup = data['type'] == ChatType.group;
            return Card(
              elevation: 1,
              child: ListTile(
                leading: Icon(
                  isGroup ? Icons.groups_outlined : Icons.person_outline,
                  color: Colors.blueAccent,
                ),
                title: Text((data['title'] ?? 'Tin nhắn').toString()),
                subtitle: Text(
                  (data['lastMessage'] ?? '').toString().isEmpty
                      ? (isGroup ? 'Nhóm chat tòa nhà' : 'Chat riêng')
                      : data['lastMessage'].toString(),
                ),
                onTap: () {},
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import 'chat_detail_screen.dart';

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
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Khong tai duoc danh sach chat. Kiem tra Firestore Rules cho collection chats.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data?.docs ?? [];
        if (chats.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Chua co cuoc tro chuyen. Khi ban nhan voi admin hoac duoc duyet vao toa nha, chat se xuat hien o day.',
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
            final doc = chats[index];
            final data = doc.data();
            final isGroup = data['type'] == ChatType.group;
            final title = (data['title'] ?? 'Tin nhan').toString();
            final lastMessage = (data['lastMessage'] ?? '').toString();

            return Card(
              elevation: 1,
              child: ListTile(
                leading: Icon(
                  isGroup ? Icons.groups_outlined : Icons.person_outline,
                  color: Colors.blueAccent,
                ),
                title: Text(title),
                subtitle: Text(
                  lastMessage.isEmpty
                      ? (isGroup ? 'Nhom chat toa nha' : 'Chat rieng')
                      : lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        chatId: doc.id,
                        chatTitle: title,
                        user: user,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

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

        final chats = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final isGroup = data['type'] == ChatType.group;
          final deletedFor = List<String>.from(data['deletedFor'] ?? []);
          return data['isDeleted'] != true &&
              (isGroup || !deletedFor.contains(user.uid));
        }).toList()
          ..sort((left, right) {
            final leftGroup = left.data()['type'] == ChatType.group;
            final rightGroup = right.data()['type'] == ChatType.group;
            if (leftGroup != rightGroup) return leftGroup ? -1 : 1;

            final leftUpdatedAt = _timestampMillis(left.data()['updatedAt']);
            final rightUpdatedAt = _timestampMillis(right.data()['updatedAt']);
            return rightUpdatedAt.compareTo(leftUpdatedAt);
          });

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
          separatorBuilder: (_, _) => const SizedBox(height: 8),
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
                trailing: isGroup
                    ? const Icon(Icons.push_pin_outlined, color: Colors.blueAccent)
                    : null,
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
                onLongPress: isGroup
                    ? null
                    : () => _confirmDeleteChat(context, doc.id),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteChat(BuildContext context, String chatId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xoa doan chat?'),
          content: const Text('Ban co chac chan muon xoa doan chat khong?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Co'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !context.mounted) return;

    try {
      await AppFirestoreService.chats.doc(chatId).update({
        'memberIds': [],
        'deletedFor': [],
        'isDeleted': true,
        'deletedBy': user.uid,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da xoa khung chat.')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen xoa khung chat.'
                : e.message ?? 'Khong xoa duoc khung chat.',
          ),
        ),
      );
    }
  }

  static int _timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}

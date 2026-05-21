import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../messages/screens/chat_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.user,
    required this.role,
    super.key,
  });

  final User user;
  final String role;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await AppFirestoreService.posts.add({
        'authorId': widget.user.uid,
        'authorName': widget.user.displayName ?? widget.user.email ?? 'User',
        'authorEmail': widget.user.email ?? '',
        'authorRole': widget.role,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _postController.clear();
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PostComposer(
          controller: _postController,
          isPosting: _isPosting,
          onPost: _createPost,
        ),
        if (widget.role != UserRole.admin) ...[
          const SizedBox(height: 16),
          _BuildingDiscovery(user: widget.user, role: widget.role),
        ],
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AppFirestoreService.posts
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final posts = snapshot.data?.docs ?? [];
            if (posts.isEmpty) {
              return const _EmptyFeed();
            }

            return Column(
              children: posts.map((doc) => _PostCard(data: doc.data())).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _BuildingDiscovery extends StatelessWidget {
  const _BuildingDiscovery({required this.user, required this.role});

  final User user;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tòa nhà đang tuyển',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AppFirestoreService.buildings.snapshots(),
              builder: (context, snapshot) {
                final buildings = snapshot.data?.docs ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(minHeight: 2);
                }

                if (buildings.isEmpty) {
                  return const Text('Chưa có tòa nhà nào được đăng.');
                }

                return Column(
                  children: buildings.map((doc) {
                    final data = doc.data();
                    return _BuildingDiscoveryTile(
                      buildingId: doc.id,
                      building: data,
                      user: user,
                      role: role,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildingDiscoveryTile extends StatelessWidget {
  const _BuildingDiscoveryTile({
    required this.buildingId,
    required this.building,
    required this.user,
    required this.role,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final User user;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = (building['name'] ?? 'Tòa nhà').toString();
    final address = (building['address'] ?? 'Chưa có địa chỉ').toString();

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.apartment_outlined, color: Colors.blueAccent),
      title: Text(name),
      subtitle: Text(address),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Nhắn admin',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _messageAdmin(context),
          ),
          IconButton(
            tooltip: 'Xin vào',
            icon: const Icon(Icons.login_outlined),
            onPressed: () => _requestJoin(context),
          ),
        ],
      ),
    );
  }

  Future<void> _requestJoin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final existing = await AppFirestoreService.joinRequests
        .where('buildingId', isEqualTo: buildingId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: JoinRequestStatus.pending)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã gửi yêu cầu trước đó.')),
        );
      }
      return;
    }

    await AppFirestoreService.joinRequests.add({
      'buildingId': buildingId,
      'buildingName': building['name'] ?? '',
      'adminId': adminId,
      'requesterId': user.uid,
      'requesterName': user.displayName ?? user.email ?? 'Người dùng',
      'requesterEmail': user.email ?? '',
      'requesterRole': role,
      'status': JoinRequestStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu tham gia tòa nhà.')),
      );
    }
  }

  Future<void> _messageAdmin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;
    final title = 'Chat với admin ${(building['adminName'] ?? '').toString()}';

    final existing = await AppFirestoreService.chats
        .where('type', isEqualTo: ChatType.private)
        .where('memberIds', arrayContains: user.uid)
        .get();

    final found = existing.docs.where((doc) {
      final members = List<String>.from(doc.data()['memberIds'] ?? []);
      return members.contains(adminId);
    }).toList();

    String chatId;
    if (found.isEmpty) {
      final chatDoc = await AppFirestoreService.chats.add({
        'type': ChatType.private,
        'buildingId': buildingId,
        'ownerId': adminId,
        'title': title,
        'memberIds': [user.uid, adminId],
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      chatId = chatDoc.id;
    } else {
      chatId = found.first.id;
    }

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            chatTitle: title,
            user: user,
          ),
        ),
      );
    }
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.controller,
    required this.isPosting,
    required this.onPost,
  });

  final TextEditingController controller;
  final bool isPosting;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Bạn đang muốn chia sẻ điều gì?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isPosting ? null : onPost,
                icon: const Icon(Icons.send_outlined),
                label: const Text('Đăng bài'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final authorName = (data['authorName'] ?? 'Người dùng').toString();
    final role = UserRole.label((data['authorRole'] ?? UserRole.user).toString());
    final content = (data['content'] ?? '').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(role, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(content),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(child: Text('Chưa có bài đăng nào.')),
    );
  }
}

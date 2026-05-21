import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    required this.chatId,
    required this.chatTitle,
    required this.user,
    super.key,
  });

  final String chatId;
  final String chatTitle;
  final User user;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final senderName =
          widget.user.displayName ?? widget.user.email ?? 'Nguoi dung';

      await AppFirestoreService.chatMessages(widget.chatId).add({
        'senderId': widget.user.uid,
        'senderName': senderName,
        'senderEmail': widget.user.email ?? '',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await AppFirestoreService.chats.doc(widget.chatId).update({
        'lastMessage': text,
        'lastSenderId': widget.user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen gui tin nhan.'
                : e.message ?? 'Khong gui duoc tin nhan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AppFirestoreService.chatMessages(widget.chatId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Khong tai duoc tin nhan. Kiem tra Firestore Rules cho chats/messages.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chua co tin nhan nao.'),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data();
                    final isMine = data['senderId'] == widget.user.uid;
                    return _MessageBubble(data: data, isMine: isMine);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Nhap tin nhan...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.data, required this.isMine});

  final Map<String, dynamic> data;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final text = (data['text'] ?? '').toString();
    final senderName = (data['senderName'] ?? 'Nguoi dung').toString();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? Colors.blueAccent : const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(color: isMine ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

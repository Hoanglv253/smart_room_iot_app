import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../view_models/chat_detail_view_model.dart';

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
  final _viewModel = ChatDetailViewModel();

  @override
  void dispose() {
    _messageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final sent = await _viewModel.sendMessage(
      chatId: widget.chatId,
      user: widget.user,
      text: _messageController.text,
    );

    if (!mounted) return;

    if (sent) {
      _messageController.clear();
      return;
    }

    final message = _sendErrorMessage(_viewModel.errorMessage);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: AppTheme.primaryGradient())),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _viewModel.messages(widget.chatId),
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
                  return const Center(child: Text('Chua co tin nhan nao.'));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  AnimatedBuilder(
                    animation: _viewModel,
                    builder: (context, _) {
                      return IconButton.filled(
                        onPressed: _viewModel.isLoading ? null : _sendMessage,
                        icon: _viewModel.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _sendErrorMessage(String? errorMessage) {
    if (_messageController.text.trim().isEmpty) return null;

    if (errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chua cap quyen gui tin nhan.';
    }

    return 'Khong gui duoc tin nhan.';
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isMine ? null : Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    senderName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    final normalizedTitle = widget.chatTitle.toLowerCase();
    final isPrivateChat = normalizedTitle.contains('chat voi') ||
        normalizedTitle.contains('chat với');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: AppColors.primary,
        titleSpacing: 0,
        title: _ChatAppBarTitle(
          title: widget.chatTitle,
          subtitle: isPrivateChat ? 'Chat riêng' : 'Nhóm tòa nhà',
          isPrivateChat: isPrivateChat,
        ),
        actions: [
          IconButton(
            onPressed: _showChatInfo,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  top: 96,
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary.withValues(alpha: 0.05),
                    size: 190,
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _viewModel.messages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Không tải được tin nhắn. Kiểm tra Firestore Rules cho chats/messages.',
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
                      return const _ChatEmptyState();
                    }

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const _DateChip(label: 'Hom này');
                        }

                        final data = messages[index].data();
                        final isMine = data['senderId'] == widget.user.uid;
                        return _MessageBubble(data: data, isMine: isMine);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            isLoading: _viewModel.isLoading,
            onSend: _sendMessage,
            onAttach: _showAttachmentHint,
          ),
        ],
      ),
    );
  }

  void _showAttachmentHint() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng gửi tệp/ảnh sẽ được thêm sau.')),
    );
  }

  void _showChatInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thông tin đoạn chat.')),
    );
  }

  String? _sendErrorMessage(String? errorMessage) {
    if (_messageController.text.trim().isEmpty) return null;

    if (errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền gửi tin nhắn.';
    }

    return 'Không gửi được tin nhắn.';
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({
    required this.title,
    required this.subtitle,
    required this.isPrivateChat,
  });

  final String title;
  final String subtitle;
  final bool isPrivateChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isPrivateChat
                ? Icons.person_outline_rounded
                : Icons.apartment_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
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
    final senderName = (data['senderName'] ?? 'Người dùng').toString();
    final timeLabel = _messageTime(data['createdAt']);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMine ? 20 : 6),
              bottomRight: Radius.circular(isMine ? 6 : 20),
            ),
            border: isMine ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: (isMine ? AppColors.primary : Colors.black)
                    .withValues(alpha: isMine ? 0.14 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    senderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              Text(
                text,
                style: TextStyle(
                  color: isMine ? Colors.white : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (timeLabel.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _messageTime(Object? value) {
    if (value is! Timestamp) return '';
    final date = value.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposerIconButton(
              icon: Icons.add_rounded,
              onPressed: onAttach,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onAttach,
                      icon: const Icon(Icons.image_outlined),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              height: 52,
              child: IconButton.filled(
                onPressed: isLoading ? null : onSend,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  const _ComposerIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.primary,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primarySoft,
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có tin nhắn nào.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy gửi lời chào để bắt đầu cuộc trò chuyện.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

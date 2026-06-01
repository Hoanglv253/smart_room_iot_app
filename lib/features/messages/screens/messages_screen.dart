import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/messages_view_model.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({required this.user, super.key});

  final User user;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _viewModel = MessagesViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _viewModel.userChats(widget.user.uid),
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

            final chats = _viewModel.visibleChats(
              docs: snapshot.data?.docs ?? [],
              userId: widget.user.uid,
            );

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              itemCount: chats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = chats[index];
                final data = doc.data();
                final isGroup = data['type'] == ChatType.group;
                final title = (data['title'] ?? 'Tin nhan').toString();
                final lastMessage = (data['lastMessage'] ?? '').toString();

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatDetailScreen(
                          chatId: doc.id,
                          chatTitle: title,
                          user: widget.user,
                        ),
                      ),
                    );
                  },
                  onLongPress: isGroup
                      ? null
                      : () => _confirmDeleteChat(context, doc.id),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: isGroup
                                ? const Color(0xFFE8F3FF)
                                : const Color(0xFFF2F5FB),
                            child: Icon(
                              isGroup
                                  ? Icons.apartment_rounded
                                  : Icons.person_outline_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastMessage.isEmpty
                                      ? (isGroup
                                          ? 'Nhom chat toa nha'
                                          : 'Chat rieng')
                                      : lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isGroup)
                            const Icon(
                              Icons.push_pin_outlined,
                              color: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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

    final deleted = await _viewModel.deletePrivateChat(
      chatId: chatId,
      userId: widget.user.uid,
    );
    if (!context.mounted) return;

    final message = deleted
        ? 'Da xoa khung chat.'
        : _deleteErrorMessage(_viewModel.errorMessage);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _deleteErrorMessage(String? errorMessage) {
    if (errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chua cap quyen xoa khung chat.';
    }

    return 'Khong xoa duoc khung chat.';
  }
}

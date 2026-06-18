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
  final _searchController = TextEditingController();
  final _viewModel = MessagesViewModel();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
                    'Không tải được danh sách chat. Kiểm tra Firestore Rules cho collection chats.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final chats = _viewModel
                .visibleChats(
                  docs: snapshot.data?.docs ?? [],
                  userId: widget.user.uid,
                )
                .map(
                  (doc) => _ChatPreview.fromDoc(
                    doc,
                    currentUserId: widget.user.uid,
                  ),
                )
                .toList();

            if (chats.isEmpty) {
              return const _MessagesEmptyView();
            }

            final filteredChats = chats.where(_matchesFilters).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                _InboxSummaryCard(chats: chats),
                const SizedBox(height: 14),
                _MessageSearchPanel(
                  controller: _searchController,
                  selectedFilter: _selectedFilter,
                  onFilterChanged: _selectFilter,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${filteredChats.length} đoạn chat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    const Text(
                      'Nhắn gần đây',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (filteredChats.isEmpty)
                  const _NoChatResult()
                else
                  ...filteredChats.map(
                    (chat) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ChatPreviewCard(
                        chat: chat,
                        onTap: () => _openChat(chat),
                        onLongPress: chat.isGroup
                            ? null
                            : () => _confirmDeleteChat(context, chat.id),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool _matchesFilters(_ChatPreview chat) {
    final filter = _selectedFilter;
    if (filter == 'pinned' && !chat.isPinned) return false;
    if (filter == 'private' && chat.isGroup) return false;
    if (filter == 'group' && !chat.isGroup) return false;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;

    return chat.title.toLowerCase().contains(query) ||
        chat.lastMessage.toLowerCase().contains(query) ||
        chat.typeLabel.toLowerCase().contains(query);
  }

  void _selectFilter(String? filter) {
    setState(() => _selectedFilter = filter);
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _openChat(_ChatPreview chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chat.id,
          chatTitle: chat.title,
          user: widget.user,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChat(BuildContext context, String chatId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa đoạn chat?'),
          content: const Text('Bạn có chắc chắn muốn xóa đoạn chat không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
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
        ? 'Đã xóa khung chat.'
        : _deleteErrorMessage(_viewModel.errorMessage);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _deleteErrorMessage(String? errorMessage) {
    if (errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền xóa khung chat.';
    }

    return 'Không xóa được khung chat.';
  }
}

class _InboxSummaryCard extends StatelessWidget {
  const _InboxSummaryCard({required this.chats});

  final List<_ChatPreview> chats;

  @override
  Widget build(BuildContext context) {
    final pinnedCount = chats.where((chat) => chat.isPinned).length;
    final unreadLikeCount = chats.where((chat) => chat.isFromOtherUser).length;
    String? buildingTitle;
    for (final chat in chats) {
      if (chat.isGroup) {
        buildingTitle = chat.title;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -30,
            child: Icon(
              Icons.mark_unread_chat_alt_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 146,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingTitle ?? 'Hộp thư của bạn',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tin nhắn mới và nhóm tòa nhà',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _InboxMetric(
                      label: 'Đoạn chat',
                      value: chats.length,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InboxMetric(
                      label: 'Ghim',
                      value: pinnedCount,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InboxMetric(
                      label: 'Mới',
                      value: unreadLikeCount,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InboxMetric extends StatelessWidget {
  const _InboxMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageSearchPanel extends StatelessWidget {
  const _MessageSearchPanel({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Tìm tên, tòa nhà, tin nhắn...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.tune_outlined),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MessageFilterChip(
                  label: 'Tất cả',
                  selected: selectedFilter == null,
                  onTap: () => onFilterChanged(null),
                ),
                _MessageFilterChip(
                  label: 'Ghim',
                  selected: selectedFilter == 'pinned',
                  onTap: () => onFilterChanged('pinned'),
                ),
                _MessageFilterChip(
                  label: 'Cá nhân',
                  selected: selectedFilter == 'private',
                  onTap: () => onFilterChanged('private'),
                ),
                _MessageFilterChip(
                  label: 'Tòa nhà',
                  selected: selectedFilter == 'group',
                  onTap: () => onFilterChanged('group'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageFilterChip extends StatelessWidget {
  const _MessageFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: selected ? const Icon(Icons.check, size: 18) : null,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _ChatPreviewCard extends StatelessWidget {
  const _ChatPreviewCard({
    required this.chat,
    required this.onTap,
    required this.onLongPress,
  });

  final _ChatPreview chat;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chat.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(chat.icon, color: chat.accentColor, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (chat.timeLabel.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            chat.timeLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      chat.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ChatTag(
                          icon: chat.isGroup
                              ? Icons.apartment_rounded
                              : Icons.person_outline_rounded,
                          label: chat.typeLabel,
                          color: chat.accentColor,
                        ),
                        if (chat.isFromOtherUser) ...[
                          const SizedBox(width: 8),
                          const _UnreadDot(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                chat.isPinned ? Icons.push_pin_rounded : Icons.chevron_right,
                color: chat.isPinned ? AppColors.primary : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTag extends StatelessWidget {
  const _ChatTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Mới',
        style: TextStyle(
          color: Color(0xFF16A34A),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MessagesEmptyView extends StatelessWidget {
  const _MessagesEmptyView();

  @override
  Widget build(BuildContext context) {
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
}

class _NoChatResult extends StatelessWidget {
  const _NoChatResult();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Không tìm thấy đoạn chat phù hợp.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ChatPreview {
  const _ChatPreview({
    required this.id,
    required this.title,
    required this.type,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
    required this.currentUserId,
  });

  factory _ChatPreview.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data();
    return _ChatPreview(
      id: doc.id,
      title: (data['title'] ?? 'Tin nhắn').toString(),
      type: (data['type'] ?? ChatType.private).toString(),
      lastMessage: (data['lastMessage'] ?? '').toString(),
      lastSenderId: (data['lastSenderId'] ?? '').toString(),
      updatedAt: data['updatedAt'],
      currentUserId: currentUserId,
    );
  }

  final String id;
  final String title;
  final String type;
  final String lastMessage;
  final String lastSenderId;
  final Object? updatedAt;
  final String currentUserId;

  bool get isGroup => type == ChatType.group;

  bool get isPinned => isGroup;

  bool get isFromOtherUser {
    return lastSenderId.isNotEmpty && lastSenderId != currentUserId;
  }

  String get typeLabel => isGroup ? 'Nhóm tòa nhà' : 'Chat riêng';

  String get subtitle {
    if (lastMessage.isNotEmpty) return lastMessage;
    return typeLabel;
  }

  IconData get icon {
    return isGroup ? Icons.apartment_rounded : Icons.person_outline_rounded;
  }

  Color get accentColor {
    return isGroup ? AppColors.primary : AppColors.tenantAccent;
  }

  String get timeLabel {
    final date = _timestampDate(updatedAt);
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static DateTime? _timestampDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

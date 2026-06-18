import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/theme/app_theme.dart';
import '../models/app_notification.dart';
import '../view_models/notifications_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.user,
    required this.role,
    required this.buildingId,
    required this.buildingName,
    this.roomId,
    super.key,
  });

  final User user;
  final String role;
  final String buildingId;
  final String buildingName;
  final String? roomId;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _viewModel = NotificationsViewModel();

  bool get _canCompose => widget.role != UserRole.user;

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _canCompose
          ? FloatingActionButton.extended(
              onPressed: _showComposer,
              icon: const Icon(Icons.edit_notifications_outlined),
              label: const Text('Gửi thông báo'),
            )
          : null,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder(
            stream: _viewModel.buildingNotifications(widget.buildingId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _NotificationEmptyState(
                  icon: Icons.lock_outline,
                  title: 'Không tải được thông báo',
                  message:
                      'Kiểm tra Firestore Rules cho collection notifications.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final visible = _viewModel.visibleNotifications(
                docs: snapshot.data?.docs ?? [],
                userId: widget.user.uid,
                role: widget.role,
                roomId: widget.roomId,
              );
              final filtered = _viewModel.filteredNotifications(
                items: visible,
                userId: widget.user.uid,
              );
              final unreadCount = _viewModel.unreadCount(
                visible,
                widget.user.uid,
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _NotificationHeroCard(
                    buildingName: widget.buildingName,
                    totalCount: visible.length,
                    unreadCount: unreadCount,
                    canCompose: _canCompose,
                    onCompose: _showComposer,
                  ),
                  const SizedBox(height: 14),
                  _NotificationFilterBar(
                    selectedFilter: _viewModel.filter,
                    onChanged: _viewModel.setFilter,
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    _NotificationEmptyState(
                      icon: Icons.notifications_none_outlined,
                      title: visible.isEmpty
                          ? 'Chưa có thông báo'
                          : 'Không có thông báo phù hợp',
                      message: visible.isEmpty
                          ? 'Khi có hóa đơn, yêu cầu hoặc thông báo từ tòa nhà, app sẽ hiển thị tại đây.'
                          : 'Thử đổi bộ lọc để xem các thông báo khác.',
                    )
                  else
                    ..._notificationChildren(filtered),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _notificationChildren(List<AppNotification> items) {
    final children = <Widget>[];
    String? currentDay;

    for (final item in items) {
      if (item.dayLabel != currentDay) {
        currentDay = item.dayLabel;
        children.add(
          Padding(
            padding: EdgeInsets.only(
              top: children.isEmpty ? 0 : 8,
              bottom: 10,
            ),
            child: Text(
              currentDay,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _NotificationCard(
            notification: item,
            isRead: item.isReadBy(widget.user.uid),
            onTap: () => _openDetail(item),
          ),
        ),
      );
    }

    return children;
  }

  Future<void> _openDetail(AppNotification notification) async {
    if (!notification.isReadBy(widget.user.uid)) {
      await _viewModel.markAsRead(
        notificationId: notification.id,
        userId: widget.user.uid,
      );
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _NotificationDetailScreen(notification: notification),
      ),
    );
  }

  Future<void> _showComposer() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _NotificationComposerSheet(
          buildingName: widget.buildingName,
          isLoading: _viewModel.isLoading,
          onSubmit: ({
            required String title,
            required String body,
            required String type,
            required String audience,
          }) async {
            final created = await _viewModel.createNotification(
              buildingId: widget.buildingId,
              title: title,
              body: body,
              type: type,
              audience: audience,
              createdBy: widget.user.uid,
              createdByName:
                  widget.user.displayName ?? widget.user.email ?? 'Quản lý',
            );

            if (!mounted) return false;
            if (!created) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _viewModel.errorMessage?.contains('permission-denied') ==
                            true
                        ? 'Firestore chưa cấp quyền gửi thông báo.'
                        : 'Không gửi được thông báo.',
                  ),
                ),
              );
            }
            return created;
          },
        );
      },
    );
  }
}

class _NotificationHeroCard extends StatelessWidget {
  const _NotificationHeroCard({
    required this.buildingName,
    required this.totalCount,
    required this.unreadCount,
    required this.canCompose,
    required this.onCompose,
  });

  final String buildingName;
  final int totalCount;
  final int unreadCount;
  final bool canCompose;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Icon(
              Icons.notifications_active_rounded,
              color: Colors.white.withValues(alpha: 0.13),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingName,
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
                          'Trung tam thông báo tòa nhà',
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
                    child: _HeroMetric(
                      label: 'Tất cả',
                      value: totalCount,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      label: 'Chưa đọc',
                      value: unreadCount,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                ],
              ),
              if (canCompose) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onCompose,
                  icon: const Icon(Icons.add_alert_outlined),
                  label: const Text('Gửi thông báo chung'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
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
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
          const SizedBox(height: 8),
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

class _NotificationFilterBar extends StatelessWidget {
  const _NotificationFilterBar({
    required this.selectedFilter,
    required this.onChanged,
  });

  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _NotificationFilterItem(NotificationFilter.all, 'Tất cả'),
      _NotificationFilterItem(NotificationFilter.unread, 'Chưa đọc'),
      _NotificationFilterItem(NotificationFilter.invoice, 'Hóa đơn'),
      _NotificationFilterItem(NotificationFilter.request, 'Yêu cầu'),
      _NotificationFilterItem(NotificationFilter.system, 'Hệ thống'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selectedFilter == filter.value,
                label: Text(filter.label),
                avatar: selectedFilter == filter.value
                    ? const Icon(Icons.check_rounded, size: 18)
                    : null,
                onSelected: (_) => onChanged(filter.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final AppNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = notification.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isRead ? AppColors.border : color.withValues(alpha: 0.36),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isRead ? 0.04 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(notification.icon, color: color, size: 27),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _NotificationTag(
                          label: notification.typeLabel,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        if (!isRead) const _UnreadBadge(),
                        const Spacer(),
                        Text(
                          notification.timeLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          notification.audienceLabel,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  const _NotificationTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
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

class _NotificationDetailScreen extends StatelessWidget {
  const _NotificationDetailScreen({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final color = notification.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(notification.icon, color: Colors.white, size: 31),
                ),
                const SizedBox(height: 18),
                Text(
                  notification.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${notification.typeLabel} - ${notification.audienceLabel}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nội dung',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
                const SizedBox(height: 18),
                _DetailRow(
                  label: 'Người gửi',
                  value: notification.createdByName,
                ),
                _DetailRow(label: 'Thời gian', value: notification.timeLabel),
                _DetailRow(label: 'Phạm vi', value: notification.audienceLabel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 94,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationComposerSheet extends StatefulWidget {
  const _NotificationComposerSheet({
    required this.buildingName,
    required this.isLoading,
    required this.onSubmit,
  });

  final String buildingName;
  final bool isLoading;
  final Future<bool> Function({
    required String title,
    required String body,
    required String type,
    required String audience,
  }) onSubmit;

  @override
  State<_NotificationComposerSheet> createState() =>
      _NotificationComposerSheetState();
}

class _NotificationComposerSheetState
    extends State<_NotificationComposerSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = NotificationType.announcement;
  String _selectedAudience = NotificationAudience.building;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gửi thông báo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.buildingName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề',
                hintText: 'Ví dụ: Bảo trì thang máy',
                prefixIcon: Icon(Icons.title_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Nội dung',
                hintText: 'Nhập nội dung thông báo...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            const _SheetLabel('Loai thông báo'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ComposerChip(
                  label: 'Thông báo',
                  selected: _selectedType == NotificationType.announcement,
                  onTap: () => setState(
                    () => _selectedType = NotificationType.announcement,
                  ),
                ),
                _ComposerChip(
                  label: 'Hóa đơn',
                  selected: _selectedType == NotificationType.invoice,
                  onTap: () => setState(
                    () => _selectedType = NotificationType.invoice,
                  ),
                ),
                _ComposerChip(
                  label: 'Hệ thống',
                  selected: _selectedType == NotificationType.system,
                  onTap: () =>
                      setState(() => _selectedType = NotificationType.system),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SheetLabel('Người nhận'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ComposerChip(
                  label: 'Toàn tòa nhà',
                  selected: _selectedAudience == NotificationAudience.building,
                  onTap: () => setState(
                    () => _selectedAudience = NotificationAudience.building,
                  ),
                ),
                _ComposerChip(
                  label: 'Người thuê',
                  selected: _selectedAudience == NotificationAudience.tenants,
                  onTap: () => setState(
                    () => _selectedAudience = NotificationAudience.tenants,
                  ),
                ),
                _ComposerChip(
                  label: 'Nhân sự',
                  selected: _selectedAudience == NotificationAudience.staff,
                  onTap: () => setState(
                    () => _selectedAudience = NotificationAudience.staff,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submitting || widget.isLoading ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Gửi thông báo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập tiêu đề và nội dung thông báo.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final created = await widget.onSubmit(
      title: title,
      body: body,
      type: _selectedType,
      audience: _selectedAudience,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã gửi thông báo.')),
      );
    }
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      avatar: selected ? const Icon(Icons.check_rounded, size: 18) : null,
      onSelected: (_) => onTap(),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterItem {
  const _NotificationFilterItem(this.value, this.label);

  final NotificationFilter value;
  final String label;
}

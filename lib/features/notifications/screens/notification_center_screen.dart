import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app_keys.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({
    super.key,
    required this.currentRole,
    required this.title,
    this.canSendReport = false,
  });

  final String currentRole;
  final String title;
  final bool canSendReport;

  static const Color _primaryBlue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('targetRoles', arrayContains: currentRole)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Không tải được thông báo: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final notifications =
              (snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .map((doc) => AppNotification.fromFirestore(doc.data()))
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có thông báo nào.',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _NotificationCard(notification: notifications[index]);
            },
          );
        },
      ),
      floatingActionButton: canSendReport
          ? FloatingActionButton.extended(
              backgroundColor: _primaryBlue,
              onPressed: () => showNotificationComposer(
                context: context,
                senderRole: 'user',
                targetRoles: const ['admin', 'manager'],
                type: 'report',
                title: 'Gửi báo cáo',
                hintText: 'Nhập nội dung báo cáo cho admin và quản lý...',
                successMessage: 'Đã gửi báo cáo.',
              ),
              icon: const Icon(Icons.report, color: Colors.white),
              label: const Text(
                'Báo cáo',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

Future<void> showNotificationComposer({
  required BuildContext context,
  required String senderRole,
  required List<String> targetRoles,
  required String type,
  required String title,
  required String hintText,
  required String successMessage,
}) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => _NotificationComposerScreen(
        senderRole: senderRole,
        targetRoles: targetRoles,
        type: type,
        title: title,
        hintText: hintText,
        successMessage: successMessage,
      ),
    ),
  );
}

class _NotificationComposerScreen extends StatefulWidget {
  const _NotificationComposerScreen({
    required this.senderRole,
    required this.targetRoles,
    required this.type,
    required this.title,
    required this.hintText,
    required this.successMessage,
  });

  final String senderRole;
  final List<String> targetRoles;
  final String type;
  final String title;
  final String hintText;
  final String successMessage;

  @override
  State<_NotificationComposerScreen> createState() =>
      _NotificationComposerScreenState();
}

class _NotificationComposerScreenState
    extends State<_NotificationComposerScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showRootSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung.')),
      );
      return;
    }

    Navigator.of(context).pop();
    _showRootSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Đang gửi thông báo...'),
      ),
    );

    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        return _sendNotification(
          message: message,
          senderRole: widget.senderRole,
          targetRoles: widget.targetRoles,
          type: widget.type,
          successMessage: widget.successMessage,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 6,
              maxLines: 10,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send),
                label: const Text('Gửi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _sendNotification({
  required String message,
  required String senderRole,
  required List<String> targetRoles,
  required String type,
  required String successMessage,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
          'message': message,
          'senderRole': senderRole,
          'senderName': user?.displayName ?? user?.email ?? 'Người dùng',
          'senderEmail': user?.email ?? '',
          'targetRoles': targetRoles,
          'type': type,
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 10));

    _showRootSnackBar(SnackBar(content: Text(successMessage)));
  } on TimeoutException {
    _showRootSnackBar(
      const SnackBar(
        content: Text(
          'Gửi quá lâu. Kiểm tra mạng hoặc quyền ghi Firestore.',
        ),
      ),
    );
  } catch (e) {
    _showRootSnackBar(SnackBar(content: Text('Không gửi được: $e')));
  }
}

void _showRootSnackBar(SnackBar snackBar) {
  rootScaffoldMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}

class AppNotification {
  const AppNotification({
    required this.message,
    required this.senderRole,
    required this.senderName,
    required this.type,
    required this.createdAt,
  });

  final String message;
  final String senderRole;
  final String senderName;
  final String type;
  final DateTime createdAt;

  factory AppNotification.fromFirestore(Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return AppNotification(
      message: (data['message'] ?? '').toString(),
      senderRole: (data['senderRole'] ?? '').toString(),
      senderName: (data['senderName'] ?? 'Người dùng').toString(),
      type: (data['type'] ?? 'notice').toString(),
      createdAt: timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String get senderLabel {
    switch (senderRole) {
      case 'manager':
        return 'Quản lý';
      case 'user':
        return 'Người thuê';
      case 'admin':
        return 'Admin';
      default:
        return 'Hệ thống';
    }
  }

  Color get color {
    return type == 'report' ? Colors.deepOrange : _NotificationCard._primaryBlue;
  }

  IconData get icon {
    return type == 'report' ? Icons.report : Icons.notifications;
  }

  String get timeLabel {
    if (createdAt.millisecondsSinceEpoch == 0) return 'Mới';
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  static const Color _primaryBlue = Color(0xFF1565C0);
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: notification.color.withValues(alpha: 0.12),
            child: Icon(notification.icon, color: notification.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${notification.senderLabel}: ${notification.senderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            notification.timeLabel,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

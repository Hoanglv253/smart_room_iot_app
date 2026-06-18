import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.buildingId,
    required this.title,
    required this.body,
    required this.type,
    required this.audience,
    required this.createdBy,
    required this.createdByName,
    required this.recipientIds,
    required this.readBy,
    required this.roomId,
    required this.targetId,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AppNotification(
      id: doc.id,
      buildingId: (data['buildingId'] ?? '').toString(),
      title: _text(data['title'], 'Thông báo mới'),
      body: _text(data['body'], 'Chưa có nội dung.'),
      type: (data['type'] ?? NotificationType.announcement).toString(),
      audience: (data['audience'] ?? NotificationAudience.building).toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdByName: _text(data['createdByName'], 'Quản lý tòa nhà'),
      recipientIds: _readStringList(data['recipientIds']),
      readBy: _readStringList(data['readBy']),
      roomId: (data['roomId'] ?? '').toString(),
      targetId: (data['targetId'] ?? '').toString(),
      createdAt: data['createdAt'],
    );
  }

  final String id;
  final String buildingId;
  final String title;
  final String body;
  final String type;
  final String audience;
  final String createdBy;
  final String createdByName;
  final List<String> recipientIds;
  final List<String> readBy;
  final String roomId;
  final String targetId;
  final Object? createdAt;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool get isUnread => readBy.isEmpty;

  IconData get icon {
    return switch (type) {
      NotificationType.invoice => Icons.receipt_long_outlined,
      NotificationType.request => Icons.person_add_alt_1_outlined,
      NotificationType.payment => Icons.payments_outlined,
      NotificationType.system => Icons.settings_suggest_outlined,
      _ => Icons.campaign_outlined,
    };
  }

  Color get color {
    return switch (type) {
      NotificationType.invoice => const Color(0xFFF59E0B),
      NotificationType.request => const Color(0xFF22C55E),
      NotificationType.payment => const Color(0xFF0EA5E9),
      NotificationType.system => const Color(0xFF64748B),
      _ => const Color(0xFF2168F3),
    };
  }

  String get typeLabel {
    return switch (type) {
      NotificationType.invoice => 'Hóa đơn',
      NotificationType.request => 'Yêu cầu',
      NotificationType.payment => 'Thanh toán',
      NotificationType.system => 'Hệ thống',
      _ => 'Thông báo',
    };
  }

  String get audienceLabel {
    return switch (audience) {
      NotificationAudience.tenants => 'Người thuê',
      NotificationAudience.staff => 'Nhân sự',
      NotificationAudience.room => 'Phòng',
      _ => 'Toàn tòa nhà',
    };
  }

  DateTime? get createdDate {
    final value = createdAt;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String get timeLabel {
    final date = createdDate;
    if (date == null) return 'Vừa xong';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get dayLabel {
    final date = createdDate;
    if (date == null) return 'Mới nhất';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(itemDay).inDays;

    if (diff == 0) return 'Hom này';
    if (diff == 1) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
  }

  bool visibleFor({
    required String userId,
    required String role,
    required String? roomId,
  }) {
    if (recipientIds.contains(userId)) return true;
    if (role == UserRole.admin) return true;

    if (role == UserRole.manager) return true;

    if (audience == NotificationAudience.staff) return false;
    if (audience == NotificationAudience.room) {
      return this.roomId.isNotEmpty && this.roomId == roomId;
    }

    return audience == NotificationAudience.building ||
        audience == NotificationAudience.tenants;
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static List<String> _readStringList(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}

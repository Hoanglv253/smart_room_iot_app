import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';

class NotificationRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> buildingNotifications(
    String buildingId,
  ) {
    return AppFirestoreService.notifications
        .where('buildingId', isEqualTo: buildingId)
        .snapshots();
  }

  Future<void> createBuildingNotification({
    required String buildingId,
    required String title,
    required String body,
    required String type,
    required String audience,
    required String createdBy,
    required String createdByName,
    String roomId = '',
    String targetId = '',
    List<String> recipientIds = const [],
  }) {
    return AppFirestoreService.notifications.add({
      'buildingId': buildingId,
      'title': title,
      'body': body,
      'type': type,
      'audience': audience,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'roomId': roomId,
      'targetId': targetId,
      'recipientIds': recipientIds,
      'readBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAsRead({
    required String notificationId,
    required String userId,
  }) {
    return AppFirestoreService.notifications.doc(notificationId).update({
      'readBy': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

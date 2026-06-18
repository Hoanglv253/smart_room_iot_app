import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

enum NotificationFilter {
  all,
  unread,
  invoice,
  request,
  system,
}

class NotificationsViewModel extends BaseViewModel {
  NotificationsViewModel({NotificationRepository? notificationRepository})
      : _notificationRepository =
            notificationRepository ?? NotificationRepository();

  final NotificationRepository _notificationRepository;
  NotificationFilter _filter = NotificationFilter.all;

  NotificationFilter get filter => _filter;

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingNotifications(
    String buildingId,
  ) {
    return _notificationRepository.buildingNotifications(buildingId);
  }

  List<AppNotification> visibleNotifications({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String userId,
    required String role,
    String? roomId,
  }) {
    final items = docs
        .map(AppNotification.fromDoc)
        .where(
          (item) => item.visibleFor(
            userId: userId,
            role: role,
            roomId: roomId,
          ),
        )
        .toList();

    items.sort((left, right) {
      final leftDate = left.createdDate;
      final rightDate = right.createdDate;
      if (leftDate == null && rightDate == null) return 0;
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
    return items;
  }

  List<AppNotification> filteredNotifications({
    required List<AppNotification> items,
    required String userId,
  }) {
    return items.where((item) => _matchesFilter(item, userId)).toList();
  }

  int unreadCount(List<AppNotification> items, String userId) {
    return items.where((item) => !item.isReadBy(userId)).length;
  }

  void setFilter(NotificationFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<bool> createNotification({
    required String buildingId,
    required String title,
    required String body,
    required String type,
    required String audience,
    required String createdBy,
    required String createdByName,
  }) {
    return runBusyAction(() {
      return _notificationRepository.createBuildingNotification(
        buildingId: buildingId,
        title: title,
        body: body,
        type: type,
        audience: audience,
        createdBy: createdBy,
        createdByName: createdByName,
      );
    });
  }

  Future<bool> markAsRead({
    required String notificationId,
    required String userId,
  }) {
    return runBusyAction(() {
      return _notificationRepository.markAsRead(
        notificationId: notificationId,
        userId: userId,
      );
    });
  }

  bool _matchesFilter(AppNotification item, String userId) {
    return switch (_filter) {
      NotificationFilter.unread => !item.isReadBy(userId),
      NotificationFilter.invoice => item.type == NotificationType.invoice ||
          item.type == NotificationType.payment,
      NotificationFilter.request => item.type == NotificationType.request,
      NotificationFilter.system => item.type == NotificationType.system,
      _ => true,
    };
  }
}

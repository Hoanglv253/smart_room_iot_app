import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';

class FeedRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> publishedBuildings() {
    return AppFirestoreService.buildings
        .where('adPublished', isEqualTo: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingComments({
    required String buildingId,
    required bool showAll,
  }) {
    Query<Map<String, dynamic>> query = AppFirestoreService
        .buildingComments(buildingId)
        .orderBy('createdAt', descending: true);

    if (!showAll) {
      query = query.limit(1);
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingRooms(String buildingId) {
    return AppFirestoreService.buildingRooms(
      buildingId,
    ).orderBy('roomNumber').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usersByRole(String role) {
    return AppFirestoreService.users.where('role', isEqualTo: role).snapshots();
  }

  Future<bool> hasPendingJoinRequest({
    required String buildingId,
    required String requesterId,
  }) async {
    final existing = await AppFirestoreService.joinRequests
        .where('buildingId', isEqualTo: buildingId)
        .where('requesterId', isEqualTo: requesterId)
        .where('status', isEqualTo: JoinRequestStatus.pending)
        .limit(1)
        .get();

    return existing.docs.isNotEmpty;
  }

  Future<void> createJoinRequest({
    required String buildingId,
    required Map<String, dynamic> building,
    required User user,
    required String role,
  }) async {
    await AppFirestoreService.joinRequests.add({
      'buildingId': buildingId,
      'buildingName': building['name'] ?? '',
      'adminId': building['adminId'] ?? '',
      'requesterId': user.uid,
      'requesterName': user.displayName ?? user.email ?? 'Người dùng',
      'requesterEmail': user.email ?? '',
      'requesterRole': role,
      'status': JoinRequestStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> findOrCreatePrivateChat({
    required User currentUser,
    required String otherUserId,
    required String otherUserName,
    String? buildingId,
    String? title,
    String? ownerId,
  }) async {
    final existing = await AppFirestoreService.chats
        .where('type', isEqualTo: ChatType.private)
        .where('memberIds', arrayContains: currentUser.uid)
        .get();

    final found = existing.docs.where((doc) {
      final data = doc.data();
      if (data['isDeleted'] == true) return false;
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);
      if (deletedFor.contains(currentUser.uid)) return false;
      final members = List<String>.from(data['memberIds'] ?? []);
      return members.contains(otherUserId);
    }).toList();

    if (found.isNotEmpty) {
      return found.first.id;
    }

    final currentName = currentUser.displayName ?? currentUser.email ?? 'Bạn';
    final chatData = <String, dynamic>{
      'type': ChatType.private,
      'ownerId': ownerId ?? currentUser.uid,
      'title': title ?? '$currentName - $otherUserName',
      'memberIds': [currentUser.uid, otherUserId],
      'deletedFor': [],
      'isDeleted': false,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (buildingId != null) chatData['buildingId'] = buildingId;

    final chatDoc = await AppFirestoreService.chats.add(chatData);

    return chatDoc.id;
  }

  Future<void> sendBuildingComment({
    required String buildingId,
    required User user,
    required String role,
    required String text,
  }) async {
    final authorName = user.displayName ?? user.email ?? 'Người dùng';

    await AppFirestoreService.buildingComments(buildingId).add({
      'authorId': user.uid,
      'authorName': authorName,
      'authorEmail': user.email ?? '',
      'authorRole': role,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

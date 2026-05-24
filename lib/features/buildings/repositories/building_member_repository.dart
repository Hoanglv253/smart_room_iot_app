import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';

class BuildingMemberRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> members(String buildingId) {
    return AppFirestoreService.users
        .where('buildingId', isEqualTo: buildingId)
        .snapshots();
  }

  Future<void> removeMember({
    required String buildingId,
    required String userId,
    required String roomId,
    required String? currentUserId,
  }) async {
    await AppFirestoreService.db.runTransaction((transaction) async {
      final userRef = AppFirestoreService.users.doc(userId);
      final roomRef = roomId.isNotEmpty
          ? AppFirestoreService.buildingRooms(buildingId).doc(roomId)
          : null;
      final roomSnapshot =
          roomRef == null ? null : await transaction.get(roomRef);

      transaction.update(userRef, {
        'buildingId': null,
        'roomId': FieldValue.delete(),
        'roomNumber': FieldValue.delete(),
        'roomName': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (roomRef != null && roomSnapshot?.exists == true) {
        transaction.update(roomRef, {
          'tenantId': FieldValue.delete(),
          'tenantName': FieldValue.delete(),
          'tenantEmail': FieldValue.delete(),
          'status': 'available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    await _removeFromBuildingGroupChat(
      buildingId: buildingId,
      userId: userId,
      currentUserId: currentUserId,
    );
  }

  Future<void> _removeFromBuildingGroupChat({
    required String buildingId,
    required String userId,
    required String? currentUserId,
  }) async {
    if (currentUserId == null) return;

    final query = await AppFirestoreService.chats
        .where('memberIds', arrayContains: currentUserId)
        .get();

    final matchedChats = query.docs.where((doc) {
      final chat = doc.data();
      return chat['type'] == ChatType.group && chat['buildingId'] == buildingId;
    }).toList();

    if (matchedChats.isEmpty) return;

    await matchedChats.first.reference.update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

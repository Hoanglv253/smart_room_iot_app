import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import 'building_member_repository.dart';

class AdminBuildingRepository {
  AdminBuildingRepository({BuildingMemberRepository? memberRepository})
    : _memberRepository = memberRepository ?? BuildingMemberRepository();

  final BuildingMemberRepository _memberRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> adminBuilding(String adminId) {
    return AppFirestoreService.buildings
        .where('adminId', isEqualTo: adminId)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> members(String buildingId) {
    return _memberRepository.members(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingJoinRequests(
    String buildingId,
  ) {
    return AppFirestoreService.joinRequests
        .where('buildingId', isEqualTo: buildingId)
        .where('status', isEqualTo: JoinRequestStatus.pending)
        .snapshots();
  }

  Future<void> approveJoinRequest({
    required String requestId,
    required String requesterId,
    required String buildingId,
  }) {
    return AppFirestoreService.db.runTransaction((transaction) async {
      transaction.update(AppFirestoreService.joinRequests.doc(requestId), {
        'status': JoinRequestStatus.approved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(AppFirestoreService.users.doc(requesterId), {
        'buildingId': buildingId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectJoinRequest(String requestId) {
    return AppFirestoreService.joinRequests.doc(requestId).update({
      'status': JoinRequestStatus.rejected,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureGroupChatMember({
    required String buildingId,
    required String adminId,
    required String requesterId,
    required Map<String, dynamic> requestData,
  }) async {
    final query = await AppFirestoreService.chats
        .where('memberIds', arrayContains: adminId)
        .get();

    final matchedChats = query.docs.where((doc) {
      final chat = doc.data();
      return chat['type'] == ChatType.group && chat['buildingId'] == buildingId;
    }).toList();

    if (matchedChats.isEmpty) {
      await AppFirestoreService.chats.add({
        'type': ChatType.group,
        'buildingId': buildingId,
        'ownerId': adminId,
        'title': (requestData['buildingName'] ?? 'Nhom chat toa nha')
            .toString(),
        'memberIds': [adminId, requesterId],
        'deletedFor': [],
        'isDeleted': false,
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await matchedChats.first.reference.update({
      'memberIds': FieldValue.arrayUnion([requesterId]),
      'deletedFor': FieldValue.arrayRemove([adminId, requesterId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

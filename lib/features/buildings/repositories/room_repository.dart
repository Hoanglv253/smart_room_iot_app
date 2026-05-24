import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';

class RoomRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> rooms(String buildingId) {
    return AppFirestoreService.buildingRooms(
      buildingId,
    ).orderBy('roomNumber').snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return AppFirestoreService.buildingRooms(buildingId).doc(roomId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingUsers(String buildingId) {
    return AppFirestoreService.users
        .where('buildingId', isEqualTo: buildingId)
        .snapshots();
  }

  Future<void> updateRoom({
    required String buildingId,
    required String roomId,
    required String roomName,
    required int roomNumber,
    required int floor,
    required int rent,
    required int area,
    required int maxPeople,
    required String type,
    required String status,
    required String? tenantUserId,
  }) async {
    final batch = AppFirestoreService.db.batch();
    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);

    batch.update(roomRef, {
      'name': roomName,
      'floor': floor,
      'rent': rent,
      'area': area,
      'maxPeople': maxPeople,
      'type': type,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (tenantUserId != null && tenantUserId.isNotEmpty) {
      batch.update(AppFirestoreService.users.doc(tenantUserId), {
        'roomName': roomName,
        'roomNumber': roomNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> removeTenant({
    required String buildingId,
    required String roomId,
    required String tenantId,
  }) async {
    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);
    final tenantRef = AppFirestoreService.users.doc(tenantId);

    await AppFirestoreService.db.runTransaction((transaction) async {
      final tenantSnapshot = await transaction.get(tenantRef);

      transaction.update(roomRef, {
        'tenantId': FieldValue.delete(),
        'tenantName': FieldValue.delete(),
        'tenantEmail': FieldValue.delete(),
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (tenantSnapshot.exists) {
        transaction.update(tenantRef, {
          'roomId': FieldValue.delete(),
          'roomNumber': FieldValue.delete(),
          'roomName': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> assignTenant({
    required String buildingId,
    required String roomId,
    required int roomNumber,
    required String roomName,
    required String? currentTenantId,
    required String tenantId,
    required String tenantName,
    required String tenantEmail,
  }) async {
    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);
    final tenantRef = AppFirestoreService.users.doc(tenantId);

    await AppFirestoreService.db.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final activeTenantId =
          roomSnapshot.data()?['tenantId']?.toString() ?? currentTenantId;

      transaction.update(roomRef, {
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantEmail': tenantEmail,
        'status': 'occupied',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (activeTenantId != null &&
          activeTenantId.isNotEmpty &&
          activeTenantId != tenantId) {
        transaction.update(AppFirestoreService.users.doc(activeTenantId), {
          'roomId': FieldValue.delete(),
          'roomNumber': FieldValue.delete(),
          'roomName': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(tenantRef, {
        'buildingId': buildingId,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'roomName': roomName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

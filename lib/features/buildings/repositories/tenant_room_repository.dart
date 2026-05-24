import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';

class TenantRoomRepository {
  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String userId) {
    return AppFirestoreService.users.doc(userId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return AppFirestoreService.buildings.doc(buildingId).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return AppFirestoreService.buildingRooms(buildingId).doc(roomId).snapshots();
  }
}

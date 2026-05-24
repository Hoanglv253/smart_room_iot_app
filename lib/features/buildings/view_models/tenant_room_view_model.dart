import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/tenant_room_repository.dart';

class TenantRoomViewModel extends BaseViewModel {
  TenantRoomViewModel({TenantRoomRepository? tenantRoomRepository})
    : _tenantRoomRepository = tenantRoomRepository ?? TenantRoomRepository();

  final TenantRoomRepository _tenantRoomRepository;

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String userId) {
    return _tenantRoomRepository.userProfile(userId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return _tenantRoomRepository.building(buildingId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return _tenantRoomRepository.room(buildingId: buildingId, roomId: roomId);
  }
}

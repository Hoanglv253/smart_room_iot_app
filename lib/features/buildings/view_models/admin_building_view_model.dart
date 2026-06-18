import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../repositories/admin_building_repository.dart';

enum JoinRequestApprovalResult {
  approved,
  approvedWithoutGroupChat,
  failed,
}

class AdminBuildingViewModel extends BaseViewModel {
  AdminBuildingViewModel({AdminBuildingRepository? buildingRepository})
    : _buildingRepository = buildingRepository ?? AdminBuildingRepository();

  final AdminBuildingRepository _buildingRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> adminBuilding(String adminId) {
    return _buildingRepository.adminBuilding(adminId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> members(String buildingId) {
    return _buildingRepository.members(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> rooms(String buildingId) {
    return _buildingRepository.rooms(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> invoices(String buildingId) {
    return _buildingRepository.invoices(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingJoinRequests(
    String buildingId,
  ) {
    return _buildingRepository.pendingJoinRequests(buildingId);
  }

  int tenantCount(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) => doc.data()['role'] == UserRole.user).length;
  }

  Future<JoinRequestApprovalResult> approveJoinRequest({
    required String requestId,
    required String buildingId,
    required String adminId,
    required Map<String, dynamic> requestData,
  }) async {
    final requesterId = (requestData['requesterId'] ?? '').toString();
    if (requesterId.isEmpty) return JoinRequestApprovalResult.failed;

    clearError();

    try {
      await _buildingRepository.approveJoinRequest(
        requestId: requestId,
        requesterId: requesterId,
        buildingId: buildingId,
      );
    } catch (error) {
      setError(error.toString());
      return JoinRequestApprovalResult.failed;
    }

    try {
      await _buildingRepository.ensureGroupChatMember(
        buildingId: buildingId,
        adminId: adminId,
        requesterId: requesterId,
        requestData: requestData,
      );
      return JoinRequestApprovalResult.approved;
    } catch (error) {
      setError(error.toString());
      return JoinRequestApprovalResult.approvedWithoutGroupChat;
    }
  }

  Future<bool> rejectJoinRequest(String requestId) {
    return runBusyAction(() {
      return _buildingRepository.rejectJoinRequest(requestId);
    });
  }
}

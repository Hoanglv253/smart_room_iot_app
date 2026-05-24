import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/building_member_repository.dart';

class AdminUserManagementViewModel extends BaseViewModel {
  AdminUserManagementViewModel({
    BuildingMemberRepository? memberRepository,
  }) : _memberRepository = memberRepository ?? BuildingMemberRepository();

  final BuildingMemberRepository _memberRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> members(String buildingId) {
    return _memberRepository.members(buildingId);
  }
}

class AdminMemberProfileViewModel extends BaseViewModel {
  AdminMemberProfileViewModel({
    BuildingMemberRepository? memberRepository,
    FirebaseAuth? firebaseAuth,
  })  : _memberRepository = memberRepository ?? BuildingMemberRepository(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final BuildingMemberRepository _memberRepository;
  final FirebaseAuth _firebaseAuth;

  Future<bool> removeFromBuilding({
    required String buildingId,
    required String userId,
    required String roomId,
  }) {
    return runBusyAction(() {
      return _memberRepository.removeMember(
        buildingId: buildingId,
        userId: userId,
        roomId: roomId,
        currentUserId: _firebaseAuth.currentUser?.uid,
      );
    });
  }
}

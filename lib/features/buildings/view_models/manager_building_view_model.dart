import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../repositories/building_member_repository.dart';
import '../repositories/invoice_repository.dart';
import '../repositories/room_repository.dart';
import '../repositories/tenant_room_repository.dart';

class ManagerBuildingViewModel extends BaseViewModel {
  ManagerBuildingViewModel({
    TenantRoomRepository? tenantRoomRepository,
    BuildingMemberRepository? memberRepository,
    RoomRepository? roomRepository,
    InvoiceRepository? invoiceRepository,
  })  : _tenantRoomRepository = tenantRoomRepository ?? TenantRoomRepository(),
        _memberRepository = memberRepository ?? BuildingMemberRepository(),
        _roomRepository = roomRepository ?? RoomRepository(),
        _invoiceRepository = invoiceRepository ?? InvoiceRepository();

  final TenantRoomRepository _tenantRoomRepository;
  final BuildingMemberRepository _memberRepository;
  final RoomRepository _roomRepository;
  final InvoiceRepository _invoiceRepository;

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String userId) {
    return _tenantRoomRepository.userProfile(userId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return _tenantRoomRepository.building(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> members(String buildingId) {
    return _memberRepository.members(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> rooms(String buildingId) {
    return _roomRepository.rooms(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> invoices(String buildingId) {
    return _invoiceRepository.buildingInvoices(buildingId);
  }

  int tenantCount(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.where((doc) => doc.data()['role'] == UserRole.user).length;
  }
}

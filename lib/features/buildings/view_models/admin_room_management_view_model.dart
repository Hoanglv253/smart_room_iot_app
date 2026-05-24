import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/room_repository.dart';

class AdminRoomManagementViewModel extends BaseViewModel {
  AdminRoomManagementViewModel({RoomRepository? roomRepository})
    : _roomRepository = roomRepository ?? RoomRepository();

  final RoomRepository _roomRepository;
  String _query = '';

  String get query => _query;

  Stream<QuerySnapshot<Map<String, dynamic>>> rooms(String buildingId) {
    return _roomRepository.rooms(buildingId);
  }

  void setQuery(String value) {
    final nextQuery = value.trim().toLowerCase();
    if (_query == nextQuery) return;
    _query = nextQuery;
    notifyListeners();
  }
}

class RoomDetailViewModel extends BaseViewModel {
  RoomDetailViewModel({RoomRepository? roomRepository})
    : _roomRepository = roomRepository ?? RoomRepository();

  final RoomRepository _roomRepository;
  String _status = 'available';

  String get status => _status;

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return _roomRepository.room(buildingId: buildingId, roomId: roomId);
  }

  void setStatus(String value) {
    if (_status == value) return;
    _status = value;
    notifyListeners();
  }

  void loadStatus({
    required String status,
    required Iterable<String> allowedStatuses,
  }) {
    final nextStatus = allowedStatuses.contains(status) ? status : 'available';
    if (_status == nextStatus) return;
    _status = nextStatus;
    notifyListeners();
  }

  Future<bool> saveRoom({
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
  }) {
    final hasTenant = tenantUserId != null && tenantUserId.isNotEmpty;
    final statusToSave = hasTenant && status == 'available'
        ? 'occupied'
        : status;

    return runBusyAction(() {
      return _roomRepository.updateRoom(
        buildingId: buildingId,
        roomId: roomId,
        roomName: roomName,
        roomNumber: roomNumber,
        floor: floor,
        rent: rent,
        area: area,
        maxPeople: maxPeople,
        type: type,
        status: statusToSave,
        tenantUserId: tenantUserId,
      );
    });
  }

  Future<bool> removeTenant({
    required String buildingId,
    required String roomId,
    required String tenantId,
  }) {
    return runBusyAction(() {
      return _roomRepository.removeTenant(
        buildingId: buildingId,
        roomId: roomId,
        tenantId: tenantId,
      );
    });
  }
}

class TenantPickerViewModel extends BaseViewModel {
  TenantPickerViewModel({RoomRepository? roomRepository})
    : _roomRepository = roomRepository ?? RoomRepository();

  final RoomRepository _roomRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingUsers(String buildingId) {
    return _roomRepository.buildingUsers(buildingId);
  }

  Future<bool> assignTenant({
    required String buildingId,
    required String roomId,
    required int roomNumber,
    required String roomName,
    required String? currentTenantId,
    required String tenantId,
    required String tenantName,
    required String tenantEmail,
  }) {
    return runBusyAction(() {
      return _roomRepository.assignTenant(
        buildingId: buildingId,
        roomId: roomId,
        roomNumber: roomNumber,
        roomName: roomName,
        currentTenantId: currentTenantId,
        tenantId: tenantId,
        tenantName: tenantName,
        tenantEmail: tenantEmail,
      );
    });
  }
}

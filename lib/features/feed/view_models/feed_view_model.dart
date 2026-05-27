import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/feed_repository.dart';

enum FeedFilter { buildings, managers, tenants }

enum BuildingAvailabilityFilter { all, available }

enum BuildingPriceFilter { all, under2m, from2mTo4m, above4m }

enum BuildingSortOption { newest, priceAsc, priceDesc }

class FeedViewModel extends BaseViewModel {
  FeedViewModel({FeedRepository? feedRepository})
    : _feedRepository = feedRepository ?? FeedRepository();

  final FeedRepository _feedRepository;
  FeedFilter _filter = FeedFilter.buildings;
  BuildingAvailabilityFilter _availabilityFilter =
      BuildingAvailabilityFilter.all;
  BuildingPriceFilter _priceFilter = BuildingPriceFilter.all;
  String _provinceFilter = '';
  String _wardFilter = '';
  BuildingSortOption _sortOption = BuildingSortOption.newest;
  String _query = '';

  FeedFilter get filter => _filter;
  BuildingAvailabilityFilter get availabilityFilter => _availabilityFilter;
  BuildingPriceFilter get priceFilter => _priceFilter;
  String get provinceFilter => _provinceFilter;
  String get wardFilter => _wardFilter;
  BuildingSortOption get sortOption => _sortOption;
  String get query => _query;
  bool get hasBuildingFilters =>
      _availabilityFilter != BuildingAvailabilityFilter.all ||
      _priceFilter != BuildingPriceFilter.all ||
      _provinceFilter.isNotEmpty ||
      _wardFilter.isNotEmpty ||
      _sortOption != BuildingSortOption.newest;

  void setFilter(FeedFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void setQuery(String value) {
    final normalized = value.trim().toLowerCase();
    if (_query == normalized) return;
    _query = normalized;
    notifyListeners();
  }

  void setAvailabilityFilter(BuildingAvailabilityFilter filter) {
    if (_availabilityFilter == filter) return;
    _availabilityFilter = filter;
    notifyListeners();
  }

  void setPriceFilter(BuildingPriceFilter filter) {
    if (_priceFilter == filter) return;
    _priceFilter = filter;
    notifyListeners();
  }

  void setProvinceFilter(String value) {
    final normalized = value.trim();
    if (_provinceFilter == normalized) return;
    _provinceFilter = normalized;
    notifyListeners();
  }

  void setWardFilter(String value) {
    final normalized = value.trim();
    if (_wardFilter == normalized) return;
    _wardFilter = normalized;
    notifyListeners();
  }

  void setSortOption(BuildingSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    notifyListeners();
  }

  void resetBuildingFilters() {
    if (!hasBuildingFilters) return;
    _availabilityFilter = BuildingAvailabilityFilter.all;
    _priceFilter = BuildingPriceFilter.all;
    _provinceFilter = '';
    _wardFilter = '';
    _sortOption = BuildingSortOption.newest;
    notifyListeners();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> publishedBuildings() {
    return _feedRepository.publishedBuildings();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingComments({
    required String buildingId,
    required bool showAll,
  }) {
    return _feedRepository.buildingComments(
      buildingId: buildingId,
      showAll: showAll,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingRooms(String buildingId) {
    return _feedRepository.buildingRooms(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> usersByRole(String role) {
    return _feedRepository.usersByRole(role);
  }

  Future<bool> requestJoin({
    required String buildingId,
    required Map<String, dynamic> building,
    required User user,
    required String role,
  }) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) {
      setError('Không tìm thấy admin của tòa nhà.');
      return false;
    }

    bool alreadyPending;
    try {
      alreadyPending = await _feedRepository.hasPendingJoinRequest(
        buildingId: buildingId,
        requesterId: user.uid,
      );
    } catch (error) {
      setError(error.toString());
      return false;
    }
    if (alreadyPending) {
      setError('Bạn đã gửi yêu cầu trước đó.');
      return false;
    }

    return runBusyAction(
      () => _feedRepository.createJoinRequest(
        buildingId: buildingId,
        building: building,
        user: user,
        role: role,
      ),
    );
  }

  Future<String?> findOrCreatePrivateChat({
    required User currentUser,
    required String otherUserId,
    required String otherUserName,
    String? buildingId,
    String? title,
    String? ownerId,
  }) {
    return runBusyTask(
      () => _feedRepository.findOrCreatePrivateChat(
        currentUser: currentUser,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        buildingId: buildingId,
        title: title,
        ownerId: ownerId,
      ),
    );
  }

  Future<bool> sendBuildingComment({
    required String buildingId,
    required User user,
    required String role,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading) return Future.value(false);

    return runBusyAction(
      () => _feedRepository.sendBuildingComment(
        buildingId: buildingId,
        user: user,
        role: role,
        text: trimmed,
      ),
    );
  }
}

import '../../../core/view_models/base_view_model.dart';
import '../repositories/settings_repository.dart';

enum AdminSettingsSaveStatus {
  saved,
  savedWithoutRooms,
  savedWithoutChat,
  failed,
}

class AdminSettingsLoadResult {
  const AdminSettingsLoadResult({
    required this.buildingId,
    required this.data,
  });

  final String? buildingId;
  final Map<String, dynamic> data;
}

class AdminSettingsSaveResult {
  const AdminSettingsSaveResult({
    required this.status,
    required this.buildingId,
  });

  final AdminSettingsSaveStatus status;
  final String? buildingId;
}

class AdminSettingsViewModel extends BaseViewModel {
  AdminSettingsViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;

  Future<AdminSettingsLoadResult?> loadBuilding(String adminId) async {
    clearError();

    try {
      final query = await _settingsRepository.adminBuilding(adminId);
      if (query.docs.isEmpty) {
        return const AdminSettingsLoadResult(buildingId: null, data: {});
      }

      final doc = query.docs.first;
      return AdminSettingsLoadResult(buildingId: doc.id, data: doc.data());
    } catch (error) {
      setError(error.toString());
      return null;
    }
  }

  Future<AdminSettingsSaveResult> saveBuilding({
    required String? buildingId,
    required Map<String, dynamic> data,
    required String userId,
    required String buildingName,
    required int totalRooms,
    required int floorCount,
    required int roomsPerFloor,
    required int defaultRent,
    required bool autoJoinGroupChat,
  }) async {
    clearError();

    String savedBuildingId;
    try {
      savedBuildingId = await _settingsRepository.saveBuilding(
        buildingId: buildingId,
        data: data,
      );
    } catch (error) {
      setError(error.toString());
      return const AdminSettingsSaveResult(
        status: AdminSettingsSaveStatus.failed,
        buildingId: null,
      );
    }

    try {
      await _settingsRepository.syncRooms(
        buildingId: savedBuildingId,
        totalRooms: totalRooms,
        floorCount: floorCount,
        roomsPerFloor: roomsPerFloor,
        defaultRent: defaultRent,
      );
    } catch (error) {
      setError(error.toString());
      return AdminSettingsSaveResult(
        status: AdminSettingsSaveStatus.savedWithoutRooms,
        buildingId: savedBuildingId,
      );
    }

    if (autoJoinGroupChat) {
      try {
        await _settingsRepository.ensureBuildingGroupChat(
          buildingId: savedBuildingId,
          userId: userId,
          buildingName: buildingName,
        );
      } catch (error) {
        setError(error.toString());
        return AdminSettingsSaveResult(
          status: AdminSettingsSaveStatus.savedWithoutChat,
          buildingId: savedBuildingId,
        );
      }
    }

    return AdminSettingsSaveResult(
      status: AdminSettingsSaveStatus.saved,
      buildingId: savedBuildingId,
    );
  }

  Future<Map<String, dynamic>?> loadPayosSettings({
    required String backendBaseUrl,
    required String idToken,
    required String buildingId,
  }) async {
    clearError();

    try {
      return await _settingsRepository.loadBuildingPayosSettings(
        backendBaseUrl: backendBaseUrl,
        idToken: idToken,
        buildingId: buildingId,
      );
    } catch (error) {
      setError(error.toString());
      return null;
    }
  }

  Future<Map<String, dynamic>?> savePayosSettings({
    required String backendBaseUrl,
    required String idToken,
    required String buildingId,
    required String clientId,
    required String apiKey,
    required String checksumKey,
  }) async {
    clearError();

    try {
      return await _settingsRepository.saveBuildingPayosSettings(
        backendBaseUrl: backendBaseUrl,
        idToken: idToken,
        buildingId: buildingId,
        clientId: clientId,
        apiKey: apiKey,
        checksumKey: checksumKey,
      );
    } catch (error) {
      setError(error.toString());
      return null;
    }
  }
}

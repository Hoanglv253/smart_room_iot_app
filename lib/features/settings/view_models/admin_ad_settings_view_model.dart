import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/settings_repository.dart';

class AdminAdSettingsViewModel extends BaseViewModel {
  AdminAdSettingsViewModel({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;
  final ImagePicker _imagePicker = ImagePicker();

  Stream<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return _settingsRepository.building(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingRooms(String buildingId) {
    return _settingsRepository.buildingRooms(buildingId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return _settingsRepository.room(buildingId: buildingId, roomId: roomId);
  }

  Future<bool> publishAd({
    required String buildingId,
    required String userId,
  }) {
    return runBusyAction(() {
      return _settingsRepository.publishBuildingAd(
        buildingId: buildingId,
        userId: userId,
      );
    });
  }

  Future<bool?> pickAndUploadRoomImage({
    required String buildingId,
    required String roomId,
  }) async {
    clearError();

    late final XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );
    } catch (error) {
      setError(error.toString());
      return false;
    }

    final selectedImage = image;
    if (selectedImage == null) return null;

    return runBusyAction(() async {
      await _settingsRepository.uploadRoomImage(
        buildingId: buildingId,
        roomId: roomId,
        image: selectedImage,
      );
    });
  }

  Future<bool> setCoverImage({
    required String buildingId,
    required String roomId,
    required String imageUrl,
  }) {
    return runBusyAction(() {
      return _settingsRepository.setRoomCoverImage(
        buildingId: buildingId,
        roomId: roomId,
        imageUrl: imageUrl,
      );
    });
  }

  Future<bool> deleteRoomImage({
    required String buildingId,
    required String roomId,
    required String imageUrl,
  }) {
    return runBusyAction(() {
      return _settingsRepository.deleteRoomImage(
        buildingId: buildingId,
        roomId: roomId,
        imageUrl: imageUrl,
      );
    });
  }
}

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

  Future<bool> publishAd({required String buildingId, required String userId}) {
    return runBusyAction(() {
      return _settingsRepository.publishBuildingAd(
        buildingId: buildingId,
        userId: userId,
      );
    });
  }

  Future<int?> pickAndUploadRoomImages({
    required String buildingId,
    required String roomId,
  }) async {
    clearError();

    late final List<XFile> images;
    try {
      images = await _imagePicker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1800,
      );
    } catch (error) {
      setError(error.toString());
      return 0;
    }

    final selectedImages = images;
    if (selectedImages.isEmpty) return null;

    final uploadedUrls = <String>[];
    final uploaded = await runBusyAction(() async {
      uploadedUrls.addAll(await _settingsRepository.uploadRoomImages(
        buildingId: buildingId,
        roomId: roomId,
        images: selectedImages,
      ));
    });
    return uploaded ? uploadedUrls.length : 0;
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

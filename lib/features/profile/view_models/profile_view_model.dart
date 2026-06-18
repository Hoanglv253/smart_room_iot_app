import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/profile_repository.dart';

class ProfileViewModel extends BaseViewModel {
  ProfileViewModel({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository();

  final ProfileRepository _profileRepository;

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile(String uid) {
    return _profileRepository.userProfile(uid);
  }

  Future<bool> saveProfile({
    required User user,
    required String name,
    required String phone,
    required String bio,
    required String address,
    required String avatarUrl,
  }) {
    return runBusyAction(
      () => _profileRepository.updateCurrentUserProfile(
        user: user,
        name: name,
        phone: phone,
        bio: bio,
        address: address,
        avatarUrl: avatarUrl,
      ),
    );
  }

  Future<String?> uploadAvatarImage({
    required User user,
    required XFile image,
  }) {
    return runBusyTask(
      () => _profileRepository.uploadAvatarImage(
        uid: user.uid,
        image: image,
      ),
    );
  }
}

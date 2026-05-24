import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';

class ProfileRepository {
  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfile(String uid) {
    return AppFirestoreService.users.doc(uid).snapshots();
  }

  Future<void> updateCurrentUserProfile({
    required User user,
    required String name,
    required String phone,
    required String bio,
    required String address,
    required String avatarUrl,
  }) async {
    final cleanName = name.trim();
    final cleanAvatarUrl = avatarUrl.trim();

    if (cleanName.isNotEmpty && cleanName != user.displayName) {
      await user.updateDisplayName(cleanName);
    }

    if (cleanAvatarUrl != (user.photoURL ?? '')) {
      await user.updatePhotoURL(cleanAvatarUrl.isEmpty ? null : cleanAvatarUrl);
    }

    await AppFirestoreService.users.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'name': cleanName,
      'displayName': cleanName,
      'phone': phone.trim(),
      'bio': bio.trim(),
      'address': address.trim(),
      'avatarUrl': cleanAvatarUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

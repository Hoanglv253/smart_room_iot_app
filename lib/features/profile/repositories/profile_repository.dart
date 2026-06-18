import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<String> uploadAvatarImage({
    required String uid,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final fileName = _safeStorageFileName(image.name);
    final uploadedAt = DateTime.now().microsecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child('avatar')
        .child('${uploadedAt}_$fileName');

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _imageContentType(fileName),
        customMetadata: {
          'uid': uid,
          'originalName': fileName,
        },
      ),
    );

    final snapshot = await uploadTask.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('Kết nối Firebase Storage quá lâu.');
      },
    );

    return _downloadUrlWithRetry(snapshot.ref);
  }

  static Future<String> _downloadUrlWithRetry(Reference ref) async {
    FirebaseException? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (error) {
        lastError = error;
        if (error.code != 'object-not-found') rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }

    throw lastError ?? Exception('Không lấy được link ảnh Firebase Storage.');
  }

  static String _safeStorageFileName(String name) {
    final clean = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return clean.isEmpty ? 'avatar.jpg' : clean;
  }

  static String _imageContentType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.gif')) return 'image/gif';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    if (lowerName.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}

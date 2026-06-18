import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/app_firestore_service.dart';

class SettingsRepository {
  Future<QuerySnapshot<Map<String, dynamic>>> adminBuilding(String adminId) {
    return AppFirestoreService.buildings
        .where('adminId', isEqualTo: adminId)
        .limit(1)
        .get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return AppFirestoreService.buildings.doc(buildingId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingRooms(String buildingId) {
    return AppFirestoreService.buildingRooms(
      buildingId,
    ).orderBy('roomNumber').snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> room({
    required String buildingId,
    required String roomId,
  }) {
    return AppFirestoreService.buildingRooms(buildingId).doc(roomId).snapshots();
  }

  Future<void> publishBuildingAd({
    required String buildingId,
    required String userId,
  }) {
    return AppFirestoreService.buildings.doc(buildingId).update({
      'adPublished': true,
      'adPublishedBy': userId,
      'adUpdatedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> uploadRoomImages({
    required String buildingId,
    required String roomId,
    required List<XFile> images,
  }) async {
    if (images.isEmpty) return const [];

    final urls = <String>[];
    for (final image in images) {
      final url = await _uploadImageToFirebaseStorage(
        buildingId: buildingId,
        roomId: roomId,
        image: image,
      );
      urls.add(url);
    }

    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);

    try {
      await AppFirestoreService.db.runTransaction((transaction) async {
        final snapshot = await transaction.get(roomRef);
        final room = snapshot.data() ?? {};
        final currentCover = (room['coverImageUrl'] ?? '').toString().trim();

        transaction.set(roomRef, {
          'imageUrls': FieldValue.arrayUnion(urls),
          if (currentCover.isEmpty) 'coverImageUrl': urls.first,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      for (final url in urls) {
        await _deleteFirebaseStorageImage(url);
      }
      rethrow;
    }

    return urls;
  }

  Future<String> uploadRoomImage({
    required String buildingId,
    required String roomId,
    required XFile image,
  }) async {
    final urls = await uploadRoomImages(
      buildingId: buildingId,
      roomId: roomId,
      images: [image],
    );
    return urls.first;
  }

  Future<void> setRoomCoverImage({
    required String buildingId,
    required String roomId,
    required String imageUrl,
  }) {
    return AppFirestoreService.buildingRooms(buildingId).doc(roomId).update({
      'coverImageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRoomImage({
    required String buildingId,
    required String roomId,
    required String imageUrl,
  }) async {
    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);

    await AppFirestoreService.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final room = snapshot.data() ?? {};
      final imageUrls = _stringList(room['imageUrls']);
      final remaining = imageUrls.where((url) => url != imageUrl).toList();
      final currentCover = (room['coverImageUrl'] ?? '').toString();

      transaction.update(roomRef, {
        'imageUrls': FieldValue.arrayRemove([imageUrl]),
        'coverImageUrl': currentCover == imageUrl
            ? (remaining.isEmpty ? FieldValue.delete() : remaining.first)
            : currentCover,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _deleteFirebaseStorageImage(imageUrl);
  }

  Future<String> saveBuilding({
    required String? buildingId,
    required Map<String, dynamic> data,
  }) async {
    final isNewBuilding = buildingId == null;
    final doc = isNewBuilding
        ? AppFirestoreService.buildings.doc()
        : AppFirestoreService.buildings.doc(buildingId);

    await doc.set({
      ...data,
      'id': doc.id,
      if (isNewBuilding) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return doc.id;
  }

  Future<Map<String, dynamic>> resolveBuildingLocation(String address) async {
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) return {};
    return {
      'address': trimmedAddress,
      'query': trimmedAddress,
      'source': 'address_only',
    };
  }

  Future<void> syncRooms({
    required String buildingId,
    required int totalRooms,
    required int floorCount,
    required int roomsPerFloor,
    required int defaultRent,
  }) async {
    if (totalRooms <= 0) return;

    final rooms = AppFirestoreService.buildingRooms(buildingId);
    final effectiveRoomsPerFloor = roomsPerFloor > 0
        ? roomsPerFloor
        : (floorCount > 0 ? (totalRooms / floorCount).ceil() : totalRooms);

    var batch = AppFirestoreService.db.batch();
    var operationCount = 0;

    Future<void> commitBatch() async {
      if (operationCount == 0) return;
      await batch.commit();
      batch = AppFirestoreService.db.batch();
      operationCount = 0;
    }

    for (var index = 1; index <= totalRooms; index++) {
      final floor = effectiveRoomsPerFloor > 0
          ? ((index - 1) ~/ effectiveRoomsPerFloor) + 1
          : 1;
      final roomInFloor = effectiveRoomsPerFloor > 0
          ? ((index - 1) % effectiveRoomsPerFloor) + 1
          : index;
      final paddedIndex = index.toString().padLeft(3, '0');
      final roomRef = rooms.doc('room_$paddedIndex');

      batch.set(roomRef, {
        'id': roomRef.id,
        'buildingId': buildingId,
        'roomNumber': index,
        'floor': floor,
        'name': 'Phòng $floor${roomInFloor.toString().padLeft(2, '0')}',
        'rent': defaultRent,
        'type': 'standard',
        'maxPeople': 0,
        'area': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      operationCount++;
      if (operationCount >= 450) {
        await commitBatch();
      }
    }

    await commitBatch();
  }

  Future<void> ensureBuildingGroupChat({
    required String buildingId,
    required String userId,
    required String buildingName,
  }) async {
    final query = await AppFirestoreService.chats
        .where('memberIds', arrayContains: userId)
        .get();

    final matchedChats = query.docs.where((doc) {
      final chat = doc.data();
      return chat['type'] == ChatType.group && chat['buildingId'] == buildingId;
    }).toList();

    if (matchedChats.isNotEmpty) {
      await matchedChats.first.reference.update({
        'memberIds': FieldValue.arrayUnion([userId]),
        'deletedFor': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await AppFirestoreService.chats.add({
      'type': ChatType.group,
      'buildingId': buildingId,
      'ownerId': userId,
      'title': buildingName.isEmpty ? 'Nhóm chat tòa nhà' : buildingName,
      'memberIds': [userId],
      'deletedFor': [],
      'isDeleted': false,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> loadBuildingPayosSettings({
    required String backendBaseUrl,
    required String idToken,
    required String buildingId,
  }) async {
    final response = await http
        .get(
          _backendUri(
            backendBaseUrl,
            '/building-payos-settings',
          ).replace(queryParameters: {'buildingId': buildingId}),
          headers: {'Authorization': 'Bearer $idToken'},
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Kết nối PayOS backend quá lâu.');
          },
        );

    final data = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Không tải được cấu hình PayOS.',
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> saveBuildingPayosSettings({
    required String backendBaseUrl,
    required String idToken,
    required String buildingId,
    required String clientId,
    required String apiKey,
    required String checksumKey,
  }) async {
    final response = await http
        .post(
          _backendUri(backendBaseUrl, '/building-payos-settings'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'buildingId': buildingId,
            'clientId': clientId,
            'apiKey': apiKey,
            'checksumKey': checksumKey,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Kết nối PayOS backend quá lâu.');
          },
        );

    final data = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Không lưu được cấu hình PayOS.',
      );
    }

    return data;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static Map<String, dynamic> _decodeMap(String body) {
    if (body.trim().isEmpty) return {};

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static Uri _backendUri(String backendBaseUrl, String path) {
    final base = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    return Uri.parse('$base$path');
  }

  static String _safeStorageFileName(String name) {
    final clean = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return clean.isEmpty ? 'room_image.jpg' : clean;
  }

  static Future<String> _uploadImageToFirebaseStorage({
    required String buildingId,
    required String roomId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    final fileName = _safeStorageFileName(image.name);
    final uploadedAt = DateTime.now().microsecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('buildings')
        .child(buildingId)
        .child('rooms')
        .child(roomId)
        .child('${uploadedAt}_$fileName');

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _imageContentType(fileName),
        customMetadata: {
          'buildingId': buildingId,
          'roomId': roomId,
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

  static Future<void> _deleteFirebaseStorageImage(String imageUrl) async {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty) return;

    final isFirebaseUrl =
        trimmedUrl.startsWith('gs://') ||
        trimmedUrl.contains('firebasestorage.googleapis.com');
    if (!isFirebaseUrl) return;

    try {
      await FirebaseStorage.instance.refFromURL(trimmedUrl).delete();
    } on FirebaseException {
      return;
    } on ArgumentError {
      return;
    }
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

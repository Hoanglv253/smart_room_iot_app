import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/services/app_firestore_service.dart';

class SettingsRepository {
  static const _cloudinaryCloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const _cloudinaryUploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

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

  Future<String> uploadRoomImage({
    required String buildingId,
    required String roomId,
    required XFile image,
  }) async {
    final url = await _uploadImageToCloudinary(
      buildingId: buildingId,
      roomId: roomId,
      image: image,
    );
    final roomRef = AppFirestoreService.buildingRooms(buildingId).doc(roomId);

    await AppFirestoreService.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      final room = snapshot.data() ?? {};
      final currentCover = (room['coverImageUrl'] ?? '').toString().trim();

      transaction.set(roomRef, {
        'imageUrls': FieldValue.arrayUnion([url]),
        if (currentCover.isEmpty) 'coverImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return url;
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

    // Cloudinary unsigned uploads cannot be securely deleted from the client.
    // The app removes the image from Firestore; cloud cleanup can be added later
    // through a signed backend endpoint.
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
        'name': 'Phong $floor${roomInFloor.toString().padLeft(2, '0')}',
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
      'title': buildingName.isEmpty ? 'Nhom chat toa nha' : buildingName,
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
            throw TimeoutException('Ket noi PayOS backend qua lau.');
          },
        );

    final data = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Khong tai duoc cau hinh PayOS.',
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
            throw TimeoutException('Ket noi PayOS backend qua lau.');
          },
        );

    final data = _decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Khong luu duoc cau hinh PayOS.',
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

  static Future<String> _uploadImageToCloudinary({
    required String buildingId,
    required String roomId,
    required XFile image,
  }) async {
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Chua cau hinh CLOUDINARY_CLOUD_NAME va CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final bytes = await image.readAsBytes();
    final fileName = _safeStorageFileName(image.name);
    final request = http.MultipartRequest(
      'POST',
      Uri.https(
        'api.cloudinary.com',
        '/v1_1/$_cloudinaryCloudName/image/upload',
      ),
    )
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'smart_room_iot/buildings/$buildingId/rooms/$roomId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        throw TimeoutException('Ket noi Cloudinary qua lau.');
      },
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = (data['secure_url'] ?? data['url'] ?? '').toString();
    if (secureUrl.isEmpty) {
      throw Exception('Cloudinary khong tra ve link anh.');
    }

    return secureUrl;
  }
}

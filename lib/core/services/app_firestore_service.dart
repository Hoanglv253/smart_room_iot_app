import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../features/admin/models/admin_profile_data.dart';

class AppFirestoreService {
  AppFirestoreService._();

  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');

  static CollectionReference<Map<String, dynamic>> get rooms =>
      db.collection('rooms');

  static CollectionReference<Map<String, dynamic>> get bills =>
      db.collection('bills');

  static CollectionReference<Map<String, dynamic>> get notifications =>
      db.collection('notifications');

  static CollectionReference<Map<String, dynamic>> get devices =>
      db.collection('devices');

  static String currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String roomId(int roomNumber) {
    return 'room_${roomNumber.toString().padLeft(3, '0')}';
  }

  static String roomName(int roomNumber) {
    return 'Phòng ${roomNumber.toString().padLeft(3, '0')}';
  }

  static String billId(int roomNumber, String monthKey) {
    return '${roomId(roomNumber)}_$monthKey';
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchUsers() {
    return users.snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchRooms() {
    return rooms.orderBy('number').snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchCurrentBills() {
    return bills.where('monthKey', isEqualTo: currentMonthKey()).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> watchDevices() {
    return devices.snapshots();
  }

  static Future<void> ensureBaseCollections({int? roomCount}) async {
    final count = roomCount ?? AdminProfileData.roomCount;
    await Future.wait([
      ensureRooms(count: count),
      ensureDevices(),
    ]).timeout(const Duration(seconds: 12));
  }

  static Future<void> ensureRooms({required int count}) async {
    final monthKey = currentMonthKey();
    final batch = db.batch();

    for (var number = 1; number <= count; number++) {
      final id = roomId(number);
      final bill = BillRecord.sampleForRoom(number, monthKey);

      batch.set(
        rooms.doc(id),
        {
          'id': id,
          'number': number,
          'name': roomName(number),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        bills.doc(billId(number, monthKey)),
        bill.toFirestore(),
        SetOptions(merge: true),
      );
    }

    await batch.commit().timeout(const Duration(seconds: 10));
  }

  static Future<void> ensureDevices() async {
    final batch = db.batch();
    final items = <DeviceRecord>[
      const DeviceRecord(
        id: 'main_pump',
        name: 'Hệ thống bơm nước tổng',
        type: 'water',
        scope: 'building',
        status: 'online',
        roomNumber: null,
        usage: 0,
      ),
      const DeviceRecord(
        id: 'fire_alarm',
        name: 'Hệ thống báo cháy trung tâm',
        type: 'alarm',
        scope: 'building',
        status: 'online',
        roomNumber: null,
        usage: 0,
      ),
      const DeviceRecord(
        id: 'hall_light_a',
        name: 'Đèn hành lang khu A',
        type: 'light',
        scope: 'building',
        status: 'online',
        roomNumber: null,
        usage: 0,
      ),
    ];

    for (final item in items) {
      batch.set(devices.doc(item.id), item.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit().timeout(const Duration(seconds: 10));
  }

  static Future<void> syncRoomOccupancyFromUsers(
    List<AppUserRecord> userList,
  ) async {
    final occupiedRooms = userList
        .where((user) => user.roomNumber != null)
        .map((user) => user.roomNumber!)
        .toSet();
    final batch = db.batch();

    for (var number = 1; number <= AdminProfileData.roomCount; number++) {
      batch.set(
        rooms.doc(roomId(number)),
        {
          'status': occupiedRooms.contains(number) ? 'occupied' : 'available',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit().timeout(const Duration(seconds: 10));
  }

  static Future<void> upsertBill(BillRecord bill) async {
    await bills.doc(bill.id).set(
      bill.toFirestore(),
      SetOptions(merge: true),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<void> sendNotification({
    required String message,
    required String senderRole,
    required List<String> targetRoles,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final doc = notifications.doc();
    await doc.set({
      'id': doc.id,
      'message': message.trim(),
      'senderRole': senderRole,
      'senderName': user?.displayName ?? user?.email ?? 'Người dùng',
      'senderEmail': user?.email ?? '',
      'senderUid': user?.uid ?? '',
      'targetRoles': targetRoles,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 10));
  }
}

class AppUserRecord {
  const AppUserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.roomNumber,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final int? roomNumber;

  factory AppUserRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final rawRoomNumber = data['roomNumber'];
    final parsedRoomNumber = rawRoomNumber is int
        ? rawRoomNumber
        : int.tryParse(rawRoomNumber?.toString() ?? '');
    final email = (data['email'] ?? '').toString();
    return AppUserRecord(
      id: id,
      name: (data['name'] ?? data['displayName'] ?? email).toString(),
      email: email,
      role: (data['role'] ?? 'user').toString(),
      roomNumber: parsedRoomNumber,
    );
  }
}

class BillRecord {
  const BillRecord({
    required this.id,
    required this.roomNumber,
    required this.monthKey,
    required this.electricKwh,
    required this.waterM3,
    required this.electricAmount,
    required this.waterAmount,
    required this.roomAmount,
    required this.status,
  });

  final String id;
  final int roomNumber;
  final String monthKey;
  final double electricKwh;
  final double waterM3;
  final int electricAmount;
  final int waterAmount;
  final int roomAmount;
  final String status;

  int get totalAmount => electricAmount + waterAmount + roomAmount;

  factory BillRecord.sampleForRoom(int roomNumber, String monthKey) {
    final electricKwh = 70 + (roomNumber % 35) * 3.4;
    final waterM3 = 7 + (roomNumber % 8) * 1.2;
    return BillRecord(
      id: AppFirestoreService.billId(roomNumber, monthKey),
      roomNumber: roomNumber,
      monthKey: monthKey,
      electricKwh: electricKwh,
      waterM3: waterM3,
      electricAmount: (electricKwh * 3500).round(),
      waterAmount: (waterM3 * 12000).round(),
      roomAmount: 2500000 + (roomNumber % 5) * 200000,
      status: 'unpaid',
    );
  }

  factory BillRecord.fromFirestore(String id, Map<String, dynamic> data) {
    final roomNumber = data['roomNumber'] is int
        ? data['roomNumber'] as int
        : int.tryParse(data['roomNumber']?.toString() ?? '') ?? 0;
    return BillRecord(
      id: id,
      roomNumber: roomNumber,
      monthKey: (data['monthKey'] ?? AppFirestoreService.currentMonthKey())
          .toString(),
      electricKwh: (data['electricKwh'] as num?)?.toDouble() ?? 0,
      waterM3: (data['waterM3'] as num?)?.toDouble() ?? 0,
      electricAmount: (data['electricAmount'] as num?)?.round() ?? 0,
      waterAmount: (data['waterAmount'] as num?)?.round() ?? 0,
      roomAmount: (data['roomAmount'] as num?)?.round() ?? 0,
      status: (data['status'] ?? 'unpaid').toString(),
    );
  }

  BillRecord copyWith({
    double? electricKwh,
    double? waterM3,
    int? electricAmount,
    int? waterAmount,
    int? roomAmount,
    String? status,
  }) {
    return BillRecord(
      id: id,
      roomNumber: roomNumber,
      monthKey: monthKey,
      electricKwh: electricKwh ?? this.electricKwh,
      waterM3: waterM3 ?? this.waterM3,
      electricAmount: electricAmount ?? this.electricAmount,
      waterAmount: waterAmount ?? this.waterAmount,
      roomAmount: roomAmount ?? this.roomAmount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'roomNumber': roomNumber,
      'roomName': AppFirestoreService.roomName(roomNumber),
      'monthKey': monthKey,
      'electricKwh': electricKwh,
      'waterM3': waterM3,
      'electricAmount': electricAmount,
      'waterAmount': waterAmount,
      'roomAmount': roomAmount,
      'totalAmount': totalAmount,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class DeviceRecord {
  const DeviceRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.scope,
    required this.status,
    required this.roomNumber,
    required this.usage,
  });

  final String id;
  final String name;
  final String type;
  final String scope;
  final String status;
  final int? roomNumber;
  final double usage;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'scope': scope,
      'status': status,
      'roomNumber': roomNumber,
      'usage': usage,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
